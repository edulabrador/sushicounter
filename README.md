# 🍣 Sushi Score

A tiny, dark-themed Flutter app for one purpose: tapping a button and watching the number go up.

I built this as a no-frills tally counter — the kind of thing you reach for when you just need to count *something* (reps, drinks, snacks, whatever "sushi" means to you that day) without opening an app packed with ads and permissions it doesn't need. Tap to add, long-press to undo a mistake, and end the session when you're done. Everything is saved locally on your device — there's no account, no backend, no tracking.

## What it does

**Counter** — the home screen. A big number, a sushi graphic you tap to increment, and a long-press to decrement if you miscount. Your current session count and your all-time global count sit right below it, so you always know where you stand.

**History** — every past session, newest first, with how many taps it had, how long it lasted, and when it happened. Made a mistake or just want to clean up? You can delete individual sessions.

**Stats** — the bigger picture: total taps ever, total sessions, your average per session, and your best session on record, plus a trend chart (via `fl_chart`) so you can see whether you're trending up or down over your last 7, last 30, or all sessions.

**Settings** — reset your current session if you want a fresh start, or wipe your global lifetime stats entirely. That second one is intentionally hard to trigger by accident: you have to type "RESET" to confirm. Even then, it only clears the lifetime totals — your session history stays intact, so you never lose the log of what actually happened.

## Under the hood

Nothing fancy, just a clean, feature-first structure so it's easy to find your way around:

- **State management** — [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod)
- **Local storage** — [`hive`](https://pub.dev/packages/hive) / `hive_flutter`, so everything persists instantly with no server round-trip
- **Charts** — [`fl_chart`](https://pub.dev/packages/fl_chart) for the trend line on the Stats screen

```
lib/
├── core/       # models, theme, storage repository
├── features/   # counter, history, stats, settings — each with its own views/providers
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

## Building an Android release

```bash
flutter build apk --release
```

The APK shows up at `build/app/outputs/flutter-apk/app-release.apk`.

## License

All rights reserved — see [LICENSE](LICENSE). You're welcome to read the code, but reuse or redistribution requires my permission.
