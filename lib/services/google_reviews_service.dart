import 'package:cloud_functions/cloud_functions.dart';

import '../models/google_reviews.dart';

/// A server-side integration should implement this interface. It deliberately
/// has no Places API implementation in the browser, where a web-service key
/// would be exposed.
abstract class GoogleReviewsService {
  Future<GoogleReviewsData?> fetchReviews({required String languageCode});
}

class FirebaseGoogleReviewsService implements GoogleReviewsService {
  FirebaseGoogleReviewsService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  @override
  Future<GoogleReviewsData?> fetchReviews({required String languageCode}) async {
    try {
      final result = await _functions
          .httpsCallable('getGoogleReviews')
          .call<Map<Object?, Object?>>({'languageCode': languageCode});
      return GoogleReviewsData.fromMap(result.data);
    } on FirebaseFunctionsException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
