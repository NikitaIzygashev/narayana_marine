import 'package:cloud_firestore/cloud_firestore.dart';

class MediaContent {
  const MediaContent({
    required this.id,
    required this.type,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.titleRu,
    required this.titleEn,
    required this.sortOrder,
    required this.isPublished,
    required this.createdAt,
  });

  final String id;
  final MediaContentType type;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? titleRu;
  final String? titleEn;
  final int sortOrder;
  final bool isPublished;
  final DateTime? createdAt;

  bool get isRenderable =>
      mediaUrl.isNotEmpty &&
      (type == MediaContentType.image || (thumbnailUrl?.isNotEmpty ?? false));

  String? titleFor(String languageCode) =>
      languageCode == 'ru' ? titleRu : titleEn;

  factory MediaContent.fromMap(String id, Map<String, dynamic> map) =>
      MediaContent(
        id: id,
        type: MediaContentType.fromValue(map['type'] as String?),
        mediaUrl: map['mediaUrl'] as String? ?? '',
        thumbnailUrl: map['thumbnailUrl'] as String?,
        titleRu: map['titleRu'] as String?,
        titleEn: map['titleEn'] as String?,
        sortOrder: (map['sortOrder'] as num?)?.round() ?? 0,
        isPublished: map['isPublished'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'mediaUrl': mediaUrl,
    'thumbnailUrl': thumbnailUrl,
    'titleRu': titleRu,
    'titleEn': titleEn,
    'sortOrder': sortOrder,
    'isPublished': isPublished,
  };

  MediaContent copyWith({
    String? mediaUrl,
    String? thumbnailUrl,
    String? titleRu,
    String? titleEn,
    int? sortOrder,
    bool? isPublished,
  }) => MediaContent(
    id: id,
    type: type,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    titleRu: titleRu ?? this.titleRu,
    titleEn: titleEn ?? this.titleEn,
    sortOrder: sortOrder ?? this.sortOrder,
    isPublished: isPublished ?? this.isPublished,
    createdAt: createdAt,
  );
}

enum MediaContentType {
  image,
  video;

  static MediaContentType fromValue(String? value) =>
      value == 'video' ? MediaContentType.video : MediaContentType.image;
}
