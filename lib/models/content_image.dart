class ContentImage {
  const ContentImage({
    required this.id,
    required this.displayUrl,
    required this.thumbnailUrl,
    required this.displayPath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
  });

  final String id;
  final String displayUrl;
  final String thumbnailUrl;
  final String displayPath;
  final String thumbnailPath;
  final int width;
  final int height;

  factory ContentImage.fromMap(Map<String, dynamic> map) => ContentImage(
        id: map['id'] as String? ?? '',
        displayUrl: map['displayUrl'] as String? ?? '',
        thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
        displayPath: map['displayPath'] as String? ?? '',
        thumbnailPath: map['thumbnailPath'] as String? ?? '',
        width: (map['width'] as num?)?.round() ?? 0,
        height: (map['height'] as num?)?.round() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayUrl': displayUrl,
        'thumbnailUrl': thumbnailUrl,
        'displayPath': displayPath,
        'thumbnailPath': thumbnailPath,
        'width': width,
        'height': height,
      };
}
