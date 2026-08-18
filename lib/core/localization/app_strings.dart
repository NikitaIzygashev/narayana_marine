import 'package:flutter/widgets.dart';

import 'app_locale.dart';
import 'locale_controller.dart';

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    required LocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static LocaleController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope is not available above this widget.');
    return scope!.notifier!;
  }

  static AppStrings of(BuildContext context) =>
      AppStrings(controllerOf(context).locale);
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => LocaleScope.of(this);
}

class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  bool get isRussian => locale == AppLocale.russian;
  String get englishLanguage => 'English';
  String get russianLanguage => 'Русский';
  String get heroEyebrow =>
      isRussian ? 'ПХУКЕТ • ТАИЛАНД' : 'PHUKET • THAILAND';
  String get toursNav => isRussian ? 'Экскурсии' : 'Tours';
  String get whyUs => isRussian ? 'Почему мы' : 'Why Us';
  String get ourFleetNav => isRussian ? 'Наш флот' : 'Our Fleet';
  String get bookNow => isRussian ? 'Забронировать' : 'Book now';
  String get openNavigation =>
      isRussian ? 'Открыть навигацию' : 'Open navigation';

  String get heroTitle => isRussian
      ? 'Дарим моменты,\nкоторые греют.'
      : "Moments you'll carry with you.";
  String get heroServices => isRussian
      ? 'Премиальные катамараны • Ранние программы • Частные чартеры'
      : 'Premium catamarans • Early departures • Private charters';
  String get heroDescription => isRussian
      ? 'Твоё море. Твои острова. Наша забота.'
      : 'Your sea. Your islands. Our care.';
  String get exploreTours => isRussian ? 'Экскурсии' : 'Explore tours';
  String get privateCharter => isRussian ? 'Частный чартер' : 'Private Charter';

  String get aboutEyebrow => isRussian ? 'О КОМПАНИИ' : 'ABOUT US';
  String get aboutTitle => isRussian
      ? 'Каждое путешествие продумано до мелочей.'
      : 'Every journey, thoughtfully designed.';
  String get aboutBody => isRussian
      ? 'Narayana Marine — особенный взгляд на путешествия по Андаманскому морю. Продуманные маршруты, современные катамараны и профессиональная команда. От приватных чартеров до ярких путешествий по островам — мы создаём дни, которые хочется прожить снова.'
      : "Narayana Marine offers a different way to experience the Andaman Sea. Thoughtfully planned routes, modern catamarans and a professional crew come together to make every journey effortless. From private charters to unforgettable island adventures, we create days you'll want to experience all over again.";

  String get whyEyebrow => isRussian ? 'ПОЧЕМУ МЫ' : 'WHY US';
  String get whyTitle =>
      isRussian ? 'Ваш комфорт - наш приоритет.' : 'Your comfort comes first.';
  List<String> get whyValues => isRussian
      ? const [
          'Премиальный флот катамаранов',
          'Комфортные кресла авиационного типа',
          'Фирменные ранние программы',
          'Просторная верхняя обзорная палуба',
          'Профессиональная опытная команда',
          'Высокие стандарты безопасности',
          'Wi‑Fi на борту',
          'Трансфер из отеля',
          'Медицинская страховка',
          'Холодные и горячие напитки',
          'Свежие фрукты',
          'Бесплатные полотенца',
          'Для семей и детей',
          'Гибкие частные чартеры',
          'Быстрая B2B-поддержка',
          'Надёжный оператор на Пхукете',
        ]
      : const [
          'Premium catamaran fleet',
          'Comfortable aircraft-style seating',
          'Signature early-bird departures',
          'Spacious rooftop viewing deck',
          'Professional, experienced crew',
          'High safety standards',
          'Wi-Fi on board',
          'Hotel transfers',
          'Medical insurance',
          'Cold and hot drinks',
          'Fresh fruit',
          'Complimentary towels',
          'Family-friendly and kids welcome',
          'Flexible private charters',
          'Fast B2B support',
          'A reliable Phuket operator',
        ];
  String get whyNote => isRussian
      ? '*Актуальный состав услуг зависит от судна и программы. Уточняйте у менеджеров.'
      : '*Inclusions vary by vessel and tour. Please check the latest details with our team.';

  String get toursEyebrow => isRussian ? 'ЭКСКУРСИИ' : 'TOURS';
  String get toursTitle => isRussian
      ? 'Лучшие тайминги для посещения островов.'
      : 'The right timing makes all the difference.';
  String get toursEmpty =>
      isRussian ? 'Экскурсии готовятся.' : 'Tours are being prepared.';
  String get fleetEyebrow => isRussian ? 'НАШ ФЛОТ' : 'OUR FLEET';
  String get fleetTitle => isRussian
      ? 'Каждое путешествие с нами - уникальное и безопасное.'
      : 'Every journey with us is unique, comfortable and safe.';
  String get fleetEmpty => isRussian
      ? 'Презентации флота готовятся.'
      : 'Fleet presentations are being prepared.';
  String get contentEyebrow => isRussian ? 'НАШ КОНТЕНТ' : 'OUR CONTENT';
  String get contentTitle =>
      isRussian ? 'Улыбки. Брызги. Радость.' : 'Smiles. Sea spray. Pure joy.';
  String get earlyBirdAdventure =>
      isRussian ? 'Раннее приключение' : 'Early bird adventure';
  String get viewDetails => isRussian ? 'Подробнее →' : 'View details →';
  String get contentUnavailable => isRussian
      ? 'Этот контент временно недоступен.'
      : 'This content is temporarily unavailable.';
  String get tryAgain => isRussian ? 'Повторить' : 'Try again';
  String get sectionInDevelopment => isRussian
      ? 'Раздел находится в разработке'
      : 'This section is currently in development.';

  String get b2bEyebrow => isRussian ? 'B2B-ПАРТНЁРСТВО' : 'B2B PARTNERSHIPS';
  String get b2bTitle => isRussian
      ? 'Локальная экспертиза. Быстрые подтверждения. Надёжный результат.'
      : 'Local knowledge. Fast confirmations. Dependable delivery.';
  String get b2bBody => isRussian
      ? 'Narayana Marine поддерживает турагентства, DMC, туроператоров, OTA и корпоративных партнёров надёжными операциями на Пхукете и быстрой локальной поддержкой.'
      : 'Narayana Marine supports travel agencies, DMCs, tour operators, OTAs and corporate partners with dependable Phuket operations and responsive local support.';

  String get reviewsEyebrow => isRussian ? 'ОТЗЫВЫ GOOGLE' : 'GOOGLE REVIEWS';
  String get reviewsTitle => isRussian
      ? 'Ваше доверие - наша награда'
      : 'Your trust means everything to us.';
  String get reviewsUnavailable => isRussian
      ? 'Актуальные отзывы гостей доступны в профиле Narayana Marine на Google Maps.'
      : 'Read the latest guest feedback on Narayana Marine’s Google Maps profile.';
  String get readAllReviews =>
      isRussian ? 'Все отзывы в Google' : 'See all reviews on Google';
  String get reviewFromGoogle =>
      isRussian ? 'Отзыв из Google' : 'Review from Google';

  String get contactEyebrow =>
      isRussian ? 'МОРСКИЕ ПРИКЛЮЧЕНИЯ ЖДУТ' : 'YOUR ANDAMAN ADVENTURE AWAITS';
  String get contactTitle => isRussian
      ? 'Ваш отдых — наша ответственность.'
      : 'Your holiday. Our responsibility.';
  String get ourAddress => isRussian ? 'Наш адрес' : 'OUR LOCATION';
  String get addressNeedsVerification => isRussian
      ? 'Адрес ожидает подтверждения Google Maps.'
      : 'Address awaiting Google Maps verification.';
  String get openInGoogleMaps =>
      isRussian ? 'Открыть в Google Maps' : 'Open in Google Maps';
  String get emailLabel => 'Email';
  String get whatsappLabel => 'WhatsApp';
  String get lineLabel => 'LINE';
  String get numberCopied => isRussian ? 'Номер скопирован' : 'Number copied';

  String get closeDetails => isRussian ? 'Закрыть детали' : 'Close details';
  String get length => isRussian ? 'Длина' : 'Length';
  String get included => isRussian ? 'Включено' : 'Included';
  String get andamanSeaExperience =>
      isRussian ? 'Впечатление Андаманского моря' : 'Andaman Sea experience';
}
