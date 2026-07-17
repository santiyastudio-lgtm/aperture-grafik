# Aperture Grafik

Offline-first Android MVP for café shift schedules, daily revenue and pay tracking.

## Features

- Onboarding in Russian or English.
- 3/3, 2/2, 5/2 and weekday schedules; shifts may end after midnight.
- Local SQLite persistence, manual extra shifts, edit/delete history and pay calculation.
- Four original Material 3 themes, RUB-only formatting, local revenue recommendations, charts and end-of-shift reminders.
- Revenue recommendations stay on-device: recent completed shifts and weekday patterns provide a practical reference range and a higher-than-usual warning. No order data leaves the phone.
- JSON backup export/import. Backups are intentionally **not encrypted**; do not share them publicly.

## Architecture

The app is organized as `presentation → application → domain ← data`:

- `domain`: pure models plus schedule and finance rules.
- `application`: Riverpod state controller and use-case coordination.
- `data`: SQLite repository; it can later be replaced with a Firebase adapter without changing the domain/UI.
- `presentation`: Material 3 screens and widgets.

## Local setup

Flutter 3.44.4 / Dart 3.12.2 is installed for this workspace in `F:\Development\flutter`.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

If `flutter.bat` is blocked by the local Windows launcher, invoke Flutter through its verified tool snapshot:

```powershell
& 'F:\Development\flutter\bin\cache\dart-sdk\bin\dart.exe' --packages='F:\Development\flutter\packages\flutter_tools\.dart_tool\package_config.json' 'F:\Development\flutter\bin\cache\flutter_tools.snapshot' analyze
```

An Android SDK and JDK 17 are additionally required for APK builds. The project has no Firebase configuration or production secrets.

## Backup format

The exported JSON has `schemaVersion: 1`. Import validates the top-level schema before replacing the single SQLite state transaction. Invalid or incompatible files leave existing data untouched.
