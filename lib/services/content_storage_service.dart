import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/cms_models.dart';

/// Uploads only to Firebase Storage. It never persists a local copy.
class ContentStorageService {
  ContentStorageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
    FirebaseFirestore? firestore,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _picker = picker ?? ImagePicker(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const maxImageBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 100 * 1024 * 1024;
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final FirebaseFirestore _firestore;

  Future<XFile?> pickImage() => _picker.pickImage(source: ImageSource.gallery);
  Future<List<XFile>> pickImages() => _picker.pickMultiImage();
  Future<XFile?> pickVideo() => _picker.pickVideo(source: ImageSource.gallery);

  Future<StoredMedia> uploadHero(XFile file) =>
      _upload(file: file, directory: 'site/hero', allowVideo: true);

  Future<StoredMedia> uploadCardImage({
    required CmsCardKind kind,
    required String cardId,
    required XFile file,
  }) => _upload(
    file: file,
    directory: '${kind.storageFolder}/$cardId',
    allowVideo: false,
  );

  Future<StoredMedia> uploadGalleryImage({required XFile file}) =>
      _upload(file: file, directory: 'gallery', allowVideo: false);

  Future<StoredMedia> _upload({
    required XFile file,
    required String directory,
    required bool allowVideo,
  }) async {
    final mediaType = _mediaType(file);
    if (mediaType == null ||
        (!allowVideo && mediaType == SiteMediaType.video)) {
      throw const ContentStorageException('Неподдерживаемый формат файла.');
    }
    final bytes = await file.readAsBytes();
    final maximum = mediaType == SiteMediaType.video
        ? maxVideoBytes
        : maxImageBytes;
    if (bytes.lengthInBytes > maximum) {
      throw ContentStorageException(
        mediaType == SiteMediaType.video
            ? 'Видео должно быть не больше 100 MB.'
            : 'Изображение должно быть не больше 10 MB.',
      );
    }
    final extension = _safeExtension(file, mediaType);
    final id = _firestore.collection('_ids').doc().id;
    final path = '$directory/$id.$extension';
    final reference = _storage.ref(path);
    try {
      await reference.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(
          contentType: _contentType(file, mediaType),
          cacheControl: 'public,max-age=31536000,immutable',
        ),
      );
      return StoredMedia(
        url: await reference.getDownloadURL(),
        storagePath: path,
        type: mediaType,
      );
    } catch (_) {
      await deleteByStoragePath(path);
      rethrow;
    }
  }

  Future<void> deleteByStoragePath(String path) async {
    if (path.trim().isEmpty) return;
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  Future<void> deleteAll(Iterable<String> paths) async {
    for (final path in paths.toSet()) {
      await deleteByStoragePath(path);
    }
  }

  SiteMediaType? _mediaType(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    final extension = file.name.split('.').last.toLowerCase();
    if (const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime) ||
        const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      return SiteMediaType.image;
    }
    if (const {'video/mp4', 'video/webm'}.contains(mime) ||
        const {'mp4', 'webm'}.contains(extension)) {
      return SiteMediaType.video;
    }
    return null;
  }

  String _safeExtension(XFile file, SiteMediaType type) {
    final extension = file.name.split('.').last.toLowerCase();
    if (type == SiteMediaType.image &&
        const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      return extension;
    }
    if (type == SiteMediaType.video &&
        const {'mp4', 'webm'}.contains(extension)) {
      return extension;
    }
    return type == SiteMediaType.image ? 'jpg' : 'mp4';
  }

  String _contentType(XFile file, SiteMediaType type) {
    final mime = file.mimeType?.toLowerCase();
    if (type == SiteMediaType.image &&
        const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
      return mime!;
    }
    if (type == SiteMediaType.video &&
        const {'video/mp4', 'video/webm'}.contains(mime)) {
      return mime!;
    }
    return type == SiteMediaType.image ? 'image/jpeg' : 'video/mp4';
  }
}

class ContentStorageException implements Exception {
  const ContentStorageException(this.message);
  final String message;
  @override
  String toString() => message;
}
