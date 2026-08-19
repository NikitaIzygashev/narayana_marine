import 'package:flutter_test/flutter_test.dart';
import 'package:narayana_marine/models/cms_models.dart';
import 'package:narayana_marine/services/cms_content_service.dart';

const _imageHero = HeroMedia(
  media: StoredMedia(
    url: 'https://example.test/site/hero/image.jpg',
    storagePath: 'site/hero/image.jpg',
    type: SiteMediaType.image,
  ),
  updatedAt: null,
);

const _videoHero = HeroMedia(
  media: StoredMedia(
    url: 'https://example.test/site/hero/intro.mp4',
    storagePath: 'site/hero/intro.mp4',
    type: SiteMediaType.video,
  ),
  updatedAt: null,
);

void main() {
  test('deletes pending paths before the current image hero file', () async {
    final deletedBatches = <Set<String>>[];
    var documentDeleted = false;

    await HeroMediaDeletionCoordinator(
      fetchHero: () async => _imageHero,
      fetchPendingPaths: () async => ['site/hero/previous.webm'],
      deleteHeroDocument: () async => documentDeleted = true,
      restoreHeroDocument: (_, _) async => fail('must not restore on success'),
      deleteStoragePaths: (paths) async => deletedBatches.add(paths.toSet()),
    ).deleteHero();

    expect(documentDeleted, isTrue);
    expect(deletedBatches, [
      {'site/hero/previous.webm'},
      {'site/hero/image.jpg'},
    ]);
  });

  test(
    'restores the video hero configuration when current storage delete fails',
    () async {
      HeroMedia? restoredHero;
      List<String>? restoredPendingPaths;
      var deleteCalls = 0;

      await expectLater(
        HeroMediaDeletionCoordinator(
          fetchHero: () async => _videoHero,
          fetchPendingPaths: () async => ['site/hero/previous.jpg'],
          deleteHeroDocument: () async {},
          restoreHeroDocument: (hero, pendingPaths) async {
            restoredHero = hero;
            restoredPendingPaths = pendingPaths.toList();
          },
          deleteStoragePaths: (_) async {
            deleteCalls++;
            if (deleteCalls == 2) throw StateError('Storage delete failed');
          },
        ).deleteHero(),
        throwsStateError,
      );

      expect(restoredHero, _videoHero);
      expect(restoredPendingPaths, ['site/hero/previous.jpg']);
    },
  );

  test('does not touch Storage when the Firestore delete fails', () async {
    var storageWasCalled = false;

    await expectLater(
      HeroMediaDeletionCoordinator(
        fetchHero: () async => _imageHero,
        fetchPendingPaths: () async => const [],
        deleteHeroDocument: () async => throw StateError('CMS delete failed'),
        restoreHeroDocument: (_, _) async {},
        deleteStoragePaths: (_) async => storageWasCalled = true,
      ).deleteHero(),
      throwsStateError,
    );

    expect(storageWasCalled, isFalse);
  });

  test('does nothing when Hero media is already absent', () async {
    var wasCalled = false;

    await HeroMediaDeletionCoordinator(
      fetchHero: () async => null,
      fetchPendingPaths: () async => fail('must not fetch pending paths'),
      deleteHeroDocument: () async => wasCalled = true,
      restoreHeroDocument: (_, _) async => wasCalled = true,
      deleteStoragePaths: (_) async => wasCalled = true,
    ).deleteHero();

    expect(wasCalled, isFalse);
  });
}
