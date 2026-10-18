# MedVault

MedVault is an offline-first Flutter learning library.

## Implemented features

- Browse, search, and filter notes.
- Read notes with heading navigation and configurable reading preferences.
- Edit note titles, tags, and taxonomy placement.
- Bookmark notes and track recent reading history.
- Persist appearance and reading-size preferences.
- Import and export version-1 JSON curriculum packs.
- Validate curriculum packs using the shared package and toolkit.

Medical learning content is supplied by the user; this project focuses on the software, storage, and workflows.

## Development

Validated with Flutter 3.24.5 and Dart 3.5.4.

Run `flutter pub get`, `flutter analyze`, and the test suite from this directory.

## Android release

Build a signed release APK with `flutter build apk --release`. The output is `build/app/outputs/flutter-apk/app-release.apk`. Verify the APK signature before distribution. Keep `android/key.properties` and the release keystore private and out of version control.

Application ID: `com.example.medvault_app`
Launcher label: `MedVault`

## Curriculum-pack backup scope

Exports include taxonomy, notes, citations, and supported relationships. They do not include device-local bookmarks, recent history, appearance, reading-size preferences, or other local activity state. Imports respect existing-record conflict rules.

## Repository layout

- `lib/` — Flutter application.
- `test/` — application tests.
- `../medvault-shared/` — curriculum-pack models and validation.
- `../medvault-toolkit/` — curriculum-pack validation CLI.
- `../medvault-infrastructure/vendor/isar_flutter_libs/` — vendored Isar plugin.
