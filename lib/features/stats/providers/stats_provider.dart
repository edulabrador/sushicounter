import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/models/session.dart';

import '../../global/providers/global_provider.dart';
import '../../history/providers/session_provider.dart';
import '../achievements.dart';
import '../stats_logic.dart';

/// The range the Stats screen summarizes.
class StatsFilterNotifier extends Notifier<StatsFilter> {
  @override
  StatsFilter build() => StatsFilter.all;

  void select(StatsFilter filter) => state = filter;
}

final statsFilterProvider = NotifierProvider<StatsFilterNotifier, StatsFilter>(
  StatsFilterNotifier.new,
);

/// Everything the Stats screen derives from saved sessions.
class StatsData {
  const StatsData({
    required this.lifetime,
    required this.summary,
    required this.records,
    required this.weekly,
    required this.restaurants,
    required this.achievements,
    required this.days,
  });

  final List<Session> lifetime;
  final StatsSummary summary;
  final StatsRecords records;
  final List<({DateTime weekStart, int pieces})> weekly;
  final List<RestaurantStats> restaurants;
  final List<Achievement> achievements;
  final Map<DateTime, int> days;
}

/// Computed once per change to history, the lifetime or the range, not on
/// every counter tap: the Stats tab stays mounted behind the counter.
final statsDataProvider = Provider<StatsData>((ref) {
  final epoch = ref.watch(globalStateProvider.select((g) => g.epoch));
  final sessions = ref.watch(sessionListProvider);
  final filter = ref.watch(statsFilterProvider);
  final now = clock.now();
  final lifetime = lifetimeSessions(sessions, epoch);
  return StatsData(
    lifetime: lifetime,
    summary: summarizeSessions(sessions, filter, epoch: epoch),
    records: computeRecords(lifetime, now),
    weekly: weeklyPieces(lifetime, now),
    restaurants: restaurantStats(lifetime),
    achievements: computeAchievements(sessions),
    days: piecesByDay(lifetime),
  );
});
