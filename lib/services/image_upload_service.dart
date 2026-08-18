import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

import '../models/content_image.dart';

enum ContentKind { boats, tours }

class ImageUploadService {
  ImageUploadService({FirebaseStorage? storage, ImagePicker? picker})
    : _storage = storage ?? FirebaseStorage.instance,
      _picker = picker ?? ImagePicker();

  static const _maxSourceBytes = 15 * 1024 * 1024;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  Future<XFile?> pickImage() => _picker.pickImage(source: ImageSource.gallery);

  Future<ContentImage> upload({
    required ContentKind kind,
    required String contentId,
    required XFile file,
  }) async {
    final source = await file.readAsBytes();
    if (source.lengthInBytes > _maxSourceBytes) {
      throw StateError('Choose an image smaller than 15 MB.');
    }
    final decoded = image.decodeImage(source);
    if (decoded == null) throw StateError('This image could not be processed.');
    if (decoded.width * decoded.height > 24000000) {
      throw StateError('Choose an image with no more than 24 megapixels.');
    }

    final display = _resize(decoded, 2560);
    final thumbnail = _resize(decoded, 640);
    final displayBytes = Uint8List.fromList(
      image.encodeJpg(display, quality: 82),
    );
    final thumbnailBytes = Uint8List.fromList(
      image.encodeJpg(thumbnail, quality: 72),
    );
    if (displayBytes.lengthInBytes > 2500 * 1024 ||
        thumbnailBytes.lengthInBytes > 350 * 1024) {
      throw StateError(
        'The optimized image is still too large. Choose a simpler photo.',
      );
    }

    final imageId = FirebaseFirestore.instance.collection('_ids').doc().id;
    final prefix = '${kind.name}/$contentId/images/$imageId';
    final displayPath = '$prefix/display.jpg';
    final thumbnailPath = '$prefix/thumbnail.jpg';
    final displayRef = _storage.ref(displayPath);
    final thumbnailRef = _storage.ref(thumbnailPath);
    final displayMetadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=31536000,immutable',
    );
    final thumbnailMetadata = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=31536000,immutable',
    );

    try {
      await displayRef.putData(displayBytes, displayMetadata);
      await thumbnailRef.putData(thumbnailBytes, thumbnailMetadata);
      return ContentImage(
        id: imageId,
        displayUrl: await displayRef.getDownloadURL(),
        thumbnailUrl: await thumbnailRef.getDownloadURL(),
        displayPath: displayPath,
        thumbnailPath: thumbnailPath,
        width: display.width,
        height: display.height,
      );
    } catch (_) {
      await _deleteIfPresent(displayRef);
      await _deleteIfPresent(thumbnailRef);
      rethrow;
    }
  }

  Future<void> deleteImage(ContentImage contentImage) async {
    await _deleteIfPresent(_storage.ref(contentImage.displayPath));
    await _deleteIfPresent(_storage.ref(contentImage.thumbnailPath));
  }

  Future<void> _deleteIfPresent(Reference reference) async {
    try {
      await reference.delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  image.Image _resize(image.Image source, int maximumEdge) {
    final largestEdge = source.width > source.height
        ? source.width
        : source.height;
    if (largestEdge <= maximumEdge) return source;
    final scale = maximumEdge / largestEdge;
    return image.copyResize(
      source,
      width: (source.width * scale).round(),
      height: (source.height * scale).round(),
      interpolation: image.Interpolation.average,
    );
  }
}
