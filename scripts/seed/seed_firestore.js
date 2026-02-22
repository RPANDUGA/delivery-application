import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import admin from 'firebase-admin';

const rootDir = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../..');
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT || path.join(rootDir, 'scripts/seed/serviceAccount.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Missing service account JSON. Set FIREBASE_SERVICE_ACCOUNT or place file at scripts/seed/serviceAccount.json');
  process.exit(1);
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf-8'));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const restaurants = [
  {
    id: 'r1',
    name: 'Harvest & Hearth',
    cuisine: 'Farm-to-table',
    rating: 4.7,
    etaMinutes: 28,
    heroImage: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
  },
  {
    id: 'r2',
    name: 'Nori House',
    cuisine: 'Japanese',
    rating: 4.5,
    etaMinutes: 32,
    heroImage: 'https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&w=1200&q=80',
  },
  {
    id: 'r3',
    name: 'Cinder Pizza Co.',
    cuisine: 'Wood-fired pizza',
    rating: 4.8,
    etaMinutes: 24,
    heroImage: 'https://images.unsplash.com/photo-1542281286-9e0a16bb7366?auto=format&fit=crop&w=1200&q=80',
  },
];

const orders = [
  {
    id: '1012',
    restaurantId: 'r1',
    customerId: 'c1',
    total: 21.5,
    status: 'enRoute',
    createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-02-08T12:30:00Z')),
    lines: [
      { itemId: 'm1', name: 'Roasted Veggie Bowl', quantity: 1, price: 14.5 },
      { itemId: 'm2', name: 'Citrus Mint Tea', quantity: 2, price: 3.5 },
    ],
  },
  {
    id: '1013',
    restaurantId: 'r2',
    customerId: 'c1',
    total: 18.0,
    status: 'preparing',
    createdAt: admin.firestore.Timestamp.fromDate(new Date('2026-02-08T12:45:00Z')),
    lines: [
      { itemId: 'm3', name: 'Salmon Donburi', quantity: 1, price: 16.0 },
    ],
  },
];

const courierTasks = [
  {
    id: 't1',
    orderId: '1012',
    pickupAddress: '81 Market St',
    dropoffAddress: '200 Pine Ave',
    payout: 8.5,
    etaMinutes: 14,
  },
  {
    id: 't2',
    orderId: '1014',
    pickupAddress: '12 Union Square',
    dropoffAddress: '955 Lakeview Dr',
    payout: 10.25,
    etaMinutes: 20,
  },
];

const courierLocations = [
  {
    id: '1012',
    lat: 37.7896,
    lng: -122.4028,
    updatedAt: admin.firestore.Timestamp.fromDate(new Date('2026-02-08T12:44:00Z')),
  },
];

const courierDeliveries = [
  {
    id: '1010',
    courierId: 'courier-1',
    basePayout: 7.75,
    tip: 0.0,
    overridePayout: null,
    rating: 4.0,
    completedAt: admin.firestore.Timestamp.fromDate(new Date('2026-02-07T18:20:00Z')),
  },
  {
    id: '1011',
    courierId: 'courier-1',
    basePayout: 9.5,
    tip: 2.0,
    overridePayout: null,
    rating: 5.0,
    completedAt: admin.firestore.Timestamp.fromDate(new Date('2026-02-08T11:10:00Z')),
  },
  {
    id: '1012',
    courierId: 'courier-1',
    basePayout: 8.5,
    tip: 1.5,
    overridePayout: null,
    rating: 4.5,
    completedAt: admin.firestore.Timestamp.fromDate(new Date('2026-02-08T13:05:00Z')),
  },
];


async function upsertCollection(collectionName, docs) {
  const batch = db.batch();
  docs.forEach((doc) => {
    const ref = db.collection(collectionName).doc(doc.id);
    batch.set(ref, doc, { merge: true });
  });
  await batch.commit();
}

async function main() {
  console.log('Seeding Firestore...');
  await upsertCollection('restaurants', restaurants);
  await upsertCollection('orders', orders);
  await upsertCollection('courierTasks', courierTasks);
  await upsertCollection('courierLocations', courierLocations);
  await upsertCollection('courierDeliveries', courierDeliveries);
  console.log('Seed complete.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
