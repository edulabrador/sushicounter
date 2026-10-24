import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';

Session at(DateTime endedAt, int count, {int? price}) => Session(
  id: endedAt.toIso8601String(),
  startedAt: endedAt.subtract(const Duration(minutes: 30)),
  endedAt: endedAt,
  count: count,
  durationSeconds: 1800,
  priceCents: price,
);

void main() {
  // Wednesday 2026-10-21, 20:00 local.
  final now = DateTime(2026, 10, 21, 20);

  group('weekly streak', () {
    test('is zero without sessions', () {
      expect(computeRecords([], now).weeklyStreak, 0);
    });

    test('counts consecutive weeks ending this week', () {
      final sessions = [
        at(DateTime(2026, 10, 19, 13), 10), // this week (Mon)
        at(DateTime(2026, 10, 18, 21), 10), // last week (Sun)
        at(DateTime(2026, 10, 6, 21), 10), // two weeks ago
        at(DateTime(2026, 9, 20, 21), 10), // after a gap
      ];
      expect(computeRecords(sessions, now).weeklyStreak, 3);
    });

    test('stays alive while this week has no session yet', () {
      final sessions = [
        at(DateTime(2026, 10, 14, 21), 10),
        at(DateTime(2026, 10, 7, 21), 10),
      ];
      expect(computeRecords(sessions, now).weeklyStreak, 2);
    });

    test('is broken by a full week without sessions', () {
      expect(
        computeRecords([at(DateTime(2026, 10, 7, 21), 10)], now).weeklyStreak,
        0,
      );
    });

    test('weeks run Monday to Sunday', () {
      expect(
        weekIndex(DateTime(2026, 10, 18, 23, 59)),
        weekIndex(DateTime(2026, 10, 12)),
      );
      expect(
        weekIndex(DateTime(2026, 10, 19)),
        weekIndex(DateTime(2026, 10, 18)) + 1,
      );
    });

    test('daylight-saving changes do not split or merge weeks', () {
      // Europe moves clocks on the last Sunday of March and October.
      expect(
        weekIndex(DateTime(2026, 3, 30)) - weekIndex(DateTime(2026, 3, 23)),
        1,
      );
      expect(
        weekIndex(DateTime(2026, 10, 26)) - weekIndex(DateTime(2026, 10, 19)),
        1,
      );
    });
  });

  test('month totals only count the current calendar month', () {
    final records = computeRecords([
      at(DateTime(2026, 10, 1, 0, 30), 12),
      at(DateTime(2026, 10, 20, 21), 8),
      at(DateTime(2026, 9, 30, 23, 30), 40),
      at(DateTime(2025, 10, 15, 21), 5),
    ], now);
    expect(records.sessionsThisMonth, 2);
    expect(records.piecesThisMonth, 20);
    expect(records.bestSession, 40);
  });

  test('cost per piece ignores sessions without a price', () {
    final summary = summarizeSessions([
      at(DateTime(2026, 10, 1), 10, price: 2500),
      at(DateTime(2026, 10, 2), 15, price: 2500),
      at(DateTime(2026, 10, 3), 100),
    ], StatsFilter.all);
    expect(summary.costPerPieceCents, 200);
    expect(
      summarizeSessions([at(now, 3)], StatsFilter.all).costPerPieceCents,
      isNull,
    );
  });

  test('chart x is real days, so gaps between visits stay visible', () {
    final origin = DateTime(2026, 10, 1, 20);
    expect(chartDay(origin, origin), 0);
    expect(chartDay(DateTime(2026, 10, 31, 20), origin), 30);
    expect(chartDay(DateTime(2026, 10, 2, 8), origin), 0.5);
  });

  test('lifetime filter keeps only the current lifetime, oldest first', () {
    final old = at(DateTime(2026, 1, 1), 1);
    final newer = Session(
      id: 'n',
      startedAt: DateTime(2026, 2, 1),
      endedAt: DateTime(2026, 2, 1),
      count: 2,
      durationSeconds: 0,
      contributionEpoch: 1,
    );
    final latest = newer.copyWith();
    expect(lifetimeSessions([latest, old], 1).map((s) => s.count), [2]);
    expect(lifetimeSessions([newer, old], null).first, old);
  });
}
