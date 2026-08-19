import 'package:cloud_firestore/cloud_firestore.dart';

enum CmsCardKind { tours, boats }

extension CmsCardKindX on CmsCardKind {
  String get collection => this == CmsCardKind.tours ? 'tours' : 'boats';
  String get storageFolder =>
      this == CmsCardKind.tours ? 'excursions' : 'fleet';
}

enum SiteMediaType { image, video }

class StoredMedia {
  const StoredMedia({
    required this.url,
    required this.storagePath,
    required this.type,
  });

  final String url;
  final String storagePath;
  final SiteMediaType type;

  /// A legacy CMS image has a display/thumbnail pair; new media uses one path.
  Iterable<String> get storagePaths sync* {
    yield storagePath;
    if (storagePath.endsWith('/display.jpg')) {
      yield storagePath.replaceFirst(
        RegExp(r'/display\.jpg$'),
        '/thumbnail.jpg',
      );
    }
  }

  factory StoredMedia.fromMap(Map<String, dynamic> map) => StoredMedia(
    url: map['url'] as String? ?? '',
    storagePath: map['storagePath'] as String? ?? '',
    type: map['type'] == 'video' ? SiteMediaType.video : SiteMediaType.image,
  );

  Map<String, dynamic> toMap() => {
    'url': url,
    'storagePath': storagePath,
    'type': type.name,
  };
}

class HeroMedia {
  const HeroMedia({required this.media, required this.updatedAt});

  final StoredMedia media;
  final DateTime? updatedAt;

  factory HeroMedia.fromMap(Map<String, dynamic> map) => HeroMedia(
    media: StoredMedia.fromMap(
      Map<String, dynamic>.from(
        map['media'] as Map? ?? const <String, dynamic>{},
      ),
    ),
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {'media': media.toMap()};
}

class CmsCard {
  const CmsCard({
    required this.id,
    required this.titleRu,
    required this.titleEn,
    required this.priceRu,
    required this.priceEn,
    required this.descriptionRu,
    required this.descriptionEn,
    required this.images,
    required this.order,
    required this.isPublished,
    required this.pendingStorageDeletes,
  });

  final String id;
  final String titleRu;
  final String titleEn;
  final String priceRu;
  final String priceEn;
  final String descriptionRu;
  final String descriptionEn;
  final List<StoredMedia> images;
  final int order;
  final bool isPublished;
  final List<String> pendingStorageDeletes;

  String titleFor(String languageCode) => languageCode == 'ru'
      ? _fallback(titleRu, titleEn)
      : _fallback(titleEn, titleRu);
  String priceFor(String languageCode) => languageCode == 'ru'
      ? _fallback(priceRu, priceEn)
      : _fallback(priceEn, priceRu);
  String descriptionFor(String languageCode) => languageCode == 'ru'
      ? _fallback(descriptionRu, descriptionEn)
      : _fallback(descriptionEn, descriptionRu);
  bool get needsEnglishTranslation =>
      titleEn.trim().isEmpty ||
      descriptionEn.trim().isEmpty ||
      priceEn.trim().isEmpty;

  factory CmsCard.fromMap(String id, Map<String, dynamic> map) => CmsCard(
    id: id,
    titleRu: map['titleRu'] as String? ?? map['name'] as String? ?? '',
    titleEn: map['titleEn'] as String? ?? map['name'] as String? ?? '',
    priceRu: map['priceRu'] as String? ?? map['priceLabel'] as String? ?? '',
    priceEn: map['priceEn'] as String? ?? map['priceLabel'] as String? ?? '',
    descriptionRu:
        map['descriptionRu'] as String? ??
        map['shortDescription'] as String? ??
        map['description'] as String? ??
        '',
    descriptionEn:
        map['descriptionEn'] as String? ??
        map['shortDescription'] as String? ??
        map['description'] as String? ??
        '',
    images: ((map['images'] ?? map['gallery']) as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) {
          final value = Map<String, dynamic>.from(item);
          if (value.containsKey('url')) return StoredMedia.fromMap(value);
          return StoredMedia(
            url: value['displayUrl'] as String? ?? '',
            storagePath: value['displayPath'] as String? ?? '',
            type: SiteMediaType.image,
          );
        })
        .where((item) => item.url.isNotEmpty && item.storagePath.isNotEmpty)
        .toList(),
    order:
        (map['order'] as num?)?.round() ??
        (map['sortOrder'] as num?)?.round() ??
        0,
    isPublished: map['isPublished'] as bool? ?? true,
    pendingStorageDeletes:
        ((map['pendingStorageDeletes'] as List<dynamic>?) ?? const [])
            .whereType<String>()
            .toList(),
  );

