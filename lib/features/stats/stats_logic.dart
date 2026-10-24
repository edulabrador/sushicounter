import 'dart:math' as math;

import 'package:sushiscore/core/models/session.dart';

enum StatsFilter { last7, last30, all }

extension StatsFilterLimit on StatsFilter {
  int? get limit => switch (this) {
    StatsFilter.last7 => 7,
    StatsFilter.last30 => 30,
    StatsFilter.all => null,
  };
}

class StatsSummary {
  const StatsSummary(this.sessions, this.totalTaps, this.bestSession);

  final List<Session> sessions;
  final int totalTaps;
  final int bestSession;

  double get averageTaps => sessions.isEmpty ? 0 : totalTaps / sessions.length;

  /// Average price of one piece over the sessions that have a price, in
  /// cents, or null when none has one.
  double? get costPerPieceCents {
    var cents = 0;
    var pieces = 0;
    for (final session in sessions) {
      final price = session.priceCents;
      if (price == null) continue;
      cents += price;
      pieces += session.count;
    }
    return pieces == 0 ? null : cents / pieces;
  }
}

/// Only sessions of [epoch]'s lifetime, oldest first.
List<Session> lifetimeSessions(List<Session> source, int? epoch) => [
  for (final session in source)
    if (epoch == null || session.isInLifetime(epoch)) session,
]..sort((a, b) => a.endedAt.compareTo(b.endedAt));

/// Sort by actual completion time so the chart remains chronological even if
/// storage returns sessions in a different order. With [epoch], only sessions
/// of that lifetime count, so averages agree with the lifetime totals.
StatsSummary summarizeSessions(
  List<Session> source,
  StatsFilter filter, {
  int? epoch,
}) {
  final sessions = lifetimeSessions(source, epoch);
  final limit = filter.limit;
  final visible = limit != null && sessions.length > limit
      ? sessions.sublist(sessions.length - limit)
      : sessions;
  final total = visible.fold<int>(0, (sum, session) => sum + session.count);
  final best = visible.fold<int>(
    0,
    (current, session) => math.max(current, session.count),
  );
  return StatsSummary(visible, total, best);
}

class StatsRecords {
  const StatsRecords({
    required this.bestSession,
    required this.weeklyStreak,
    required this.sessionsThisMonth,
    required this.piecesThisMonth,
  });

  final int bestSession;

  /// Consecutive calendar weeks (Monday to Sunday) with at least one session,
  /// ending this week, or last week while this week has none yet.
  final int weeklyStreak;
  final int sessionsThisMonth;
  final int piecesThisMonth;
}

/// Index of the local Monday-to-Sunday week containing [time].
int weekIndex(DateTime time) {
  final local = time.toLocal();
  // Calendar dates in UTC, so daylight-saving changes cannot shift the count.
  final day = DateTime.utc(local.year, local.month, local.day);
  final firstMonday = DateTime.utc(1970, 1, 5);
  return (day.difference(firstMonday).inDays / 7).floor();
}

StatsRecords computeRecords(List<Session> sessions, DateTime now) {
  final weeks = {for (final session in sessions) weekIndex(session.endedAt)};
  var week = weekIndex(now);
  if (!weeks.contains(week)) week--;
  var streak = 0;
  while (weeks.contains(week)) {
    streak++;
    week--;
  }
  final localNow = now.toLocal();
  var monthSessions = 0;
  var monthPieces = 0;
  var best = 0;
  for (final session in sessions) {
    best = math.max(best, session.count);
    final ended = session.endedAt.toLocal();
    if (ended.year == localNow.year && ended.month == localNow.month) {
      monthSessions++;
      monthPieces += session.count;
    }
  }
  return StatsRecords(
    bestSession: best,
    weeklyStreak: streak,
    sessionsThisMonth: monthSessions,
    piecesThisMonth: monthPieces,
  );
}

/// Chart x position of [time]: days since [origin], so gaps between visits
/// show as gaps on the chart.
double chartDay(DateTime time, DateTime origin) =>
    time.difference(origin).inMinutes / Duration.minutesPerDay;
