# The Salon

Flutter application for customer bookings and salon administration. Firebase Authentication handles email/password login; Cloud Firestore stores users, services, appointments, and booking slot reservations. There is no Express server or PostgreSQL database.

## Run locally

Use Flutter 3.38.9 or a compatible release with Dart 3.10. Run `flutter pub get`, then `flutter run -d chrome`. The committed `lib/firebase_options.dart` contains Firebase client identifiers. These are not service account secrets. The Firebase project must enable Email/Password Authentication and Cloud Firestore. Local web sign-in also requires the local hostname in Firebase Authentication authorized domains.

Run `flutter analyze`, `flutter test`, and `flutter build web --release` before release.

## Access control and launch migration

Firestore rules are in `firestore.rules`; deploy them to Firebase project `salonapp-419d7` with `firebase deploy --only firestore:rules --project salonapp-419d7` after reviewing them against existing data. The client cannot enforce database authorization by itself. A customer account becomes active immediately. Selecting **Salon owner** during signup creates a pending request; an existing administrator must approve it in **Manage Admins** before it receives management access. Administrators can also create a separate account directly from that screen, in which case the new administrator receives a password-setup email. A public role selection or a `users.role` value alone does not grant access.

New bookings reserve a `bookingSlots` document in the same Firestore transaction as the appointment. **Before accepting bookings on an existing database**, backfill any non-cancelled future appointments so these slots are recognized. The 15 appointments observed on 25 October 2026 were all in the past, so the current database needs no backfill. For a database with future appointments, obtain a service account securely through the Firebase project owner; keep its JSON outside this repository. In `scripts/migration`, run `npm install`, set `GOOGLE_APPLICATION_CREDENTIALS` to its path, then run `node backfill-slots.mjs` to check for conflicts. Resolve reported conflicts before running `node backfill-slots.mjs --apply`. The script only creates missing reservations; it does not delete appointment data. Run the dry run again after applying and verify it reports zero missing slots. Never commit the service account file.

Current slot selection uses the application's existing fixed times. It does not model staff capacity, opening hours, or overlapping services longer than one slot. Those require business scheduling data before they can be enforced correctly.

## Booking alerts and priority requests

Customers can request priority handling while booking and describe their need. The booking keeps the normal service price until an administrator quotes an extra fee. The customer can accept the displayed total or decline the fee and keep the standard booking pending. An administrator can confirm the appointment only after the customer has answered the quote. The app does not collect payment; the salon handles payment separately. New fields on appointment documents are optional when reading existing bookings.

The notification bell shows live appointment updates inside the signed-in app. Administrators see bookings needing review; customers see priority quotes and appointment outcomes. It uses existing Firestore access rules and works without email infrastructure. It is an in-app notification, not a background push notification.

Email delivery is implemented as Firebase Cloud Functions in `functions/`. A new booking sends a separate email to every current administrator account, including the primary recovery owner. Confirmation sends the customer an email; a priority quote also emails the customer to request a decision. Addresses are read from Firebase Authentication at send time so an administrator's current email is used. Delivery records in `mailDelivery` and provider idempotency keys reduce duplicate emails if a trigger is retried. Client access to delivery records is denied by the Firestore rules.

Email is **not active** until the following Firebase setup is complete:

1. Upgrade Firebase project `salonapp-419d7` to the Blaze plan. Firebase requires Blaze to deploy Cloud Functions. Set a billing budget alert appropriate for the salon.
2. Create a Resend account, verify a sender domain, and choose a sender address on that domain. A sender domain is required for reliable production mail.
3. In `functions/`, run `npm ci`. From the repository root run `firebase functions:secrets:set RESEND_API_KEY --project salonapp-419d7` and enter the Resend API key at the prompt. Never put this key in Vercel or client code.
4. Copy `functions/.env.example` to the ignored `functions/.env.salonapp-419d7` and replace the placeholder `MAIL_FROM` with the verified sender address.
5. Deploy the rules first: `firebase deploy --only firestore:rules --project salonapp-419d7`. Then deploy the triggers: `firebase deploy --only functions --project salonapp-419d7`.
6. Book a test appointment using a customer account, verify the admin inboxes receive the alert, quote and accept any priority fee, confirm it, and verify the customer receives email. Inspect Firebase Functions logs for failures.

The Resend key and billing are external requirements. Without them, bookings, priority quotes, and in-app updates still work after the revised rules and web build are published; email will not be sent.

For local tests, run `flutter test`, `npm test --prefix functions`, and `firebase emulators:exec --only firestore --project salon-priority-rules-test "npm run test:rules --prefix functions"`. The last command downloads the Firestore emulator on first use and never writes to the production database.

## Create or transfer administrator access

For ordinary setup, sign in as an existing administrator, open **Manage Admins**, and select **Add admin**. Enter the person's name and email; the application creates an independent Firebase account and sends the recipient a link to choose a password. The primary owner UID remains the recovery account. The `scripts/migration/transfer-owner.mjs` utility is retained only as an emergency fallback for changing that primary recovery account's email. It requires a temporary service-account key and should not be used for routine administrator creation.

## Vercel

The web frontend is a static Flutter build. Firebase remains the backend; Vercel does not host a database or API for this project. `vercel.json` configures the repository root, a Flutter 3.38.9 build, `build/web` output, and SPA route fallback. Import the existing GitHub repository into Vercel with Framework Preset **Other** and Root Directory **repository root**. The build script downloads a pinned Flutter SDK during the first build, so check the build time and logs on the selected Vercel plan. Connect the `main` branch for production deployments. No Vercel secret environment variables are required by this code; Firebase client configuration is already in `lib/firebase_options.dart`.

Production is available at `https://salon-app-gray.vercel.app/`. This hostname is listed in Firebase Authentication → Settings → Authorized domains, and the revised Firestore rules are published. Sign-in, service loading, booking, cancellation, and admin changes still require an account-based smoke test; deployment readiness alone does not verify these flows. Firestore rules and any future slot backfill are separate Firebase operations.
