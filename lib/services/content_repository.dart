import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cms_models.dart';

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
    bool includeDeleting = false,
  }) async {
    final reference = _collectionFor(kind);
    final snapshot = admin
        ? await reference.get()
        : await reference.where('isPublished', isEqualTo: true).get();
    final result = snapshot.docs
        .map((doc) => CmsCard.fromMap(doc.id, doc.data()))
        .toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return includeDeleting
        ? result
        : result.where((card) => !card.isDeleting).toList();
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

  Future<void> deleteHero() => _hero.delete();

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
  }) async {
    final reference = _collectionFor(kind).doc(card.id);
    if (isNew) {
      await _createIfAbsent(reference, {
        ...card.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (!existing.exists) throw StateError('The card no longer exists.');
      final createdAt = existing.data()?['createdAt'];
      if (createdAt is! Timestamp) {
        throw StateError('The card has no valid creation timestamp.');
      }
      transaction.set(reference, {
        ...card.toMap(),
        'createdAt': createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markCmsCardForDeletion(CmsCardKind kind, CmsCard card) =>
      _collectionFor(kind).doc(card.id).update({
        'isPublished': false,
        'isDeleting': true,
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
      _saveDocument(_content.doc(item.id), item.toMap(), isNew: isNew);

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
      _saveDocument(_services.doc(item.id), item.toMap(), isNew: isNew);
  Future<void> deleteService(String id) => _services.doc(id).delete();

  Future<void> _saveDocument(
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
