import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narayana_marine/core/localization/app_locale.dart';
import 'package:narayana_marine/core/localization/app_strings.dart';
import 'package:narayana_marine/core/localization/locale_controller.dart';
import 'package:narayana_marine/features/public/presentation/home_page.dart';
import 'package:narayana_marine/models/cms_models.dart';

class _MemoryStore implements LocalePreferenceStore {
  @override
  Future<String?> readLocale() async => null;

  @override
  Future<void> writeLocale(String languageCode) async {}
}

void main() {
  testWidgets(
    'thumbnails display on a collapsed card with multiple images',
        (tester) async {
      await tester.pumpWidget(
        _cardHarness(
          expanded: false,
          imageCount: 2,
        ),
      );

      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    },
  );

  testWidgets(
    'thumbnails remain on an expanded card with multiple images',
        (tester) async {
      await tester.pumpWidget(
        _cardHarness(
          expanded: true,
          imageCount: 2,
        ),
      );

      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    },
  );

  testWidgets(
    'thumbnail strip is hidden when a card has one image',
        (tester) async {
      await tester.pumpWidget(
        _cardHarness(
          expanded: false,
          imageCount: 1,
        ),
      );

      await tester.pump();

      expect(find.byType(ListView), findsNothing);
    },
  );
}

Widget _cardHarness({
  required bool expanded,
  required int imageCount,
}) {
  final controller = LocaleController(
    store: _MemoryStore(),
    initialLocale: AppLocale.english,
  );

  return LocaleScope(
    controller: controller,
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CmsContentCard(
            item: CmsCard(
              id: 'test-card',
              titleRu: 'Название',
              titleEn: 'Title',
              priceRu: '',
              priceEn: '',
              descriptionRu: 'Описание',
              descriptionEn: 'Description',
              images: List.generate(
                imageCount,
                    (index) => StoredMedia(
                  url: 'https://example.test/$index.jpg',
                  storagePath: 'fleet/test/$index.jpg',
                  type: SiteMediaType.image,
                ),
              ),
              order: 1,
              isPublished: true,
              isDeleting: false,
              pendingStorageDeletes: const [],
            ),
            expanded: expanded,
            adminMode: false,
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    ),
  );
}