  Map<String, dynamic> toMap() => {
    'titleRu': titleRu,
    'titleEn': titleEn,
    'priceRu': priceRu,
    'priceEn': priceEn,
    'descriptionRu': descriptionRu,
    'descriptionEn': descriptionEn,
    'images': images.map((item) => item.toMap()).toList(),
    'order': order,
    'isPublished': isPublished,
    'pendingStorageDeletes': pendingStorageDeletes,
  };

  CmsCard copyWith({
    String? titleRu,
    String? titleEn,
    String? priceRu,
    String? priceEn,
    String? descriptionRu,
    String? descriptionEn,
    List<StoredMedia>? images,
    List<String>? pendingStorageDeletes,
    bool? isPublished,
  }) => CmsCard(
    id: id,
    titleRu: titleRu ?? this.titleRu,
    titleEn: titleEn ?? this.titleEn,
    priceRu: priceRu ?? this.priceRu,
    priceEn: priceEn ?? this.priceEn,
    descriptionRu: descriptionRu ?? this.descriptionRu,
    descriptionEn: descriptionEn ?? this.descriptionEn,
    images: images ?? this.images,
    order: order,
    isPublished: isPublished ?? this.isPublished,
    pendingStorageDeletes: pendingStorageDeletes ?? this.pendingStorageDeletes,
  );
}

class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.media,
    required this.order,
    required this.isPublished,
    required this.pendingStorageDeletes,
  });

  final String id;
  final StoredMedia media;
  final int order;
  final bool isPublished;
  final List<String> pendingStorageDeletes;

  factory GalleryItem.fromMap(String id, Map<String, dynamic> map) =>
      GalleryItem(
        id: id,
        media: StoredMedia.fromMap(
          Map<String, dynamic>.from(
            map['media'] as Map? ??
                {
                  'url': map['mediaUrl'] ?? '',
                  'storagePath': map['storagePath'] ?? '',
                  'type': map['type'] ?? 'image',
                },
          ),
        ),
        order:
            (map['order'] as num?)?.round() ??
            (map['sortOrder'] as num?)?.round() ??
            0,
        isPublished: map['isPublished'] as bool? ?? true,
        pendingStorageDeletes:
            ((map['pendingStorageDeletes'] as List<dynamic>?) ?? const [])
                .whereType<String>()
                .toList(),
      );

  Map<String, dynamic> toMap() => {
    'media': media.toMap(),
    'order': order,
    'isPublished': isPublished,
    'pendingStorageDeletes': pendingStorageDeletes,
  };
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.textRu,
    required this.textEn,
    required this.order,
  });

  final String id;
  final String textRu;
  final String textEn;
  final int order;

  String textFor(String languageCode) => languageCode == 'ru'
      ? _fallback(textRu, textEn)
      : _fallback(textEn, textRu);
  bool get needsEnglishTranslation => textEn.trim().isEmpty;

  factory ServiceItem.fromMap(String id, Map<String, dynamic> map) =>
      ServiceItem(
        id: id,
        textRu: map['textRu'] as String? ?? '',
        textEn: map['textEn'] as String? ?? '',
        order: (map['order'] as num?)?.round() ?? 0,
      );

  Map<String, dynamic> toMap() => {
    'textRu': textRu,
    'textEn': textEn,
    'order': order,
  };
}

String _fallback(String first, String second) =>
    first.trim().isEmpty ? second : first;
