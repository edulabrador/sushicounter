# Changelog

All notable changes to this project will be documented in this file.

## [0.7.0] - 2026-10-27
### Added
- Group mode: count up to eight people at your table under your own counter. The table is kept with the unsaved session, saved with it, carried by backups, and shown in History and the details. Only your own pieces count towards your totals and stats.
- Edit a saved session's pieces and start time from its details; lifetime totals follow the change.
- Share a session as a 1080 px image with the nigiri, pieces, restaurant, duration, pace, price and table total, through the Android share sheet (served by a small read-only content provider, no permission). Elsewhere the summary is copied.
- Home screen widget with the current session count; its +1 button opens the app adding one sushi, like the launcher shortcut.
- Session goal in Settings, with progress on the counter and a vibration when reached.
- Calendar in Stats: recent weeks shaded by pieces per day, also readable as a list.
- Beating your record sets off a golden burst, a "New record!" badge and a strong vibration; each tap floats a small +1. Reduced motion keeps only the badge.
- Tablets and sideways phones: navigation rail, side-by-side counter, two-column Stats and a centred History.

### Changed
- Stats derive their figures once per change to history instead of on every counter tap, and the counter screen rebuilds once per tap instead of three times.
- The app draws edge to edge behind transparent system bars, keeping content clear of them and of display cutouts.
- The emulator test records frame timings for 100 taps and prints a marker per step; a stuck run stops after 15 minutes with the device log.
- Fixed a Kotlin type inference error that failed the Android build.
- Android keeps one Flutter engine for the whole process, so when the system recreates the activity (for example while it finishes processing an install) the app carries on instead of restarting; this was also what made the emulator test hang at random since 0.6.0.
- Privacy policy and Play notes cover table names, the widget's stored count and user-started sharing.
- App version is now `0.7.0+12`.

## [0.6.0] - 2026-10-25
### Added
- Restaurant per session: name it from the session details, with suggestions from earlier sessions. History shows it on each card, and Stats gains "By restaurant" with sessions, average pieces and cost per piece, plus a trophy for the cheapest per piece.
- Achievements: ten goals in Stats (sessions, pieces, a big session, a weekly streak, prices, restaurants), each with its progress. Ending a session that unlocks one says so.
- Optional light theme: Settings > Appearance offers Dark (default), Light or System. Both palettes are checked for WCAG AA contrast.
- Charts can switch to a list (trend newest first, weekly by "Week of"), which reads better with a screen reader.
- Golden tests for the counter, history, stats and settings screens in both themes, on a fixed clock.
- Play Store phone screenshots in English and Spanish (1080×1920) and a new feature graphic with the nigiri in each language, with the scripts that render them in `tool/store/`.

### Changed
- App icon drawn from the in-app nigiri on navy, with an Android adaptive icon (including a themed monochrome layer) and a navy native splash with the nigiri, so there is no white flash at launch.
- History and Stats views are split into smaller widget files.
- Time-dependent screens read the time through `package:clock`, so tests can fix it.
- App version is now `0.6.0+11`.

## [0.5.1] - 2026-10-24
### Changed
- Settings: a header with the nigiri and settings grouped into titled cards (Session, Preferences, Your data, About), with boxed icons like the Stats tiles.
- Session details: a header with the nigiri (starry for the record), the date and time range, and a grid of pieces, duration, pace and price.
- Startup: the nigiri and a short message while data loads; a new worried nigiri and a filled retry button when it cannot be opened.
- Dialogs, bottom sheets, switches, text fields and list rows follow the app theme; example text in fields is dimmed so it never looks typed.
- App version is now `0.5.1+10`.

## [0.5.0] - 2026-10-24
### Changed
- Visual redesign around the app's nigiri character. Its drawing now lives in shared code (`lib/shared/art/sushi_art.dart`) and gains two moods: sleepy for empty screens and starry for records. The happy face is pixel-identical to the original at every counter-button size, which a test checks.
- Colors follow the sushi: salmon accent (contrast-checked), salmon buttons and navigation, flatter cards.
- Counter: the nigiri gets starry eyes when the session beats your record, a progress bar shows how far the record is, and the three metrics sit in equal columns with icons.
- History: grouped by month with session and piece totals, card rows with a mini nigiri, a record badge and the price.
- Stats: two-column summary tiles, a curved salmon trend line with a soft fill, a dashed average with its own legend, the record marked by a starry nigiri, a new pieces-per-week bar chart, and records with the character.
- Empty History and Stats show the sleepy nigiri instead of plain text.
- App version is now `0.5.0+9`.

