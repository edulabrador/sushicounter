# Hive 2 compatibility fixtures

Binary boxes written by the original `hive` 2.2.3 package, exactly as earlier
Sushi Tracker releases stored them:

- `legacy_v01/`: sessions without `contributionEpoch`, totals without `epoch`,
  and the old `ongoingCount` / `ongoingStartedAt` keys.
- `v03/`: the 0.3.0 layout (epochs, `ongoing_session`, `keep_screen_on`).

Both contain sessions `s1` (12 taps, 40 min, 2026-03-14 20:00 UTC) and `s2`
(18 taps, 55 min, a week later), totals 30 taps / 2 sessions, and an active
session of 4 taps started 30 days after `s1`.

`test/hive_compat_test.dart` copies them to a temp directory and opens them
with the app's current storage code. Do not regenerate them with a newer
storage package: their value is that they come from the old one.

The generator is kept as `generate.dart.txt` (`.txt` so the app does not
analyze it). Run it from a separate package that depends on `hive: 2.2.3`.
