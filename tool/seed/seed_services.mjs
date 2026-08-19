import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { readFile } from 'node:fs/promises';

const apply = process.argv.includes('--apply');
const services = JSON.parse(
  await readFile(new URL('./initial_services.json', import.meta.url), 'utf8'),
);

initializeApp({ credential: applicationDefault(), projectId: 'narayana-marine' });
const db = getFirestore();

console.log(apply ? 'Applying initial services.' : 'Dry run only. Pass --apply to create documents.');
for (const item of services) {
  const reference = db.collection('services').doc(item.id);
  const existing = await reference.get();
  if (existing.exists) {
    console.log(`skip services/${item.id}: already exists`);
    continue;
  }
  if (!apply) {
    console.log(`would create services/${item.id}`);
    continue;
  }
  await reference.create({
    textRu: item.textRu,
    textEn: item.textEn,
    order: item.order,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  console.log(`created services/${item.id}`);
}
