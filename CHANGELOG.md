# Changelog

All notable changes to this project will be documented in this file.

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
