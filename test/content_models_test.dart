import 'package:flutter_test/flutter_test.dart';
import 'package:narayana_marine/models/boat.dart';
import 'package:narayana_marine/models/content_image.dart';
import 'package:narayana_marine/models/tour.dart';

void main() {
  const image = ContentImage(
    id: 'image-1',
    displayUrl: 'https://example.test/display.jpg',
    thumbnailUrl: 'https://example.test/thumb.jpg',
    displayPath: 'boats/boat/images/image-1/display.jpg',
    thumbnailPath: 'boats/boat/images/image-1/thumbnail.jpg',
    width: 1200,
    height: 800,
  );

  test('boat serializes and chooses the selected cover image', () {
    const boat = Boat(
      id: 'vanit-1',
      name: 'VANIT 1',
      subtitle: 'Catamaran',
      description: '',
      lengthMeters: 11.5,
      capacityLabel: 'Private Charter',
      specifications: [],
      gallery: [image],
      coverImageId: 'image-1',
      isPublished: false,
      sortOrder: 10,
    );

    final restored = Boat.fromMap(boat.id, boat.toMap());

    expect(restored.coverImage?.id, 'image-1');
    expect(restored.lengthMeters, 11.5);
    expect(restored.toMap()['gallery'], hasLength(1));
  });

  test('tour can clear its cover after its last image is removed', () {
    const tour = Tour(
      id: 'private-charters',
      name: 'Private Charters',
      shortDescription: '',
      fullDescription: '',
      destinations: [],
      highlights: [],
      timingLabel: null,
      itinerary: [],
      inclusions: [],
      priceLabel: null,
      gallery: [image],
      coverImageId: 'image-1',
      isPublished: false,
      sortOrder: 40,
    );

    final updated = tour.copyWith(gallery: const [], clearCover: true);

    expect(updated.gallery, isEmpty);
    expect(updated.coverImageId, isNull);
  });
}
