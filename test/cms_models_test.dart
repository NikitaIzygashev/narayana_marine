import 'package:flutter_test/flutter_test.dart';
import 'package:narayana_marine/models/cms_models.dart';

void main() {
  const media = StoredMedia(
    url: 'https://example.test/fleet/boat/photo.webp',
    storagePath: 'fleet/boat/photo.webp',
    type: SiteMediaType.image,
  );

  test('media serializes its Storage path and type', () {
    final restored = StoredMedia.fromMap(media.toMap());

    expect(restored.url, media.url);
    expect(restored.storagePath, 'fleet/boat/photo.webp');
    expect(restored.type, SiteMediaType.image);
  });

  test('card serialization keeps locale fields and image limit data', () {
    const card = CmsCard(
      id: 'boat-1',
      titleRu: 'Катамаран',
      titleEn: 'Catamaran',
      priceRu: '10 000 THB',
      priceEn: '10,000 THB',
      descriptionRu: 'Описание',
      descriptionEn: 'Description',
      images: [media],
      order: 10,
      isPublished: true,
      isDeleting: false,
      pendingStorageDeletes: ['fleet/boat/old.jpg'],
    );

    final restored = CmsCard.fromMap(card.id, card.toMap());

    expect(restored.titleFor('ru'), 'Катамаран');
    expect(restored.titleFor('en'), 'Catamaran');
    expect(restored.images, hasLength(1));
    expect(restored.images.single.storagePath, media.storagePath);
    expect(restored.pendingStorageDeletes, ['fleet/boat/old.jpg']);
    expect(
      card.toMap().keys,
      unorderedEquals([
        'titleRu',
        'titleEn',
        'priceRu',
        'priceEn',
        'descriptionRu',
        'descriptionEn',
        'images',
        'order',
        'isPublished',
        'isDeleting',
        'pendingStorageDeletes',
      ]),
    );
  });

  test('a draft needs a title in at least one language', () {
    const card = CmsCard(
      id: 'draft',
      titleRu: '',
      titleEn: '',
      priceRu: '',
      priceEn: '',
      descriptionRu: '',
      descriptionEn: '',
      images: [],
      order: 10,
      isPublished: false,
      isDeleting: false,
      pendingStorageDeletes: [],
    );

    expect(
      card.validationIssue(forPublish: false),
      CmsCardValidationIssue.draftTitleRequired,
    );
    expect(
      card.copyWith(titleEn: 'Draft').validationIssue(forPublish: false),
      isNull,
    );
  });

  test('publication requires bilingual content and a cover image', () {
    const draft = CmsCard(
      id: 'draft',
      titleRu: 'Катамаран',
      titleEn: 'Catamaran',
      priceRu: '',
      priceEn: '',
      descriptionRu: 'Описание',
      descriptionEn: 'Description',
      images: [],
      order: 10,
      isPublished: true,
      isDeleting: false,
      pendingStorageDeletes: [],
    );

    expect(
      draft.validationIssue(forPublish: true),
      CmsCardValidationIssue.imageRequired,
    );
    expect(
      draft.copyWith(images: [media]).validationIssue(forPublish: true),
      isNull,
    );
  });

  test('the first stored image remains the cover after reordering', () {
    const second = StoredMedia(
      url: 'https://example.test/fleet/boat/second.png',
      storagePath: 'fleet/boat/second.png',
      type: SiteMediaType.image,
    );
    const card = CmsCard(
      id: 'boat',
      titleRu: 'Катамаран',
      titleEn: 'Catamaran',
      priceRu: '',
      priceEn: '',
      descriptionRu: 'Описание',
      descriptionEn: 'Description',
      images: [second, media],
      order: 0,
      isPublished: true,
      isDeleting: false,
      pendingStorageDeletes: [],
    );

    final restored = CmsCard.fromMap(card.id, card.toMap());

    expect(restored.images.first.storagePath, second.storagePath);
    expect(restored.validationIssue(forPublish: true), isNull);
  });

  test('hero media preserves video type and path', () {
    const hero = HeroMedia(
      media: StoredMedia(
        url: 'https://example.test/site/hero/intro.mp4',
        storagePath: 'site/hero/intro.mp4',
        type: SiteMediaType.video,
      ),
      updatedAt: null,
    );

    final restored = HeroMedia.fromMap(hero.toMap());

    expect(restored.media.type, SiteMediaType.video);
    expect(restored.media.storagePath, 'site/hero/intro.mp4');
  });

  test('media cleanup uses only the canonical storage path', () {
    expect(media.storagePaths, ['fleet/boat/photo.webp']);
  });
}
