import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/boat.dart';
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

  Future<List<Boat>> fetchPublishedBoats() async {
    final snapshot = await _boats
        .where('isPublished', isEqualTo: true)
        .orderBy('sortOrder')
        .get();
    return snapshot.docs.map((doc) => Boat.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<Tour>> fetchPublishedTours() async {
    final snapshot = await _tours
        .where('isPublished', isEqualTo: true)
        .orderBy('sortOrder')
        .get();
    return snapshot.docs.map((doc) => Tour.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<MediaContent>> fetchPublishedMediaContent() async {
    final snapshot = await _content
        .where('isPublished', isEqualTo: true)
        .orderBy('sortOrder')
        .get();
    return snapshot.docs
        .map((doc) => MediaContent.fromMap(doc.id, doc.data()))
        .where((item) => item.isRenderable)
        .toList();
  }

  Future<List<MediaContent>> fetchAllMediaContent() async {
    final snapshot = await _content.orderBy('sortOrder').get();
    return snapshot.docs
        .map((doc) => MediaContent.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Boat>> fetchAllBoats() async {
    final snapshot = await _boats.orderBy('sortOrder').get();
    return snapshot.docs.map((doc) => Boat.fromMap(doc.id, doc.data())).toList();
  }

  Future<List<Tour>> fetchAllTours() async {
    final snapshot = await _tours.orderBy('sortOrder').get();
    return snapshot.docs.map((doc) => Tour.fromMap(doc.id, doc.data())).toList();
  }

  Future<void> saveBoat(Boat boat, {required bool isNew}) async {
    final data = boat.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final reference = _boats.doc(boat.id);
    if (!isNew) return reference.set(data, SetOptions(merge: true));
    data['createdAt'] = FieldValue.serverTimestamp();
    await _createIfAbsent(reference, data);
  }

  Future<void> saveTour(Tour tour, {required bool isNew}) async {
    final data = tour.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final reference = _tours.doc(tour.id);
    if (!isNew) return reference.set(data, SetOptions(merge: true));
    data['createdAt'] = FieldValue.serverTimestamp();
    await _createIfAbsent(reference, data);
  }

  Future<void> saveMediaContent(
    MediaContent content, {
    required bool isNew,
  }) async {
    final data = content.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final reference = _content.doc(content.id);
    if (!isNew) return reference.set(data, SetOptions(merge: true));
    data['createdAt'] = FieldValue.serverTimestamp();
    await _createIfAbsent(reference, data);
  }

  Future<void> updateBoatGallery(
    String id,
    List<ContentImage> gallery,
    String? coverImageId,
  ) =>
      _boats.doc(id).update({
        'gallery': gallery.map((image) => image.toMap()).toList(),
        'coverImageId': coverImageId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateTourGallery(
    String id,
    List<ContentImage> gallery,
    String? coverImageId,
  ) =>
      _tours.doc(id).update({
        'gallery': gallery.map((image) => image.toMap()).toList(),
        'coverImageId': coverImageId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteBoat(String id) => _boats.doc(id).delete();
  Future<void> deleteTour(String id) => _tours.doc(id).delete();
  Future<void> deleteMediaContent(String id) => _content.doc(id).delete();

  Future<void> _createIfAbsent(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) => _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        if (existing.exists) throw StateError('This stable ID already exists.');
        transaction.set(reference, data);
      });
}
