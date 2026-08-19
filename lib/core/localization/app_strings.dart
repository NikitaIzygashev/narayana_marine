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
  String get whyUs => isRussian ? 'Почему мы' : 'Why us';
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
  String get expand => isRussian ? 'Развернуть' : 'Expand';
  String get collapse => isRussian ? 'Свернуть' : 'Collapse';
  String get closeImageViewer =>
      isRussian ? 'Закрыть просмотр изображения' : 'Close image viewer';
  String get previousImage =>
      isRussian ? 'Предыдущее изображение' : 'Previous image';
  String get nextImage => isRussian ? 'Следующее изображение' : 'Next image';
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

  String get add => isRussian ? 'Добавить' : 'Add';
  String get addService => isRussian ? 'Добавить услугу' : 'Add service';
  String get addCard => isRussian ? 'Добавить карточку' : 'Add card';
  String get addImage => isRussian ? 'Добавить изображение' : 'Add image';
  String get edit => isRussian ? 'Редактировать' : 'Edit';
  String get delete => isRussian ? 'Удалить' : 'Delete';
  String get deleteImage => isRussian ? 'Удалить изображение' : 'Delete image';
  String get cancel => isRussian ? 'Отмена' : 'Cancel';
  String get save => isRussian ? 'Сохранить' : 'Save';
  String get signOut => isRussian ? 'Выйти' : 'Sign out';
  String get uploadImage =>
      isRussian ? 'Загрузить изображение' : 'Upload image';
  String get uploadVideo => isRussian ? 'Загрузить видео' : 'Upload video';
  String get uploadFile => isRussian ? 'Загрузить файл' : 'Upload file';
  String get updateFile => isRussian ? 'Обновить файл' : 'Update file';
  String get deleteFile => isRussian ? 'Удалить файл' : 'Delete file';
  String get deleteHeroFileTitle =>
      isRussian ? 'Удалить файл?' : 'Delete file?';
  String get deleteHeroFileBody => isRussian
      ? 'Текущий фон первого экрана будет удалён. Это действие нельзя отменить.'
      : 'The current hero background will be removed. This action cannot be undone.';
  String get couldNotDeleteFile =>
      isRussian ? 'Не удалось удалить файл.' : 'Failed to delete file.';

  String get deleteCardTitle =>
      isRussian ? 'Удалить карточку?' : 'Delete card?';
  String get deleteCardBody => isRussian
      ? 'Файлы этой карточки также будут удалены с сервера.'
      : 'This card’s files will also be deleted from the server.';
  String get deleteImageTitle =>
      isRussian ? 'Удалить изображение?' : 'Delete image?';
  String get deleteImageBody => isRussian
      ? 'Файл также будет удалён с сервера.'
      : 'The file will also be deleted from the server.';
  String get couldNotUploadFile =>
      isRussian ? 'Не удалось загрузить файл.' : 'Could not upload file.';
  String get couldNotDeleteCard => isRussian
      ? 'Не удалось удалить карточку. Очистка будет повторена при следующем входе.'
      : 'Could not delete the card. Cleanup will be retried on the next sign-in.';
  String get galleryLimitReached => isRussian
      ? 'Можно добавить не более 12 изображений.'
      : 'You can add no more than 12 images.';
  String get couldNotUploadImage => isRussian
      ? 'Не удалось загрузить изображение.'
      : 'Could not upload image.';
  String get couldNotDeleteImage =>
      isRussian ? 'Не удалось удалить изображение.' : 'Could not delete image.';
  String get enterService => isRussian ? 'Введите услугу.' : 'Enter a service.';
  String get serviceAlreadyExists => isRussian
      ? 'Такая услуга уже существует.'
      : 'This service already exists.';
  String get couldNotDeleteService =>
      isRussian ? 'Не удалось удалить услугу.' : 'Could not delete service.';
  String get serviceRuLabel => isRussian ? 'Услуга (RU)' : 'Service (RU)';
  String get serviceEnLabel =>
      isRussian ? 'Услуга (EN), необязательно' : 'Service (EN), optional';

  String get adminAccessDenied => isRussian ? 'Нет доступа.' : 'Access denied.';
  String get adminAccessDeniedBody => isRussian
      ? 'Этот аккаунт не имеет прав администратора. Выполнен безопасный выход.'
      : 'This account does not have administrator access. You have been signed out safely.';
  String get signInWithAnotherAccount =>
      isRussian ? 'Войти с другим аккаунтом' : 'Sign in with another account';
  String get adminSignInTitle =>
      isRussian ? 'Вход в панель управления' : 'Sign in to the admin panel';
  String get password => isRussian ? 'Пароль' : 'Password';
  String get enterEmail => isRussian ? 'Введите email.' : 'Enter an email.';
  String get enterPassword =>
      isRussian ? 'Введите пароль.' : 'Enter a password.';
  String get invalidCredentials =>
      isRussian ? 'Неверный email или пароль.' : 'Incorrect email or password.';
  String get signIn => isRussian ? 'Войти' : 'Sign in';

  String get editCard => isRussian ? 'Редактировать карточку' : 'Edit card';
  String get titleRuLabel => isRussian ? 'Название (RU)' : 'Title (RU)';
  String get titleEnLabel => isRussian ? 'Название (EN)' : 'Title (EN)';
  String get priceRuLabel => isRussian ? 'Стоимость (RU)' : 'Price (RU)';
  String get priceEnLabel => isRussian ? 'Стоимость (EN)' : 'Price (EN)';
  String get descriptionRuLabel =>
      isRussian ? 'Описание (RU)' : 'Description (RU)';
  String get descriptionEnLabel =>
      isRussian ? 'Описание (EN)' : 'Description (EN)';
  String imagesCount(int count) =>
      isRussian ? 'Изображения ($count/10)' : 'Images ($count/10)';
  String get addAtLeastOneImage => isRussian
      ? 'Добавьте хотя бы одно изображение.'
      : 'Add at least one image.';
  String get cardImageLimitReached => isRussian
      ? 'Можно добавить не более 10 изображений.'
      : 'You can add no more than 10 images.';
  String get couldNotSaveCard =>
      isRussian ? 'Не удалось сохранить карточку.' : 'Could not save card.';
  String get requiredField =>
      isRussian ? 'Обязательное поле.' : 'This field is required.';

  String contentEditorTitle({required bool isNew, required bool isBoat}) {
    final noun = isBoat
        ? (isRussian ? 'судно' : 'boat')
        : (isRussian ? 'экскурсию' : 'tour');
    return isNew
        ? (isRussian ? 'Добавить $noun' : 'Add $noun')
        : (isRussian ? 'Редактировать $noun' : 'Edit $noun');
  }

  String get identity => isRussian ? 'Идентификатор' : 'Identity';
  String get stableIdLabel =>
      isRussian ? 'Стабильный ID / slug' : 'Stable ID / slug';
  String get name => isRussian ? 'Название' : 'Name';
  String get publishedActive =>
      isRussian ? 'Опубликовано / активно' : 'Published / active';
  String get publishedHint => isRussian
      ? 'На публичном сайте отображаются только опубликованные элементы.'
      : 'Only published items appear on the public website.';
  String get saveContent => isRussian ? 'Сохранить контент' : 'Save content';
  String get contentSaved => isRussian ? 'Контент сохранён.' : 'Content saved.';
  String get saveBeforeGallery => isRussian
      ? 'Сначала сохраните элемент, чтобы загрузить изображения галереи.'
      : 'Save this item before uploading its gallery images.';
  String get boatDetails => isRussian ? 'Данные судна' : 'Boat details';
  String get subtitleType =>
      isRussian ? 'Подзаголовок / тип' : 'Subtitle / type';
  String get description => isRussian ? 'Описание' : 'Description';
  String get lengthOptional => isRussian
      ? 'Длина в метрах (необязательно)'
      : 'Length in metres (optional)';
  String get capacityLabel =>
      isRussian ? 'Подпись вместимости' : 'Capacity label';
  String get specifications => isRussian ? 'Характеристики' : 'Specifications';
  String get onePerLineLabelValue => isRussian
      ? 'По одной на строку: Название: Значение'
      : 'One per line: Label: Value';
  String get experienceDetails =>
      isRussian ? 'Данные экскурсии' : 'Experience details';
  String get shortDescription =>
      isRussian ? 'Краткое описание' : 'Short description';
  String get fullDescription =>
      isRussian ? 'Полное описание' : 'Full description';
  String get destinations => isRussian ? 'Направления' : 'Destinations';
  String get highlights => isRussian ? 'Особенности' : 'Highlights';
  String get onePerLine => isRussian ? 'По одному на строку' : 'One per line';
  String get timingLabelOptional =>
      isRussian ? 'Подпись времени (необязательно)' : 'Timing label (optional)';
  String get itinerary => isRussian ? 'Маршрут' : 'Itinerary';
  String get onePerLineItinerary => isRussian
      ? 'По одному на строку: Время | Заголовок | Описание'
      : 'One per line: Time | Title | Description';
  String get inclusions => isRussian ? 'Что включено' : 'Inclusions';
  String get priceLabelOptional =>
      isRussian ? 'Подпись цены (необязательно)' : 'Price label (optional)';
  String get invalidStableId => isRussian
      ? 'Введите стабильный ID из букв, цифр и дефисов.'
      : 'Enter a stable ID using letters, numbers and hyphens.';
  String get couldNotSaveContent =>
      isRussian ? 'Не удалось сохранить контент.' : 'Could not save content.';
  String galleryTitle(int count) =>
      isRussian ? 'Галерея ($count/10)' : 'Gallery ($count/10)';
  String get optimizedUploadsHint => isRussian
      ? 'Загрузки преобразуются в оптимизированные JPEG-файлы и миниатюры.'
      : 'Uploads are converted to optimized JPEG display and thumbnail files.';
  String get noImagesUploaded =>
      isRussian ? 'Изображения ещё не загружены.' : 'No images uploaded yet.';
  String get coverImage => isRussian ? 'Главное изображение' : 'Cover image';
  String get setCover => isRussian ? 'Сделать главным' : 'Set cover';
  String get moveEarlier => isRussian ? 'Переместить раньше' : 'Move earlier';
  String get moveLater => isRussian ? 'Переместить позже' : 'Move later';
}