## [0.4.0] - 2026-10-24
### Added
- Export and import a backup file through the Android document picker (no storage permission). Web and desktop keep the clipboard fallback. Import now always asks before replacing data.
- Optional price per session, shown in the session details, with cost per piece in Stats. Amounts use the device region's currency.
- Records in Stats: best session, weekly streak, sessions and pieces this month.
- Launcher shortcut: long-press the app icon and choose "Add one sushi". Relaunching from Recents never adds again.
- Spanish Play Store listing text, and Spanish declared for iOS.

### Changed
- Storage moved from the unmaintained `hive` 2.2.3 to `hive_ce`. Tests open real files written by `hive` 2.2.3 in the 0.1 and 0.3 layouts to prove existing data still loads.
- The trend chart uses a date axis, so gaps between visits are visible.
- Settings are split into sections; settings storage has its own `Preferences` class.
- Colors come from theme tokens checked against WCAG AA contrast. The low-contrast grey in History was replaced.
- "Discard session" says so when an interrupted save had already reached history.
- CI runs Kotlin unit tests and an integration test of the real app on an Android emulator.
- App version is now `0.4.0+8`.

## [0.3.0] - 2026-10-24
### Added
- Spanish translation. The app follows the device language (English and Spanish).
- Haptic feedback when adding or removing a sushi.
- Optional "keep screen on during a session" setting, on by default (Android).
- Export and import of all history and totals as a text backup through the clipboard.
- Session details show pace per minute and can delete the session.
- "Discard session" when saving a finished session keeps failing, so the counter is never stuck.

### Fixed
- Restoring an old unsaved session without a start time no longer crashes the Counter screen.
- Counter and Stats show the same lifetime total (both include the active session).
- After a lifetime reset, Stats averages, best session and chart cover only the current lifetime, show when it started, and History marks older sessions.
- Undoing a delete restores exactly what the delete removed, even when the total had been clamped at 0.
- Several deletes in a row can all be undone from the latest snackbar.
- The elapsed timer no longer falls behind when frames are skipped, and starts correctly when the app opens in the background.
- History durations read as `1:02:05` instead of raw seconds.
- A single-session chart is centred.
- An unresolved save error stays visible until a later save succeeds.
- The reset confirmation ignores case and surrounding spaces and focuses the field.
- The privacy policy now states that Android backup may include app data.

### Changed
- Riverpod providers use `Notifier` instead of the legacy `StateNotifier` API, and the counter state is a phase enum with `copyWith`.
- CI reads the expected release version from `pubspec.yaml` and runs on pushes to `main` and on pull requests.
- App version is now `0.3.0+7`.

## [0.2.4] - 2026-09-23
### Added
- A visible Undo control and live elapsed timer on the Counter screen.

### Fixed
- Lifetime reset is blocked during an active session or while session persistence/completion is busy, preventing pre-reset taps from being counted in a new lifetime.
- Counter lifetime total includes active session taps without persisting them early or double-counting on completion.

### Changed
- Counter helper text and session metrics are clearer, and Stats filters explicitly refer to session counts.
- Flutter UI branding now consistently says Sushi Tracker.
- Counter actions are positioned for phone layouts, and widget coverage uses stable keys for repeated values.
- Session timer advances deterministically, restores from the saved start time, and recalculates after app resume.
- Android and desktop package metadata no longer uses the Flutter `com.example` placeholder where the release identity is configured.
- App version is now `0.2.4+6`.
- The Statistics screen now sorts sessions by completion time, uses integer tap labels, and remains useful for empty and single-session histories.
- Display names and web metadata now consistently use Sushi Tracker; application identifiers and signing remain unchanged.

## [v0.1.1]
### Fixed
- Global lifetime counter not refreshing in the UI: Hive returns the same cached object instance, so Riverpod's identity check never notified listeners. The repository now returns fresh immutable copies.
- Counter screen overflowing on short viewports (landscape/desktop); the central block now scales down gracefully.
- `getGlobalState` no longer crashes if the stored state is missing.

### Added
- Ongoing (unsaved) session persistence: taps survive an app restart.
- Real unit and widget tests covering the counter, session end flow, global stats notifications, history deletion and UI flows.

### Changed
- Bottom navigation uses `IndexedStack` so each tab keeps its state.
- Removed leftover shell scripts (`new.sh`, `new2.sh`, `new3.sh`) and dead `copyWith` code; fixed the README clone URL.

## [v0.1.0] - Initial Release
### Added
- Core Counter functionality (Tap to increment, Long-press to decrement).
- Session tracking with `startedAt`, `endedAt`, `count`, and `durationSeconds`.
- Global lifetime state tracking (`lifetimeTotalTaps`, `lifetimeTotalSessions`).
- Hive persistence integration.
- Bottom Navigation routing (Counter, History, Stats).
- History view showing reverse-chronological list of saved sessions.
- Stats view with KPI cards and line chart using `fl_chart`.
- Settings view featuring standard session reset and strong-confirmation "RESET" typed global wipe.
- Dark minimalist theme with centered custom Sushi design.
