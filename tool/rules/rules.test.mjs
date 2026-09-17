import { readFile } from 'node:fs/promises';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';

const adminUid = 'mBqYpkC87AgLsfXOVn65JnjPG6A3';
const firestoreHost =
  process.env.FIRESTORE_EMULATOR_HOST?.split(':')[0] ?? '127.0.0.1';
const firestorePort = Number(
  process.env.FIRESTORE_EMULATOR_HOST?.split(':')[1] ?? 8080,
);
const storageHost =
  process.env.FIREBASE_STORAGE_EMULATOR_HOST?.split(':')[0] ?? '127.0.0.1';
const storagePort = Number(
  process.env.FIREBASE_STORAGE_EMULATOR_HOST?.split(':')[1] ?? 9199,
);
const firestoreRules = await readFile(
  new URL('../../firestore.rules', import.meta.url),
  'utf8',
);
const storageRules = await readFile(
  new URL('../../storage.rules', import.meta.url),
  'utf8',
);
const testEnv = await initializeTestEnvironment({
  projectId: 'narayana-marine-rules-test',
  firestore: { host: firestoreHost, port: firestorePort, rules: firestoreRules },
  storage: { host: storageHost, port: storagePort, rules: storageRules },
});

const timestamps = {
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
};
const image = {
  url: 'https://example.test/fleet/published-boat/photo.jpg',
  storagePath: 'fleet/published-boat/photo.jpg',
  type: 'image',
};
const draftBoat = {
  titleRu: 'Тест',
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
  ...timestamps,
};
const publishedBoat = {
  ...draftBoat,
  titleEn: 'Test',
  descriptionRu: 'Описание',
  descriptionEn: 'Description',
  images: [image],
  isPublished: true,
};

try {
  const admin = testEnv.authenticatedContext(adminUid);
  const visitor = testEnv.unauthenticatedContext();

  await assertSucceeds(setDoc(doc(admin.firestore(), 'boats', 'test-boat'), draftBoat));
  await assertFails(getDoc(doc(visitor.firestore(), 'boats', 'test-boat')));
  await assertFails(
    setDoc(doc(admin.firestore(), 'boats', 'invalid-draft'), {
      ...draftBoat,
      titleRu: '',
    }),
  );
  await assertFails(
    setDoc(doc(admin.firestore(), 'boats', 'invalid-published'), {
      ...draftBoat,
      isPublished: true,
    }),
  );
  await assertFails(
    setDoc(doc(admin.firestore(), 'boats', 'legacy-field'), {
      ...draftBoat,
      name: 'Legacy name',
    }),
  );
  await assertFails(
    setDoc(doc(admin.firestore(), 'boats', 'too-many-images'), {
      ...publishedBoat,
      images: Array.from({ length: 11 }, (_, index) => ({
        ...image,
        url: `https://example.test/fleet/too-many-images/${index}.jpg`,
        storagePath: `fleet/too-many-images/${index}.jpg`,
      })),
    }),
  );
  await assertSucceeds(
    setDoc(doc(admin.firestore(), 'boats', 'published-boat'), publishedBoat),
  );
  await assertSucceeds(
    setDoc(doc(admin.firestore(), 'boats', 'seven-image-boat'), {
      ...publishedBoat,
      images: Array.from({ length: 7 }, (_, index) => ({
        ...image,
        url: `https://example.test/fleet/seven-image-boat/${index}.jpg`,
        storagePath: `fleet/seven-image-boat/${index}.jpg`,
      })),
    }),
  );
  await assertSucceeds(
    getDoc(doc(visitor.firestore(), 'boats', 'published-boat')),
  );
  await assertFails(
    setDoc(doc(visitor.firestore(), 'boats', 'published-boat'), publishedBoat),
  );
  await assertFails(deleteDoc(doc(visitor.firestore(), 'boats', 'published-boat')));
  await assertSucceeds(
    setDoc(doc(admin.firestore(), 'tours', 'test-tour'), {
      ...publishedBoat,
      images: [
        {
          ...image,
          storagePath: 'excursions/test-tour/photo.jpg',
          url: 'https://example.test/excursions/test-tour/photo.jpg',
        },
      ],
    }),
  );
  await assertFails(
    setDoc(doc(admin.firestore(), 'tours', 'invalid-tour'), {
      ...publishedBoat,
      images: [image],
    }),
  );

  const imageBytes = new Uint8Array([0xff, 0xd8, 0xff]);
  await assertSucceeds(
    uploadBytes(ref(admin.storage(), 'fleet/test-boat/photo.jpg'), imageBytes, {
      contentType: 'image/jpeg',
    }),
  );
  await assertFails(
    uploadBytes(ref(visitor.storage(), 'fleet/blocked/photo.jpg'), imageBytes, {
      contentType: 'image/jpeg',
    }),
  );
  await assertFails(
    uploadBytes(ref(admin.storage(), 'fleet/test-boat/photo.gif'), imageBytes, {
      contentType: 'image/gif',
    }),
  );
  await assertFails(
    uploadBytes(
      ref(admin.storage(), 'fleet/test-boat/too-large.jpg'),
      new Uint8Array(10 * 1024 * 1024 + 1),
      { contentType: 'image/jpeg' },
    ),
  );
  await assertSucceeds(
    getBytes(ref(visitor.storage(), 'fleet/test-boat/photo.jpg')),
  );

  console.log('Firestore and Storage rule tests passed.');
} finally {
  await testEnv.cleanup();
}
