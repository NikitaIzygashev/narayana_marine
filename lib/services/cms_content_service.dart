import 'package:image_picker/image_picker.dart';

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

  Future<void> saveCard({
    required CmsCardKind kind,
    required CmsCard card,
    required bool isNew,
    required List<XFile> newImages,
    required Set<String> removedStoragePaths,
  }) async {
    if (card.images.length + newImages.length > 10) {
      throw StateError('Можно добавить не более 10 изображений.');
    }
    final uploaded = <StoredMedia>[];
    try {
      for (final file in newImages) {
        uploaded.add(
          await _storage.uploadCardImage(
            kind: kind,
            cardId: card.id,
            file: file,
          ),
        );
      }
      final removedPaths = card.images
          .where((image) => removedStoragePaths.contains(image.storagePath))
          .expand((image) => image.storagePaths);
      final next = card.copyWith(
        images: [...card.images, ...uploaded],
        pendingStorageDeletes: {
          ...card.pendingStorageDeletes,
          ...removedPaths,
        }.toList(),
      );
      await _repository.saveCmsCard(kind, next, isNew: isNew);
    } catch (_) {
      await _storage.deleteAll(uploaded.map((item) => item.storagePath));
      rethrow;
    }
    await cleanPendingDeletes();
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
      final cards = await _repository.fetchCmsCards(kind, admin: true);
      for (final card in cards.where(
        (item) => item.pendingStorageDeletes.isNotEmpty,
      )) {
        await _storage.deleteAll(card.pendingStorageDeletes);
        if (card.isPublished) {
          await _repository.clearCmsCardPendingDeletes(
            kind,
            card.id,
            card.pendingStorageDeletes,
          );
        } else {
          await _repository.deleteCmsCard(kind, card.id);
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
