class GoogleReview {
  const GoogleReview({
    required this.authorName,
    required this.rating,
    required this.text,
    this.relativeDate,
    this.photoUrl,
    this.originalText,
  });

  final String authorName;
  final double rating;
  final String text;
  final String? relativeDate;
  final String? photoUrl;
  final String? originalText;

  factory GoogleReview.fromMap(Map<Object?, Object?> map) => GoogleReview(
    authorName: map['authorName'] as String? ?? '',
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    text: map['text'] as String? ?? '',
    relativeDate: map['relativeDate'] as String?,
    photoUrl: map['photoUrl'] as String?,
    originalText: map['originalText'] as String?,
  );
}

class GoogleReviewsData {
  const GoogleReviewsData({
    required this.rating,
    required this.reviewCount,
    required this.reviews,
    this.formattedAddress,
  });

  final double rating;
  final int reviewCount;
  final List<GoogleReview> reviews;
  final String? formattedAddress;

  factory GoogleReviewsData.fromMap(Map<Object?, Object?> map) {
    final rawReviews = map['reviews'] as List<Object?>? ?? const [];
    return GoogleReviewsData(
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      reviews: rawReviews
          .whereType<Map<Object?, Object?>>()
          .map(GoogleReview.fromMap)
          .toList(growable: false),
      formattedAddress: map['formattedAddress'] as String?,
    );
  }
}
