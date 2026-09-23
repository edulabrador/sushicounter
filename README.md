# 🍣 Sushi Tracker

A tiny, dark-themed, offline-first Flutter app for counting sushi pieces during a buffet.

Tap to add a piece, use Undo or long-press to correct a count, and end the session when you're done. A live timer tracks session duration. History and lifetime statistics stay on your device. The app has no account, backend, ads, or analytics.

## What it does

**Counter** - the home screen. Tap the sushi graphic to count, use visible Undo or long-press to decrement, and end the session to save it. It shows this session, the lifetime total including the active session, and a live elapsed timer.

**History** - every past session, newest first, with its count, duration, and completion time. Individual sessions can be deleted and restored with Undo.

**Stats** - lifetime taps and sessions, average and best session counts, plus a trend chart for the latest 7 sessions, 30 sessions, or all sessions.

**Settings** - reset the current session or lifetime totals. Lifetime reset is unavailable while a session is active and requires typing "RESET" to confirm. It clears lifetime totals while preserving session history.

### Updating from an older version

Existing history is preserved. When upgrading, Sushi Tracker only links legacy history to lifetime totals if the old totals exactly match the saved sessions; otherwise it leaves the totals unchanged so deleting old history cannot accidentally change a later reset total.

## Under the hood

Nothing fancy, just a clean, feature-first structure so it's easy to find your way around:

- **State management**, [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
- **Local storage**, [`hive`](https://pub.dev/packages/hive) / `hive_flutter`, so everything persists instantly with no server round-trip
- **Charts**, [`fl_chart`](https://pub.dev/packages/fl_chart) for the trend line on the Stats screen

```
lib/
├── core/       # models, theme, storage repository
├── features/   # counter, history, stats, and settings, each with its own views/providers
└── shared/     # widgets used across features (bottom nav, etc.)
```

## Running it locally

You'll need the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

```bash
git clone https://github.com/edulabrador/sushicounter.git
cd sushicounter
flutter pub get
flutter run
```

## Building for Android

```bash
flutter build apk --debug
```

The local debug APK appears at `build/app/outputs/flutter-apk/app-debug.apk`.
For a signed Play Store app bundle, see [PUBLISHING.md](PUBLISHING.md).

## License

All rights reserved. See [LICENSE](LICENSE). You're welcome to read the code, but reuse or redistribution requires my permission.
