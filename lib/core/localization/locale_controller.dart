import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

abstract class LocalePreferenceStore {
  Future<String?> readLocale();
  Future<void> writeLocale(String languageCode);
}

class SharedPreferencesLocaleStore implements LocalePreferenceStore {
  static const _key = 'narayana_marine.selected_locale';

  @override
  Future<String?> readLocale() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key);
  }

  @override
  Future<void> writeLocale(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, languageCode);
  }
}

class LocaleController extends ChangeNotifier {
  LocaleController({
    required LocalePreferenceStore store,
    required AppLocale initialLocale,
  }) : this._(
    store: store,
    initialLocale: initialLocale,
  );

  LocaleController._({
    required this._store,
    required AppLocale initialLocale,
  }) : _locale = initialLocale;

  final LocalePreferenceStore _store;
  AppLocale _locale;

  AppLocale get locale => _locale;

  static Future<LocaleController> load({
    Locale? browserLocale,
    LocalePreferenceStore? store,
  }) async {
    final preferenceStore = store ?? SharedPreferencesLocaleStore();
    final saved = await preferenceStore.readLocale();

    final savedLocale = switch (saved) {
      'ru' => AppLocale.russian,
      'en' => AppLocale.english,
      _ => null,
    };

    final initialLocale =
        savedLocale ??
            AppLocale.fromBrowserLocale(
              browserLocale ?? PlatformDispatcher.instance.locale,
            );

    return LocaleController(
      store: preferenceStore,
      initialLocale: initialLocale,
    );
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) {
      return;
    }

    _locale = locale;
    notifyListeners();

    await _store.writeLocale(locale.languageCode);
  }
}