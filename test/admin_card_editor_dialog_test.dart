import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:narayana_marine/core/localization/app_locale.dart';
import 'package:narayana_marine/core/localization/app_strings.dart';
import 'package:narayana_marine/core/localization/locale_controller.dart';
import 'package:narayana_marine/features/admin/presentation/widgets/admin_card_editor_dialog.dart';
import 'package:narayana_marine/models/cms_models.dart';

class _MemoryStore implements LocalePreferenceStore {
  @override
  Future<String?> readLocale() async => null;

  @override
  Future<void> writeLocale(String languageCode) async {}
}

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
              isPublished: true,
              pendingStorageDeletes: const [],
            ),
            onSave: (_, _, _) async {},
            pickImages: () async => [
              XFile.fromData(Uint8List(0), name: 'test-image.jpg'),
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

    final saveButton = find.text('Save');

    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsNWidgets(2));

    final addButton = find.text('Add');

    expect(addButton, findsOneWidget);

    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Images (1/10)'), findsOneWidget);
  });
}
