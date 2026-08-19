import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:narayana_marine/core/localization/app_locale.dart';
import 'package:narayana_marine/core/localization/app_strings.dart';
import 'package:narayana_marine/core/localization/locale_controller.dart';
import 'package:narayana_marine/models/google_reviews.dart';
import 'package:narayana_marine/models/media_content.dart';

class _MemoryStore implements LocalePreferenceStore {
  _MemoryStore(this.value);

  String? value;

  @override
  Future<String?> readLocale() async => value;

  @override
  Future<void> writeLocale(String languageCode) async {
    value = languageCode;
  }
}

void main() {
  test('uses Russian for browser locales beginning with ru', () async {
    final controller = await LocaleController.load(
      browserLocale: const Locale('ru', 'KZ'),
      store: _MemoryStore(null),
    );

    expect(controller.locale, AppLocale.russian);
  });

  test('uses English for every non-Russian browser locale', () async {
    final controller = await LocaleController.load(
      browserLocale: const Locale('th', 'TH'),
      store: _MemoryStore(null),
    );

    expect(controller.locale, AppLocale.english);
  });

  test('saved manual locale takes precedence and persists changes', () async {
    final store = _MemoryStore('en');
    final controller = await LocaleController.load(
      browserLocale: const Locale('ru', 'RU'),
      store: store,
    );

    expect(controller.locale, AppLocale.english);
    await controller.setLocale(AppLocale.russian);
    expect(store.value, 'ru');
    expect(controller.locale, AppLocale.russian);
  });

  test(
    'public navigation and hero strings are available in both languages',
    () {
      const english = AppStrings(AppLocale.english);
      const russian = AppStrings(AppLocale.russian);

      expect(english.whyUs, 'Why us');
      expect(russian.whyUs, 'Почему мы');
      expect(english.heroEyebrow, 'PHUKET • THAILAND');
      expect(russian.heroEyebrow, 'ПХУКЕТ • ТАИЛАНД');
      expect(russian.bookNow, 'Забронировать');
      expect(english.contentEyebrow, 'OUR CONTENT');
      expect(russian.sectionInDevelopment, 'Раздел находится в разработке');
      expect(
        english.sectionInDevelopment,
        'This section is currently in development.',
      );
    },
  );

  test('key admin actions are available in Russian and English', () {
    const english = AppStrings(AppLocale.english);
    const russian = AppStrings(AppLocale.russian);

    expect(english.addService, 'Add service');
    expect(russian.addService, 'Добавить услугу');
    expect(english.addCard, 'Add card');
    expect(russian.addCard, 'Добавить карточку');
    expect(english.addImage, 'Add image');
    expect(russian.addImage, 'Добавить изображение');
    expect(english.signOut, 'Sign out');
    expect(russian.signOut, 'Выйти');
    expect(english.edit, 'Edit');
    expect(russian.edit, 'Редактировать');
    expect(english.delete, 'Delete');
    expect(russian.delete, 'Удалить');
    expect(english.save, 'Save');
    expect(russian.save, 'Сохранить');
    expect(english.cancel, 'Cancel');
    expect(russian.cancel, 'Отмена');
    expect(english.expand, 'Expand');
    expect(russian.expand, 'Развернуть');
    expect(english.collapse, 'Collapse');
    expect(russian.collapse, 'Свернуть');
  });

  test('Google reviews response parser accepts minimal callable payload', () {
    final data = GoogleReviewsData.fromMap({
      'rating': 4.8,
      'reviewCount': 12,
      'formattedAddress': 'Verified address from Google',
      'reviews': [
        {
          'authorName': 'Guest',
          'rating': 5,
          'text': 'Real API text',
          'originalText': 'Original API text',
          'relativeDate': 'a week ago',
        },
      ],
    });

    expect(data.rating, 4.8);
    expect(data.reviewCount, 12);
    expect(data.formattedAddress, 'Verified address from Google');
    expect(data.reviews.single.authorName, 'Guest');
    expect(data.reviews.single.originalText, 'Original API text');
  });

  test('video content requires a preview before public rendering', () {
    final withoutPreview = MediaContent.fromMap('video-1', {
      'type': 'video',
      'mediaUrl': 'https://example.test/video.mp4',
      'isPublished': true,
      'sortOrder': 10,
    });
    final withPreview = MediaContent.fromMap('video-2', {
      'type': 'video',
      'mediaUrl': 'https://example.test/video.mp4',
      'thumbnailUrl': 'https://example.test/preview.jpg',
      'isPublished': true,
      'sortOrder': 20,
    });

    expect(withoutPreview.isRenderable, isFalse);
    expect(withPreview.isRenderable, isTrue);
  });
}
