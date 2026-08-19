import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/boat.dart';
import '../models/cms_models.dart';
import '../models/content_image.dart';
import '../models/media_content.dart';
import '../models/tour.dart';

class ContentRepository {
  ContentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _boats =>
      _firestore.collection('boats');
  CollectionReference<Map<String, dynamic>> get _tours =>
      _firestore.collection('tours');
  CollectionReference<Map<String, dynamic>> get _content =>
      _firestore.collection('content');
  CollectionReference<Map<String, dynamic>> get _services =>
      _firestore.collection('services');
  DocumentReference<Map<String, dynamic>> get _hero =>
      _firestore.collection('site').doc('hero');

  // Legacy API retained for existing detail/editor widgets.
  Future<List<Boat>> fetchPublishedBoats() async {
    final snapshot = await _boats.where('isPublished', isEqualTo: true).get();
    final result = snapshot.docs
        .map((doc) => Boat.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  Future<List<Tour>> fetchPublishedTours() async {
    final snapshot = await _tours.where('isPublished', isEqualTo: true).get();
    final result = snapshot.docs
        .map((doc) => Tour.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  Future<List<MediaContent>> fetchPublishedMediaContent() async {
    final snapshot = await _content.where('isPublished', isEqualTo: true).get();
    final result = snapshot.docs
        .map((doc) => MediaContent.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result.where((item) => item.isRenderable).toList();
  }

  Future<List<MediaContent>> fetchAllMediaContent() async {
    final snapshot = await _content.get();
    final result = snapshot.docs
        .map((doc) => MediaContent.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  Future<List<Boat>> fetchAllBoats() async {
    final snapshot = await _boats.get();
    final result = snapshot.docs
        .map((doc) => Boat.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  Future<List<Tour>> fetchAllTours() async {
    final snapshot = await _tours.get();
    final result = snapshot.docs
        .map((doc) => Tour.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
  }

  Future<void> saveBoat(Boat boat, {required bool isNew}) =>
      _saveLegacy(_boats.doc(boat.id), boat.toMap(), isNew: isNew);

  Future<void> saveTour(Tour tour, {required bool isNew}) =>
      _saveLegacy(_tours.doc(tour.id), tour.toMap(), isNew: isNew);

  Future<void> saveMediaContent(MediaContent content, {required bool isNew}) =>
      _saveLegacy(_content.doc(content.id), content.toMap(), isNew: isNew);

  Future<void> updateBoatGallery(
    String id,
    List<ContentImage> gallery,
    String? coverImageId,
  ) => _boats.doc(id).update({
    'gallery': gallery.map((image) => image.toMap()).toList(),
    'coverImageId': coverImageId,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateTourGallery(
    String id,
    List<ContentImage> gallery,
    String? coverImageId,
  ) => _tours.doc(id).update({
    'gallery': gallery.map((image) => image.toMap()).toList(),
    'coverImageId': coverImageId,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteBoat(String id) => _boats.doc(id).delete();
  Future<void> deleteTour(String id) => _tours.doc(id).delete();
  Future<void> deleteMediaContent(String id) => _content.doc(id).delete();

  String newId(CmsCardKind kind) => _collectionFor(kind).doc().id;
  String newGalleryId() => _content.doc().id;
  String newServiceId() => _services.doc().id;

  Future<HeroMedia?> fetchHero() async {
    final snapshot = await _hero.get();
    return snapshot.exists ? HeroMedia.fromMap(snapshot.data()!) : null;
  }

  Future<List<CmsCard>> fetchCmsCards(
    CmsCardKind kind, {
    required bool admin,
  }) async {
    final reference = _collectionFor(kind);
    final snapshot = admin
        ? await reference.get()
        : await reference.where('isPublished', isEqualTo: true).get();
    final result = snapshot.docs
        .map((doc) => CmsCard.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  Future<List<GalleryItem>> fetchGallery({required bool admin}) async {
    final snapshot = admin
        ? await _content.get()
        : await _content.where('isPublished', isEqualTo: true).get();
    final result = snapshot.docs
        .map((doc) => GalleryItem.fromMap(doc.id, doc.data()))
        .where((item) => item.media.url.isNotEmpty)
        .toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  Future<List<ServiceItem>> fetchServices() async {
    final snapshot = await _services.get();
    final result = snapshot.docs
        .map((doc) => ServiceItem.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  Future<void> saveHero(
    HeroMedia hero, {
    Iterable<String> pendingDeletes = const [],
  }) => _hero.set({
    ...hero.toMap(),
    'pendingStorageDeletes': pendingDeletes.toSet().toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> clearHeroPendingDeletes(Iterable<String> paths) => _hero.update({
    'pendingStorageDeletes': FieldValue.arrayRemove(paths.toList()),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<List<String>> heroPendingDeletes() async {
    final data = (await _hero.get()).data();
    return ((data?['pendingStorageDeletes'] as List<dynamic>?) ?? const [])
        .whereType<String>()
        .toList();
  }

  Future<void> saveCmsCard(
    CmsCardKind kind,
    CmsCard card, {
    required bool isNew,
  }) => _saveLegacy(
    _collectionFor(kind).doc(card.id),
    card.toMap(),
    isNew: isNew,
  );

  Future<void> markCmsCardForDeletion(CmsCardKind kind, CmsCard card) =>
      _collectionFor(kind).doc(card.id).update({
        'isPublished': false,
        'pendingStorageDeletes': card.images
            .expand((image) => image.storagePaths)
            .toSet()
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> clearCmsCardPendingDeletes(
    CmsCardKind kind,
    String id,
    Iterable<String> paths,
  ) => _collectionFor(kind).doc(id).update({
    'pendingStorageDeletes': FieldValue.arrayRemove(paths.toList()),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteCmsCard(CmsCardKind kind, String id) =>
      _collectionFor(kind).doc(id).delete();

  Future<void> saveGalleryItem(GalleryItem item, {required bool isNew}) =>
      _saveLegacy(_content.doc(item.id), item.toMap(), isNew: isNew);

  Future<void> markGalleryForDeletion(GalleryItem item) =>
      _content.doc(item.id).update({
        'isPublished': false,
        'pendingStorageDeletes': [item.media.storagePath],
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> clearGalleryPendingDeletes(String id, Iterable<String> paths) =>
      _content.doc(id).update({
        'pendingStorageDeletes': FieldValue.arrayRemove(paths.toList()),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteGalleryItem(String id) => _content.doc(id).delete();

  Future<void> saveService(ServiceItem item, {required bool isNew}) =>
      _saveLegacy(_services.doc(item.id), item.toMap(), isNew: isNew);
  Future<void> deleteService(String id) => _services.doc(id).delete();

  Future<void> _saveLegacy(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data, {
    required bool isNew,
  }) async {
    data = {...data, 'updatedAt': FieldValue.serverTimestamp()};
    if (!isNew) return reference.set(data, SetOptions(merge: true));
    data['createdAt'] = FieldValue.serverTimestamp();
    await _createIfAbsent(reference, data);
  }

  CollectionReference<Map<String, dynamic>> _collectionFor(CmsCardKind kind) =>
      kind == CmsCardKind.tours ? _tours : _boats;

  Future<void> _createIfAbsent(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) => _firestore.runTransaction((transaction) async {
    final existing = await transaction.get(reference);
    if (existing.exists) throw StateError('This stable ID already exists.');
    transaction.set(reference, data);
  });
}
