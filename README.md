# The Salon

Flutter application for customer bookings and salon administration. Firebase Authentication handles email/password login; Cloud Firestore stores users, services, appointments, and booking slot reservations. There is no Express server or PostgreSQL database.

## Run locally

Use Flutter 3.38.9 or a compatible release with Dart 3.10. Run `flutter pub get`, then `flutter run -d chrome`. The committed `lib/firebase_options.dart` contains Firebase client identifiers. These are not service account secrets. The Firebase project must enable Email/Password Authentication and Cloud Firestore. Local web sign-in also requires the local hostname in Firebase Authentication authorized domains.

Run `flutter analyze`, `flutter test`, and `flutter build web --release` before release.

## Access control and launch migration

Firestore rules are in `firestore.rules`; deploy them to Firebase project `salonapp-419d7` with `firebase deploy --only firestore:rules --project salonapp-419d7` after reviewing them against existing data. The client cannot enforce database authorization by itself. Public signup creates customer accounts only. Admin access is restricted to the verified existing owner Firebase Auth UID in both the UI and Firestore rules. Changing or adding owners requires an intentional code and rules update. Existing `users.role: admin` values alone do not grant access.

New bookings reserve a `bookingSlots` document in the same Firestore transaction as the appointment. **Before accepting bookings on an existing database**, backfill any non-cancelled future appointments so these slots are recognized. The 15 appointments observed on 25 October 2026 were all in the past, so the current database needs no backfill. For a database with future appointments, obtain a service account securely through the Firebase project owner; keep its JSON outside this repository. In `scripts/migration`, run `npm install`, set `GOOGLE_APPLICATION_CREDENTIALS` to its path, then run `node backfill-slots.mjs` to check for conflicts. Resolve reported conflicts before running `node backfill-slots.mjs --apply`. The script only creates missing reservations; it does not delete appointment data. Run the dry run again after applying and verify it reports zero missing slots. Never commit the service account file.

Current slot selection uses the application's existing fixed times. It does not model staff capacity, opening hours, or overlapping services longer than one slot. Those require business scheduling data before they can be enforced correctly.

## Vercel

The web frontend is a static Flutter build. Firebase remains the backend; Vercel does not host a database or API for this project. `vercel.json` configures the repository root, a Flutter 3.38.9 build, `build/web` output, and SPA route fallback. Import the existing GitHub repository into Vercel with Framework Preset **Other** and Root Directory **repository root**. The build script downloads a pinned Flutter SDK during the first build, so check the build time and logs on the selected Vercel plan. Connect the `main` branch for production deployments. No Vercel secret environment variables are required by this code; Firebase client configuration is already in `lib/firebase_options.dart`.

After the first preview deployment, add the exact preview and production hostnames to Firebase Authentication → Settings → Authorized domains. Verify sign-in, service loading, booking, cancellation, and admin access on preview before promoting production. Firestore rules and the slot backfill are separate Firebase operations and must be completed before accepting live bookings.
