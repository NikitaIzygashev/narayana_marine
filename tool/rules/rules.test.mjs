import { readFile } from 'node:fs/promises';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const adminUid = 'mBqYpkC87AgLsfXOVn65JnjPG6A3';
const host = process.env.FIRESTORE_EMULATOR_HOST?.split(':')[0] ?? '127.0.0.1';
const port = Number(process.env.FIRESTORE_EMULATOR_HOST?.split(':')[1] ?? 8080);
const rules = await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8');
const testEnv = await initializeTestEnvironment({
  projectId: 'narayana-marine-rules-test',
  firestore: { host, port, rules },
});

const boat = {
  titleRu: 'Тест', titleEn: 'Test', priceRu: '', priceEn: '',
  descriptionRu: 'Описание', descriptionEn: 'Description', images: [],
  order: 10, isPublished: false, pendingStorageDeletes: [],
  createdAt: new Date(), updatedAt: new Date(),
};

const service = {
  textRu: 'Тестовая услуга', textEn: 'Test service', order: 10,
  createdAt: new Date(), updatedAt: new Date(),
};

try {
  await assertSucceeds(setDoc(doc(testEnv.authenticatedContext(adminUid).firestore(), 'boats', 'test-boat'), boat));
  await assertFails(getDoc(doc(testEnv.unauthenticatedContext().firestore(), 'boats', 'test-boat')));
  await assertFails(setDoc(doc(testEnv.unauthenticatedContext().firestore(), 'boats', 'blocked'), boat));
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'boats', 'published-boat'), { ...boat, isPublished: true });
  });
  await assertSucceeds(getDoc(doc(testEnv.unauthenticatedContext().firestore(), 'boats', 'published-boat')));
  await assertSucceeds(setDoc(doc(testEnv.authenticatedContext(adminUid).firestore(), 'services', 'test-service'), service));
  await assertFails(setDoc(doc(testEnv.unauthenticatedContext().firestore(), 'services', 'blocked-service'), service));
  console.log('Firestore rule tests passed.');
} finally {
  await testEnv.cleanup();
}
