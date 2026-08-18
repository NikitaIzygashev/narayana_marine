import 'dart:ui';

enum AppLocale {
  english('en'),
  russian('ru');

  const AppLocale(this.languageCode);

  final String languageCode;

  static AppLocale fromBrowserLocale(Locale locale) {
    return locale.languageCode.toLowerCase().startsWith('ru')
        ? AppLocale.russian
        : AppLocale.english;
  }
}
