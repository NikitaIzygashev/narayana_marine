import 'content_image.dart';

class Boat {
  const Boat({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.lengthMeters,
    required this.capacityLabel,
    required this.specifications,
    required this.gallery,
    required this.coverImageId,
    required this.isPublished,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final double? lengthMeters;
  final String capacityLabel;
  final List<Map<String, String>> specifications;
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

  factory Boat.fromMap(String id, Map<String, dynamic> map) => Boat(
        id: id,
        name: map['name'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        description: map['description'] as String? ?? '',
        lengthMeters: (map['lengthMeters'] as num?)?.toDouble(),
        capacityLabel: map['capacityLabel'] as String? ?? '',
        specifications: ((map['specifications'] as List<dynamic>?) ?? [])
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry('$key', '$value')))
            .toList(),
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
        'subtitle': subtitle,
        'description': description,
        'lengthMeters': lengthMeters,
        'capacityLabel': capacityLabel,
        'specifications': specifications,
        'gallery': gallery.map((image) => image.toMap()).toList(),
        'coverImageId': coverImageId,
        'isPublished': isPublished,
        'sortOrder': sortOrder,
      };

  Boat copyWith({
    List<ContentImage>? gallery,
    String? coverImageId,
    bool clearCover = false,
    bool? isPublished,
    int? sortOrder,
  }) =>
      Boat(
        id: id,
        name: name,
        subtitle: subtitle,
        description: description,
        lengthMeters: lengthMeters,
        capacityLabel: capacityLabel,
        specifications: specifications,
        gallery: gallery ?? this.gallery,
        coverImageId: clearCover ? null : (coverImageId ?? this.coverImageId),
        isPublished: isPublished ?? this.isPublished,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
