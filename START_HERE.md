# Complete Feedback App source folder — logo and profile edition

This folder contains all app Dart source, the exact supplied symbol-only logo, asset registration, Firebase rules, dependencies, tests and setup tooling. The app shows the logo instead of the old text wordmark. Its internal Dart package remains `feedback_studio` for source/test compatibility; the visible application name is `Feedback`.

## Start a new copy on Windows

1. Extract the ZIP. Open the inner `feedback_app` folder in VS Code, where `pubspec.yaml` is located.
2. Flutter 3.35+ (Dart 3.9+) and Android Studio's Android SDK/emulator must be installed. Run `flutter doctor`.
3. Run the one-time setup from the project terminal:

```powershell
.\SETUP_WINDOWS.cmd
```

The setup generates official Android/iOS/web runners using your installed Flutter SDK, restores the supplied application source, installs dependencies, adds Android release Internet permission and creates launcher icons from the logo. Native runner folders are generated on your machine; this archive does not contain a compiled APK, a Gradle wrapper or hand-fabricated native runners. On macOS/Linux: `bash SETUP.sh`.

If PowerShell restricts `.cmd` execution in your environment, use:

```powershell
dart tool/setup.dart
```

4. Copy your existing filled `firebase.android.json` from the old project into this folder. Do not replace its real values with placeholders. If you need to configure a new project, follow the Firebase section below.
5. Deploy the **new rules**. They include private `users/{uid}` profiles while preserving review/admin permissions:

```powershell
$config = Get-Content .\firebase.android.json -Raw | ConvertFrom-Json
firebase.cmd deploy --only firestore --project $config.FIREBASE_PROJECT_ID
```

6. Verify and launch:

```powershell
dart format lib test tool
flutter analyze
flutter test
flutter devices
flutter run -d emulator-5554 --dart-define-from-file=firebase.android.json
```

Use your actual Android device ID instead of `emulator-5554`.

For a demo before Firebase configuration:

```powershell
flutter run -d emulator-5554 --dart-define=DEMO_MODE=true
```

Demo security actions are intentionally unavailable because they require a real account. Demo profile changes are in memory and reset on app restart.

## Upgrade the existing project instead

Back up the old project. Copy this folder's `lib/`, `test/`, `assets/`, `pubspec.yaml`, `flutter_launcher_icons.yaml` and `firestore.rules` into it. Add new files and replace matching files. **Preserve your existing `lib/firebase_options.dart`, filled Firebase JSON files, `android/`, `ios/`, `web/`, native Firebase files and `firebase.json`.** Do not delete the entire old lib folder.

Run:

```powershell
flutter pub get
dart run flutter_launcher_icons
$config = Get-Content .\firebase.android.json -Raw | ConvertFrom-Json
firebase.cmd deploy --only firestore --project $config.FIREBASE_PROJECT_ID
dart format lib test
flutter analyze
flutter test
```

The new full-folder setup script can also be used after copying `tool/setup.dart`; it adjusts platform labels and Android Internet permission. Do not overwrite custom native settings without a backup.

## Firebase configuration for a new folder

The startup uses JSON dart-define values, as in the previous version. Copy `firebase.android.example.json` to `firebase.android.json` and replace every placeholder with your real Android values. Enable Email/Password authentication and create the default Firestore database.

If registration of native platform apps is needed:

```powershell
firebase.cmd login
dart pub global run flutterfire_cli:flutterfire configure
```

Select your existing Firebase project and Android. When asked to reuse a bare `firebase.json` configuration, choose No if it lacks platform app settings. Copy the generated Android apiKey/appId/messagingSenderId/projectId values into your JSON. Generated `firebase_options.dart` is a reference; the app continues to initialize from JSON.

Use matching platform App IDs for web/iOS. Do not use an Android App ID for web. No credentials are included here. Do not distribute service-account private keys.

## Profile settings included

Account → Profile settings:
- Display name, bio, contact phone, city/location and website.
- Five avatar colours and an optional HTTPS profile-photo URL with explicit preview and graceful fallback.
- Private profile persistence in Firestore `users/{uid}`.
- Email verification and refresh of verification status.
- Current-password reauthentication for password changes and email-change verification.
- Password reset email.
- Form validation, save busy states and confirmation before abandoning unsaved changes.

Photo support is by HTTPS URL; local gallery upload is not included. Phone is a contact field, not phone authentication. Profile permissions cannot change the trusted administrator role. Email only changes after completing Firebase's new-address verification flow. Passwords are never stored in Firestore.

Name and private profile data belong to separate Firebase services; saving them is not a cross-service atomic transaction. If one save fails after the other succeeds, retry and review the current values. Existing review author names remain historical, while new reviews use the updated name.

## Responsive and performance work

- Mobile bottom navigation and tablet/desktop navigation rail.
- Responsive metric grid; profile fields use one column on phones and two when space permits.
- Wrapping filter/status/rating controls, constrained readable content widths and keyboard-scrollable forms.
- Feedback inbox renders 20 cards initially, with Show more increments. Search/analytics still use all accessible feedback loaded by the existing listener; this is UI pagination, not Firestore query pagination.
- Bounded image decode sizes and no live photo-URL request on every keystroke.
- Stream/controller cleanup, duplicate submission protection and draft safeguards.

For very large datasets, server-side pagination and aggregates are still required; this app does not claim benchmarked production-scale performance.

## Administrator access

The earlier trusted `admin: true` claim remains required. Existing administrators keep their permissions. To assign a new admin, configure trusted Application Default Credentials outside the app and use:

```powershell
npm.cmd install --no-save firebase-admin
node tool/grant_admin.mjs USER_UID
```

Then sign out/sign in. No role switch exists in real Firebase mode.

## Validation status and next checks

Dart grammar parsing, local import resolution, YAML/JSON parsing, asset existence and ZIP integrity were checked. Flutter SDK, Android runtime and your live Firebase account are unavailable here. Flutter analyze/test, launcher icon generation, native setup, APK builds and live Firebase security flows must still be run on your machine. No zero-defect or device-tested claim is made.

Tests cover feedback analytics/filtering, member/admin data separation, small-screen submission/admin flows, profile constraints/account separation, and small-screen profile editing. Check real account registration, profile save/restart, denied cross-user reads, password/email verification and admin replies before submission.

## Build after verification

```powershell
flutter build apk --release --dart-define-from-file=firebase.android.json
```

APK: `build\app\outputs\flutter-apk\app-release.apk`.

If an old launcher icon remains, uninstall the old local test app and install the new APK; note that uninstalling removes its local app data.
