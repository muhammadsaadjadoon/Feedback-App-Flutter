# Layout and test corrections

Corrects the reported workspace badge overflow, administrator response heading overflow, ListTile Material assertion and profile-test tap hidden beneath bottom navigation. Removes the unnecessary firebase_core import in helpers.dart.

For an existing project, replace only these files from this folder:
- lib/helpers.dart
- lib/screens.dart
- lib/design.dart
- lib/review_screens.dart
- test/profile_flow_test.dart
- test/app_flow_test.dart

Keep your Firebase configuration and existing native platform folders. Then run:

```powershell
dart format lib test
flutter analyze
flutter test --reporter expanded
```

Source parsing and archive validation were performed here. Flutter runtime tests were not run because the SDK is unavailable; confirm the commands above locally before submission.
