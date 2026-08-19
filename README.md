# Narayana Marine

Flutter Web website and single-administrator content editor for Narayana Marine, Phuket.

## Local development

Install Flutter dependencies, then run the web application:

```powershell
flutter pub get
flutter run -d chrome
```

`/` is the public website and `/admin` is the protected administrator route.
The admin route shows the same website layout with CMS controls inside its
sections; it never exposes those controls on `/`.

## Important security configuration

- The sole authorized Firebase UID is enforced in `firestore.rules` and `storage.rules`.
- Firebase Authentication must contain the Email/Password user
  `Narayamarine@gmail.com` with UID `mBqYpkC87AgLsfXOVn65JnjPG6A3`.
  The application does not create this user and never contains its password.
- Firebase Authentication must have end-user account creation and deletion disabled in Firebase Console before release.
- The public application does not contain an account-creation flow.
- Firestore and Storage Rules must be deployed before publishing any content.
- Set `RECAPTCHA_V3_SITE_KEY` as a build-time value only after App Check has been registered in Firebase Console. Without it, the application runs normally but does not activate App Check.

## Initial catalog

The seed tool creates only missing, unpublished documents and never contains credentials.

```powershell
cd tool
npm install
npm run seed:dry-run
npm run seed:apply
```

The owner must authenticate locally with Application Default Credentials before applying seed data. Do not commit credentials.

## Initial "Why us" migration

The 16 existing service chips are Firestore data. Run the idempotent seed once
before deploying the CMS build so this public section is never empty:

```powershell
cd tool
npm run seed:services:dry-run
npm run seed:services:apply
cd ..
```

The script only creates missing stable IDs and never overwrites edited services.

## CMS Storage lifecycle

CMS uploads media directly to Firebase Storage URLs; it does not download or
persist copies on the visitor device. For a replacement it uploads the new
object, updates Firestore, then deletes the old `storagePath`. If the Firestore
write fails, the newly uploaded object is removed. A small
`pendingStorageDeletes` list allows the next authorized CMS session to safely
retry a Storage deletion interrupted by a network failure.

## Google Maps reviews

The public site links directly to Narayana Marine's supplied Google Maps card.
It does not call Places API from the browser and does not display an invented
rating or review. The Flutter `GoogleReviewsData` model and
`GoogleReviewsService` interface are ready for a trusted backend response.

Before a reviews backend is implemented, the Owner must:

1. Attach billing to the Google Cloud project that will own the integration.
2. Enable **Places API (New)**.
3. Use a server-restricted API key (API restriction: Places API (New),
   application restriction: the backend's service identity/IP only).
4. Use a Text Search (New) request from that trusted environment to verify the
   Narayana Marine Place ID against the supplied Google Maps card.
5. Add a Cloud Function or another authenticated server endpoint that requests
   only the required Place Details fields and returns a minimal read-only
   review payload to the website.

Never put that web-service API key in Dart, assets, Firestore, Git, or a web
build argument. Review attribution requirements must be checked against the
current Google Maps Platform terms when that backend is enabled.

## Validation

```powershell
flutter analyze
flutter test

firebase emulators:start --project narayana-marine-rules-test --only auth,firestore,storage
cd tool
npm run test:rules
```

## Later deployment commands

Do not run these commands until reviewed and approved by the Project Owner:

```powershell
flutter build web --release --dart-define=RECAPTCHA_V3_SITE_KEY=YOUR_RECAPTCHA_V3_SITE_KEY
firebase deploy --project narayana-marine --only firestore:rules,firestore:indexes,storage
firebase deploy --project narayana-marine --only hosting
```
