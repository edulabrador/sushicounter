# Sushi Score Flutter App

A minimalist Flutter application built with a dark theme to track session taps ("Sushi Score") and aggregate lifetime global taps.

## Features

- **Counter Screen**: A dark minimal UI with a giant centered counter and a customizable sushi graphic for hit detection. Tapping the sushi increments the current session; long-pressing decrements it. Includes optimistic UI updates.
- **History Screen**: A reverse-chronological list of all saved sessions. Includes duration tracking, timestamps, and tap counts per session. Allows for session deletion.
- **Stats Screen**: Key performance indicators (KPIs) showing lifetime total taps, total sessions, average taps per session, and the best session record. Includes a trend line chart (powered by `fl_chart`) to visualize taps over time, with filters for 'All', 'Last 7', and 'Last 30' sessions.
- **Settings Screen**: Options to reset the current ongoing session or securely wipe the global lifetime counter.
  - *Note on Global Reset*: Resetting the global lifetime counter requires strong confirmation (typing "RESET"). This action wipes `lifetimeTotalTaps` and `lifetimeTotalSessions` but intentionally **preserves your session history**.

## Architecture

This project is built using a feature-first clean architecture pattern to remain beginner-friendly yet scalable:

- **State Management**: `flutter_riverpod`
- **Local Storage**: `hive` and `hive_flutter` for fast, synchronous NoSQL persistence.
- **Charting**: `fl_chart`
- **Structure**:
  - `lib/core/` (Models, Theme, Storage repository)
  - `lib/features/` (Counter, History, Stats, Settings, Global views and providers)
  - `lib/shared/` (Common UI widgets like Bottom Nav)

## How to Run

1. Ensure you have the Flutter SDK installed on your machine.
2. Clone this repository:
   ```bash
   git clone https://github.com/your-username/sushi-score-flutter.git
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run on your desired device or emulator:
   ```bash
   flutter run
   ```

## How to Build Android Release

To generate an optimized APK for Android:

```bash
flutter build apk --release
```
The output file will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
