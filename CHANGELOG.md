# Changelog

All notable changes to this project will be documented in this file.

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
