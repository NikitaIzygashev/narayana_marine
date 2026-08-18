import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckService {
  static const _siteKey = String.fromEnvironment('RECAPTCHA_V3_SITE_KEY');

  static Future<void> activateIfConfigured() async {
    if (!kIsWeb || _siteKey.isEmpty) return;
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(_siteKey),
    );
  }
}
