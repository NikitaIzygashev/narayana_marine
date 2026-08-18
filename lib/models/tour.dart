import 'content_image.dart';

class Tour {
  const Tour({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.fullDescription,
    required this.destinations,
    required this.highlights,
    required this.timingLabel,
    required this.itinerary,
    required this.inclusions,
    required this.priceLabel,
    required this.gallery,
    required this.coverImageId,
    required this.isPublished,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String shortDescription;
  final String fullDescription;
  final List<String> destinations;
  final List<String> highlights;
  final String? timingLabel;
  final List<Map<String, String>> itinerary;
  final List<String> inclusions;
  final String? priceLabel;
  final List<ContentImage> gallery;
  final String? coverImageId;
  final bool isPublished;
  final int sortOrder;

  ContentImage? get coverImage {
    for (final image in gallery) {
      if (image.id == coverImageId) return image;
    }
    return gallery.isEmpty ? null : gallery.first;
  }

  factory Tour.fromMap(String id, Map<String, dynamic> map) => Tour(
        id: id,
        name: map['name'] as String? ?? '',
        shortDescription: map['shortDescription'] as String? ?? '',
        fullDescription: map['fullDescription'] as String? ?? '',
        destinations: ((map['destinations'] as List<dynamic>?) ?? []).map((item) => '$item').toList(),
        highlights: ((map['highlights'] as List<dynamic>?) ?? []).map((item) => '$item').toList(),
        timingLabel: map['timingLabel'] as String?,
        itinerary: ((map['itinerary'] as List<dynamic>?) ?? [])
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry('$key', '$value')))
            .toList(),
        inclusions: ((map['inclusions'] as List<dynamic>?) ?? []).map((item) => '$item').toList(),
        priceLabel: map['priceLabel'] as String?,
        gallery: ((map['gallery'] as List<dynamic>?) ?? [])
            .whereType<Map>()
            .map((item) => ContentImage.fromMap(Map<String, dynamic>.from(item)))
            .toList(),
        coverImageId: map['coverImageId'] as String?,
        isPublished: map['isPublished'] as bool? ?? false,
        sortOrder: (map['sortOrder'] as num?)?.round() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'shortDescription': shortDescription,
        'fullDescription': fullDescription,
        'destinations': destinations,
        'highlights': highlights,
        'timingLabel': timingLabel,
        'itinerary': itinerary,
        'inclusions': inclusions,
        'priceLabel': priceLabel,
        'gallery': gallery.map((image) => image.toMap()).toList(),
        'coverImageId': coverImageId,
        'isPublished': isPublished,
        'sortOrder': sortOrder,
      };

  Tour copyWith({
    List<ContentImage>? gallery,
    String? coverImageId,
    bool clearCover = false,
    bool? isPublished,
    int? sortOrder,
  }) =>
      Tour(
        id: id,
        name: name,
        shortDescription: shortDescription,
        fullDescription: fullDescription,
        destinations: destinations,
        highlights: highlights,
        timingLabel: timingLabel,
        itinerary: itinerary,
        inclusions: inclusions,
        priceLabel: priceLabel,
        gallery: gallery ?? this.gallery,
        coverImageId: clearCover ? null : (coverImageId ?? this.coverImageId),
        isPublished: isPublished ?? this.isPublished,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
