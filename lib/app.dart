import 'package:flutter/material.dart';

import 'core/localization/app_strings.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class NarayanaApp extends StatelessWidget {
  const NarayanaApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) => MaterialApp.router(
        title: 'Narayana Marine - Phuket Catamaran Tours',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
        builder: (context, child) => LocaleScope(
          controller: localeController,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
