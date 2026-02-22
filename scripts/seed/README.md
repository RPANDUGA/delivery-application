# Firestore Seed Tool

This script seeds Firestore with sample restaurants, orders, and courier tasks.

## Setup
1. Create a Firebase project.
2. Generate a service account key JSON.
3. Save it to `scripts/seed/serviceAccount.json` or set env var `FIREBASE_SERVICE_ACCOUNT` to the file path.

## Run
```bash
cd /Users/Ramesh/Workspace/food_delivery_flutter/scripts/seed
npm install
npm run seed
```

## Set admin claims
After you sign in once (to get a UID), run:
```bash
npm run set-admin -- <YOUR_UID>
```

## Collections created
- `restaurants`
- `orders`
- `courierTasks`
- `courierLocations`
- `courierDeliveries`
