import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/config/app_check_service.dart';
import 'core/localization/locale_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppCheckService.activateIfConfigured();
  final localeController = await LocaleController.load();
  runApp(NarayanaApp(localeController: localeController));
}
