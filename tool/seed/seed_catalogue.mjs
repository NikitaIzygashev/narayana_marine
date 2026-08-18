import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { readFile } from 'node:fs/promises';

const apply = process.argv.includes('--apply');
const catalogue = JSON.parse(
  await readFile(new URL('./initial_catalogue.json', import.meta.url), 'utf8'),
);

initializeApp({ credential: applicationDefault(), projectId: 'narayana-marine' });
const db = getFirestore();

const boatDocument = (item) => ({
  name: item.name,
  subtitle: item.subtitle,
  description: '',
  lengthMeters: item.lengthMeters,
  capacityLabel: item.capacityLabel,
  specifications: [],
  gallery: [],
  coverImageId: null,
  isPublished: false,
  sortOrder: item.sortOrder,
  createdAt: FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
});

const tourDocument = (item) => ({
  name: item.name,
  shortDescription: '',
  fullDescription: '',
  destinations: item.destinations,
  highlights: item.highlights,
  timingLabel: null,
  itinerary: [],
  inclusions: [],
  priceLabel: null,
  gallery: [],
  coverImageId: null,
  isPublished: false,
  sortOrder: item.sortOrder,
  createdAt: FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
});

async function seed(collection, items, documentFor) {
  for (const item of items) {
    const reference = db.collection(collection).doc(item.id);
    const existing = await reference.get();
    if (existing.exists) {
      console.log(`skip ${collection}/${item.id}: already exists`);
      continue;
    }
    if (!apply) {
      console.log(`would create ${collection}/${item.id}`);
      continue;
    }
    await reference.create(documentFor(item));
    console.log(`created ${collection}/${item.id}`);
  }
}

console.log(apply ? 'Applying seed data.' : 'Dry run only. Pass --apply to create documents.');
await seed('boats', catalogue.boats, boatDocument);
await seed('tours', catalogue.tours, tourDocument);
