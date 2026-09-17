import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narayana_marine/core/localization/app_locale.dart';
import 'package:narayana_marine/core/localization/app_strings.dart';
import 'package:narayana_marine/core/localization/locale_controller.dart';
import 'package:narayana_marine/core/theme/app_theme.dart';

class _MemoryStore implements LocalePreferenceStore {
  @override
  Future<String?> readLocale() async => null;

  @override
  Future<void> writeLocale(String languageCode) async {}
}

void main() {
  test('Why Narayana content has five approved benefits in both languages', () {
    const english = AppStrings(AppLocale.english);
    const russian = AppStrings(AppLocale.russian);

    expect(english.whyNarayana, 'Why Narayana?');
    expect(russian.whyNarayana, 'Почему Narayana?');
    expect(english.whyNarayanaBenefits, hasLength(5));
    expect(russian.whyNarayanaBenefits, hasLength(5));
    expect(
      english.whyNarayanaBenefits.map((benefit) => benefit.title),
      [
        'Real Boats',
        'Premium Comfort',
        'Early Programs',
        'Real Guest Experience',
        'Reliable B2B Support',
      ],
    );
    expect(
      russian.whyNarayanaBenefits.map((benefit) => benefit.title),
      [
        'Реальные лодки',
        'Комфорт премиального уровня',
        'Ранний старт',
        'Настоящее гостеприимство',
        'Надёжная B2B-поддержка',
      ],
    );
    expect(
      english.whyNarayanaBenefits.map((benefit) => benefit.body),
      [
        'What you see is what you get. Our photos show the actual boats you’ll travel on — no surprises.',
        'More space, comfortable seating, and our signature roof deck make every journey more enjoyable.',
        'We start earlier, giving you a chance to experience the islands before the busiest hours.',
        'Genuine hospitality, attentive service, and comfortable journeys — designed to make your day at sea truly memorable.',
        'Fast communication, dependable coordination, and dedicated support for our travel partners.',
      ],
    );
    expect(
      russian.whyNarayanaBenefits.map((benefit) => benefit.body),
      [
        'Вы получаете именно то, что видите. На наших фотографиях показаны реальные лодки, на которых проходят поездки — без неприятных сюрпризов.',
        'Больше пространства, удобные места и наша фирменная верхняя палуба делают путешествие комфортным от начала до конца.',
        'Мы отправляемся раньше, чтобы вы могли увидеть острова до самых загруженных часов и большого потока туристов.',
        'Искренняя забота, внимательный сервис и комфорт на протяжении всей поездки — чтобы день в море действительно запомнился.',
        'Быстрая связь, чёткая координация и постоянная поддержка наших туристических партнёров.',
      ],
    );
  });

  testWidgets('locale scope switches Why Narayana content between English and Russian', (
      tester,
      ) async {
    final controller = LocaleController(
      store: _MemoryStore(),
      initialLocale: AppLocale.english,
    );

    await tester.pumpWidget(
      LocaleScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              final strings = context.strings;

              return Scaffold(
                body: Column(
                  children: [
                    Text(strings.whyNarayana),
                    for (final benefit in strings.whyNarayanaBenefits)
                      Text(benefit.title),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Why Narayana?'), findsOneWidget);
    expect(find.text('Real Boats'), findsOneWidget);
    expect(find.text('Premium Comfort'), findsOneWidget);
    expect(find.text('Early Programs'), findsOneWidget);
    expect(find.text('Real Guest Experience'), findsOneWidget);
    expect(find.text('Reliable B2B Support'), findsOneWidget);

    await controller.setLocale(AppLocale.russian);
    await tester.pump();

    expect(find.text('Почему Narayana?'), findsOneWidget);
    expect(find.text('Реальные лодки'), findsOneWidget);
    expect(find.text('Комфорт премиального уровня'), findsOneWidget);
    expect(find.text('Ранний старт'), findsOneWidget);
    expect(find.text('Настоящее гостеприимство'), findsOneWidget);
    expect(find.text('Надёжная B2B-поддержка'), findsOneWidget);
    expect(find.text('Why Narayana?'), findsNothing);
    expect(find.text('Real Boats'), findsNothing);
  });
}
