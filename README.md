# Food Delivery Flutter (Customer + Courier + Restaurant/Admin)

This repo scaffolds a Flutter multi-app workspace with shared packages and Firebase-ready data layer.

## Structure
- `apps/customer_app`
- `apps/courier_app`
- `apps/restaurant_admin_app`
- `packages/shared` (design system + models)
- `packages/data` (repositories + Firebase adapter)
- `templates/*` (app `lib/` sources to copy into each app)
- `scripts/bootstrap.sh` (creates Flutter apps and wires dependencies)

## Prerequisites
- Flutter SDK (3.x) installed and on PATH
- Android SDK / Android Studio
- Firebase project (one project, three Android apps)

## Firebase setup
1. Create a Firebase project.
2. Add Android apps:
   - `com.fooddelivery.customer`
   - `com.fooddelivery.courier`
   - `com.fooddelivery.restaurant`
3. Download each `google-services.json` and place into:
   - `apps/customer_app/android/app/`
   - `apps/courier_app/android/app/`
   - `apps/restaurant_admin_app/android/app/`
4. (Recommended) Install FlutterFire CLI and generate `firebase_options.dart` for each app.
   - You can run `flutterfire configure` per app directory.
   - The templates include placeholder `firebase_options.dart` so the apps build, but replace them with the generated files.
5. Enable Email/Password authentication in Firebase Console.
6. Set admin custom claims for restaurant admin users (used for payout overrides).
   - Run `npm run set-admin -- <UID>` in `scripts/seed` after signing in once to get the UID.
   - Deploy `firestore.rules` to enforce admin-only overrides.

## Seed data
To seed Firestore with sample restaurants, orders, and courier tasks:
```bash
cd /Users/Ramesh/Workspace/food_delivery_flutter/scripts/seed
npm install
npm run seed
```
See `scripts/seed/README.md` for service account setup.

## Auth
Each app starts with an auth gate. If Firebase init fails (missing options), it falls back to a mock auth flow so you can still navigate the UI.

## Real-time order tracking (maps)
- Uses `flutter_map` + OpenStreetMap tiles.
- Firestore collection: `courierLocations/{orderId}` with fields `lat`, `lng`, `updatedAt`.
- For production, use your own tile server or a paid provider to meet OpenStreetMap usage policies.
- `flutter_map` 8.2.2 requires Dart 3.6+, so ensure your Flutter SDK includes Dart 3.6 or newer.
- Courier app includes a foreground demo button to stream location updates to Firestore (not a true background service).
- Courier app includes a background service button (Android only) that streams live GPS with `geolocator` and `flutter_background_service`.
- Background location requires Android permissions and user consent. The bootstrap script patches the courier app manifest.
 - Live GPS uses the currently active order; accept a task first so the correct order ID is stored.
 - For better survival after app kill, the courier app stores `activeOrderId` in SharedPreferences and auto-starts the service on boot.
 - Completing a delivery clears the active order and stops any live GPS sharing.
 - The courier app automatically stops GPS sharing and shows a delivery summary when the order status becomes `delivered`.

## Courier payouts + history
- Firestore collection: `courierDeliveries/{orderId}` with fields `courierId`, `basePayout`, `tip`, `overridePayout`, `rating`, `completedAt`.
- Courier app shows a Delivery Summary screen after completion and a History tab for past deliveries.
- The courier app auto-creates/updates the delivery summary on completion and aggregates weekly earnings from history.
- Payout is a simple estimate (base + distance + percentage of order total) using the GPS path when available.
- The summary screen lets the courier set a customer rating, add a tip, or override payout (admin) and saves to Firestore.
 - Restaurant/Admin app includes a Payouts tab to review and override courier payouts.
 - Admin access is based on Firebase Auth custom claims (`admin: true`) and enforced by `firestore.rules`.

## Bootstrap (creates the Flutter apps)
```bash
cd /Users/Ramesh/Workspace/food_delivery_flutter
bash scripts/bootstrap.sh
```

## Android minSdkVersion
Flutter defaults to minSdkVersion 21. To target Android 8.0 (API 26), edit each app’s
`android/app/build.gradle` and set `minSdkVersion 26`.

## Run
```bash
cd apps/customer_app
flutter run
```

Repeat for courier and restaurant/admin apps.

## Notes
- The apps currently use `MockDataRepository` so they run without Firebase.
- Switch to `FirebaseDataRepository` in each app once Firebase is configured.
