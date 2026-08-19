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
      pendingStorageDeletes: ['fleet/boat/old.jpg'],
    );

    final restored = CmsCard.fromMap(card.id, card.toMap());

    expect(restored.titleFor('ru'), 'Катамаран');
    expect(restored.titleFor('en'), 'Catamaran');
    expect(restored.images, hasLength(1));
    expect(restored.images.single.storagePath, media.storagePath);
    expect(restored.pendingStorageDeletes, ['fleet/boat/old.jpg']);
  });

  test('empty English fields fall back to Russian and signal translation', () {
    const item = ServiceItem(
      id: 'service',
      textRu: 'Трансфер',
      textEn: '',
      order: 10,
    );

    expect(item.textFor('en'), 'Трансфер');
    expect(item.needsEnglishTranslation, isTrue);
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

  test('legacy display media includes its thumbnail in cleanup paths', () {
    const legacy = StoredMedia(
      url: 'https://example.test/boats/vanit/images/1/display.jpg',
      storagePath: 'boats/vanit/images/1/display.jpg',
      type: SiteMediaType.image,
    );

    expect(legacy.storagePaths, [
      'boats/vanit/images/1/display.jpg',
      'boats/vanit/images/1/thumbnail.jpg',
    ]);
  });
}
