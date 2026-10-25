import 'dart:math' as math;

import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';

enum AchievementId {
  firstSession,
  tenSessions,
  fiftySessions,
  bigAppetite,
  sushiMaster,
  hundredPieces,
  thousandPieces,
  regular,
  priceWatcher,
  explorer,
}

class Achievement {
  const Achievement(this.id, this.progress, this.target);

  final AchievementId id;
  final int progress;
  final int target;

  bool get unlocked => progress >= target;

  /// Progress capped at the target, for "3/10" style labels.
  int get shownProgress => math.min(progress, target);
}

/// Longest run of consecutive calendar weeks with at least one session.
int longestWeeklyStreak(List<Session> sessions) {
  final weeks = {for (final s in sessions) weekIndex(s.endedAt)}.toList()
    ..sort();
  var longest = 0;
  var current = 0;
  int? previous;
  for (final week in weeks) {
    current = previous != null && week == previous + 1 ? current + 1 : 1;
    longest = math.max(longest, current);
    previous = week;
  }
  return longest;
}

/// Achievements over the whole history: they are earned once and are not
/// reset with the lifetime totals (deleting sessions can take them back).
List<Achievement> computeAchievements(List<Session> sessions) {
  final pieces = sessions.fold(0, (sum, s) => sum + s.count);
  final best = sessions.fold(0, (m, s) => math.max(m, s.count));
  final priced = sessions.where((s) => s.priceCents != null).length;
  final restaurants = knownRestaurants(sessions).length;
  return [
    Achievement(AchievementId.firstSession, sessions.length, 1),
    Achievement(AchievementId.tenSessions, sessions.length, 10),
    Achievement(AchievementId.fiftySessions, sessions.length, 50),
    Achievement(AchievementId.bigAppetite, best, 30),
    Achievement(AchievementId.sushiMaster, best, 50),
    Achievement(AchievementId.hundredPieces, pieces, 100),
    Achievement(AchievementId.thousandPieces, pieces, 1000),
    Achievement(AchievementId.regular, longestWeeklyStreak(sessions), 4),
    Achievement(AchievementId.priceWatcher, priced, 5),
    Achievement(AchievementId.explorer, restaurants, 3),
  ];
}

/// Achievements unlocked by going from [before] to [after].
List<AchievementId> newlyUnlocked(
  List<Achievement> before,
  List<Achievement> after,
) {
  final had = {
    for (final a in before)
      if (a.unlocked) a.id,
  };
  return [
    for (final a in after)
      if (a.unlocked && !had.contains(a.id)) a.id,
  ];
}
