import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/cms_models.dart';
import 'content_repository.dart';
import 'content_storage_service.dart';

/// Coordinates Firestore metadata and Storage objects without pretending the
/// two Firebase products share a transaction.
class CmsContentService {
  CmsContentService({
    ContentRepository? repository,
    ContentStorageService? storage,
  }) : _repository = repository ?? ContentRepository(),
       _storage = storage ?? ContentStorageService();

  final ContentRepository _repository;
  final ContentStorageService _storage;

  Future<void> replaceHero(XFile file) async {
    final previous = await _repository.fetchHero();
    final existingPendingDeletes = await _repository.heroPendingDeletes();
    final uploaded = await _storage.uploadHero(file);
    try {
      await _repository.saveHero(
        HeroMedia(media: uploaded, updatedAt: null),
        pendingDeletes: [
          ...existingPendingDeletes,
          if (previous != null) previous.media.storagePath,
        ],
      );
    } catch (_) {
      await _storage.deleteByStoragePath(uploaded.storagePath);
      rethrow;
    }
    await cleanPendingDeletes();
  }

  Future<void> deleteHero() => HeroMediaDeletionCoordinator(
    fetchHero: _repository.fetchHero,
    fetchPendingPaths: _repository.heroPendingDeletes,
    deleteHeroDocument: _repository.deleteHero,
    restoreHeroDocument: (hero, pendingPaths) =>
        _repository.saveHero(hero, pendingDeletes: pendingPaths),
    deleteStoragePaths: _storage.deleteAll,
  ).deleteHero();

  Future<void> saveCard({
    required CmsCardKind kind,
    required CmsCard card,
    required bool isNew,
    required List<CardImageInput> images,
    required Set<String> removedStoragePaths,
  }) async {
    if (images.length > 10) {
      throw const CmsCardValidationException(
        CmsCardValidationIssue.imageLimitExceeded,
      );
    }
    final uploaded = <StoredMedia>[];
    try {
      final resolvedImages = <StoredMedia>[];
      for (final item in images) {
        if (item.existing != null) {
          resolvedImages.add(item.existing!);
          continue;
        }
        final uploadedImage = await _storage.uploadCardImage(
          kind: kind,
          cardId: card.id,
          file: item.file!,
        );
        uploaded.add(uploadedImage);
        resolvedImages.add(uploadedImage);
      }
      final next = card.copyWith(
        images: resolvedImages,
        pendingStorageDeletes: {
          ...card.pendingStorageDeletes,
          ...removedStoragePaths,
        }.toList(),
      );
      final issue = next.validationIssue(forPublish: next.isPublished);
      if (issue != null) throw CmsCardValidationException(issue);
      await _repository.saveCmsCard(kind, next, isNew: isNew);
    } catch (_) {
      try {
        await _storage.deleteAll(uploaded.map((item) => item.storagePath));
      } catch (cleanupError) {
        debugPrint(
          'CMS uploaded-image cleanup failed: ${cleanupError.runtimeType}',
        );
      }
      rethrow;
    }
    try {
      await cleanPendingDeletes();
    } catch (error) {
      debugPrint('CMS cleanup queued after card save: ${error.runtimeType}');
    }
  }

  Future<void> deleteCard(CmsCardKind kind, CmsCard card) async {
    await _repository.markCmsCardForDeletion(kind, card);
    try {
      await _storage.deleteAll(card.images.expand((item) => item.storagePaths));
      await _repository.deleteCmsCard(kind, card.id);
    } catch (_) {
      // The hidden document retains pending paths and is retried later.
      rethrow;
    }
  }

  Future<void> addGalleryImage({
    required XFile file,
    required int order,
  }) async {
    final uploaded = await _storage.uploadGalleryImage(file: file);
    final item = GalleryItem(
      id: _repository.newGalleryId(),
      media: uploaded,
      order: order,
      isPublished: true,
      pendingStorageDeletes: const [],
    );
    try {
      await _repository.saveGalleryItem(item, isNew: true);
    } catch (_) {
      await _storage.deleteByStoragePath(uploaded.storagePath);
      rethrow;
    }
  }

  Future<void> deleteGalleryItem(GalleryItem item) async {
    await _repository.markGalleryForDeletion(item);
    try {
      await _storage.deleteByStoragePath(item.media.storagePath);
      await _repository.deleteGalleryItem(item.id);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> cleanPendingDeletes() async {
    final heroPaths = await _repository.heroPendingDeletes();
    if (heroPaths.isNotEmpty) {
      await _storage.deleteAll(heroPaths);
      await _repository.clearHeroPendingDeletes(heroPaths);
    }
    for (final kind in CmsCardKind.values) {
      final cards = await _repository.fetchCmsCards(
        kind,
        admin: true,
        includeDeleting: true,
      );
      for (final card in cards.where(
        (item) => item.pendingStorageDeletes.isNotEmpty,
      )) {
        await _storage.deleteAll(card.pendingStorageDeletes);
        if (card.isDeleting) {
          await _repository.deleteCmsCard(kind, card.id);
        } else {
          await _repository.clearCmsCardPendingDeletes(
            kind,
            card.id,
            card.pendingStorageDeletes,
          );
        }
      }
    }
    final gallery = await _repository.fetchGallery(admin: true);
    for (final item in gallery.where(
      (value) => value.pendingStorageDeletes.isNotEmpty,
    )) {
      await _storage.deleteAll(item.pendingStorageDeletes);
      if (item.isPublished) {
        await _repository.clearGalleryPendingDeletes(
          item.id,
          item.pendingStorageDeletes,
        );
      } else {
        await _repository.deleteGalleryItem(item.id);
      }
    }
  }
}

class CardImageInput {
  const CardImageInput.existing(this.existing) : file = null;
  const CardImageInput.newFile(this.file) : existing = null;

  final StoredMedia? existing;
  final XFile? file;
}

class CmsCardValidationException implements Exception {
  const CmsCardValidationException(this.issue);
  final CmsCardValidationIssue issue;

  @override
  String toString() => 'CMS card validation failed: ${issue.name}';
}

class HeroMediaDeletionCoordinator {
  const HeroMediaDeletionCoordinator({
    required this.fetchHero,
    required this.fetchPendingPaths,
    required this.deleteHeroDocument,
    required this.restoreHeroDocument,
    required this.deleteStoragePaths,
  });

  final Future<HeroMedia?> Function() fetchHero;
  final Future<List<String>> Function() fetchPendingPaths;
  final Future<void> Function() deleteHeroDocument;
  final Future<void> Function(HeroMedia hero, Iterable<String> pendingPaths)
  restoreHeroDocument;
  final Future<void> Function(Iterable<String> paths) deleteStoragePaths;

  Future<void> deleteHero() async {
    final hero = await fetchHero();
    if (hero == null) return;

    final pendingPaths = await fetchPendingPaths();
    final currentPaths = hero.media.storagePaths
        .where((path) => path.trim().isNotEmpty)
        .toSet();
    final previousPaths = pendingPaths
        .where((path) => path.trim().isNotEmpty && !currentPaths.contains(path))
        .toSet();

    if (currentPaths.isEmpty) {
      await deleteStoragePaths(previousPaths);
      await deleteHeroDocument();
      return;
    }

    await deleteHeroDocument();
    try {
      await deleteStoragePaths(previousPaths);
      await deleteStoragePaths(currentPaths);
    } catch (_) {
      await restoreHeroDocument(hero, pendingPaths);
      rethrow;
    }
  }
}
