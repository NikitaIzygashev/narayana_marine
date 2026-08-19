import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static Future<void> cta(String name) => FirebaseAnalytics.instance.logEvent(
    name: 'cta_click',
    parameters: {'cta_name': name},
  );

  static Future<void> detailOpen(String contentType) =>
      FirebaseAnalytics.instance.logEvent(
        name: 'content_detail_open',
        parameters: {'content_type': contentType},
      );
}
