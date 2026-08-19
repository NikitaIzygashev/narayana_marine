import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'app.dart';
import 'core/config/app_check_service.dart';
import 'core/localization/locale_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase Hosting rewrites /admin to index.html. Read the browser pathname
  // (rather than an empty # hash) so GoRouter receives /admin on first load.
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppCheckService.activateIfConfigured();
  final localeController = await LocaleController.load();
  runApp(NarayanaApp(localeController: localeController));
}
