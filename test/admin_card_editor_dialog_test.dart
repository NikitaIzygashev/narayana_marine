import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:narayana_marine/core/localization/app_locale.dart';
import 'package:narayana_marine/core/localization/app_strings.dart';
import 'package:narayana_marine/core/localization/locale_controller.dart';
import 'package:narayana_marine/features/admin/presentation/widgets/admin_card_editor_dialog.dart';
import 'package:narayana_marine/models/cms_models.dart';
import 'package:narayana_marine/services/cms_content_service.dart';

class _MemoryStore implements LocalePreferenceStore {
  @override
  Future<String?> readLocale() async => null;

  @override
  Future<void> writeLocale(String languageCode) async {}
}

const _onePixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  61,
  29,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

void main() {
  testWidgets('English card editor uses English interface labels', (
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
          home: AdminCardEditorDialog(
            kind: CmsCardKind.tours,
            isNew: true,
            card: CmsCard(
              id: 'test-card',
              titleRu: '',
              titleEn: '',
              priceRu: '',
              priceEn: '',
              descriptionRu: '',
              descriptionEn: '',
              images: const [],
              order: 0,
              isPublished: false,
              isDeleting: false,
              pendingStorageDeletes: const [],
            ),
            onSave: (_, _, _) async {},
            pickImages: () async => [
              XFile.fromData(
                Uint8List.fromList(_onePixelPng),
                mimeType: 'image/png',
                name: 'test-image.png',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add card'), findsOneWidget);
    expect(find.text('Title (RU)'), findsOneWidget);
    expect(find.text('Images (0/10)'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);

    final saveButton = find.text('Save');

    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Add a Russian or English title before saving a draft.'),
      findsOneWidget,
    );

    final addButton = find.text('Add');

    expect(addButton, findsOneWidget);

    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Images (1/10)'), findsOneWidget);
    final preview = tester.widget<Image>(find.byType(Image));
    expect(preview.image, isA<MemoryImage>());
  });

  testWidgets('editor selects a tapped image as the canonical cover', (
      tester,
      ) async {
    const first = StoredMedia(
      url: 'https://example.test/first.jpg',
      storagePath: 'fleet/test/first.jpg',
      type: SiteMediaType.image,
    );

    const second = StoredMedia(
      url: 'https://example.test/second.jpg',
      storagePath: 'fleet/test/second.jpg',
      type: SiteMediaType.image,
    );

    CmsCard? savedCard;
    List<CardImageInput>? savedInputs;

    await tester.pumpWidget(
      _editorHarness(
        card: _card(images: const [first, second]),
        onSave: (card, images, _) async {
          savedCard = card;
          savedInputs = images;
        },
      ),
    );

    await tester.pump();

    expect(find.text('Display order'), findsNothing);
    expect(
      find.text(
        'The first image is the cover. Use arrows to change the order.',
      ),
      findsNothing,
    );

    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.arrow_forward), findsNothing);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    final secondImage = find.byWidgetPredicate(
          (widget) =>
      widget is Semantics &&
          widget.properties.label == 'Set cover' &&
          widget.properties.selected == false,
    );

    expect(secondImage, findsOneWidget);

    final secondCoverTarget = find.descendant(
      of: secondImage,
      matching: find.byType(InkWell),
    );

    expect(secondCoverTarget, findsOneWidget);

    await tester.ensureVisible(secondCoverTarget);
    await tester.pumpAndSettle();
    await tester.tap(secondCoverTarget);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(savedCard, isNotNull);
    expect(savedInputs, isNotNull);
    expect(savedCard!.order, 123456789);
    expect(
      savedCard!.images.first.storagePath,
      second.storagePath,
    );
    expect(
      savedInputs!.first.existing!.storagePath,
      second.storagePath,
    );
    expect(
      savedInputs![1].existing!.storagePath,
      first.storagePath,
    );
  });
}

Widget _editorHarness({
  required CmsCard card,
  Future<void> Function(CmsCard, List<CardImageInput>, Set<String>)? onSave,
}) {
  final controller = LocaleController(
    store: _MemoryStore(),
    initialLocale: AppLocale.english,
  );
  return LocaleScope(
    controller: controller,
    child: MaterialApp(
      home: AdminCardEditorDialog(
        kind: CmsCardKind.boats,
        isNew: false,
        card: card,
        onSave: onSave ?? (_, _, _) async {},
      ),
    ),
  );
}

CmsCard _card({List<StoredMedia> images = const []}) => CmsCard(
  id: 'test-card',
  titleRu: 'Название',
  titleEn: 'Title',
  priceRu: '',
  priceEn: '',
  descriptionRu: 'Описание',
  descriptionEn: 'Description',
  images: images,
  order: 123456789,
  isPublished: false,
  isDeleting: false,
  pendingStorageDeletes: const [],
);
