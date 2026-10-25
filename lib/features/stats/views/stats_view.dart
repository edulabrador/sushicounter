import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

import 'package:sushiscore/features/stats/achievements.dart';
import 'package:sushiscore/features/stats/widgets/achievements_grid.dart';
import 'package:sushiscore/features/stats/widgets/kpi_grid.dart';
import 'package:sushiscore/features/stats/widgets/restaurant_list.dart';
import 'package:sushiscore/features/stats/widgets/stats_section.dart';
import 'package:sushiscore/features/stats/widgets/trend_chart.dart';
import 'package:sushiscore/features/stats/widgets/weekly_chart.dart';

export 'package:sushiscore/features/stats/stats_logic.dart';

extension on StatsFilter {
  String label(AppLocalizations l10n) => switch (this) {
    StatsFilter.last7 => l10n.filterLast7,
    StatsFilter.last30 => l10n.filterLast30,
    StatsFilter.all => l10n.filterAll,
  };
}

class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});

  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView> {
  StatsFilter _filter = StatsFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final global = ref.watch(globalStateProvider);
    final lifetimeTaps = ref.watch(lifetimeTapsProvider);
    final sessions = ref.watch(sessionListProvider);
    final lifetime = lifetimeSessions(sessions, global.epoch);
    final summary = summarizeSessions(sessions, _filter, epoch: global.epoch);
    final now = clock.now();
    final records = computeRecords(lifetime, now);
    final costPerPiece = summary.costPerPieceCents;
    final achievements = computeAchievements(sessions);
    final weekly = weeklyPieces(lifetime, now);
    final theme = Theme.of(context);
    final resetAt = global.lastResetAt;
    final range = _filter.label(l10n);
    final decimal = NumberFormat('0.0', locale);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (resetAt != null) ...[
                    Text(
                      l10n.sinceReset(DateFormat.yMMMd(locale).format(resetAt)),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                  ],
                  KpiGrid(
                    width: constraints.maxWidth,
                    items: [
                      Kpi(
                        Icons.all_inclusive,
                        l10n.lifetimeTaps,
                        '$lifetimeTaps',
                      ),
                      Kpi(
                        Icons.event_available,
                        l10n.lifetimeSessions,
                        '${global.lifetimeTotalSessions}',
                      ),
                      Kpi(
                        Icons.insights,
                        l10n.averageKpi(range),
                        decimal.format(summary.averageTaps),
                      ),
                      Kpi(
                        Icons.emoji_events_outlined,
                        l10n.bestKpi(range),
                        '${summary.bestSession}',
                      ),
                      if (costPerPiece != null)
                        Kpi(
                          Icons.payments_outlined,
                          l10n.costPerPiece(range),
                          formatMoney(context, costPerPiece),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    label: l10n.rangeSemantics,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: SegmentedButton<StatsFilter>(
                          showSelectedIcon: false,
                          segments: [
                            for (final filter in StatsFilter.values)
                              ButtonSegment(
                                value: filter,
                                label: Text(filter.label(l10n)),
                              ),
                          ],
                          selected: {_filter},
                          onSelectionChanged: (selection) =>
                              setState(() => _filter = selection.first),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatsSection(
                    title: l10n.sessionTrend,
                    rows: summary.sessions.isEmpty
                        ? null
                        : [
                            for (final session in summary.sessions.reversed)
                              (
                                label: DateFormat.yMMMd(
                                  locale,
                                ).add_Hm().format(session.endedAt),
                                value: l10n.tapsCount(session.count),
                              ),
                          ],
                    trailing: summary.sessions.isEmpty
                        ? null
                        : AverageLegend(
                            label: l10n.averageLine(
                              decimal.format(summary.averageTaps),
                            ),
                          ),
                    child: summary.sessions.isEmpty
                        ? Semantics(
                            liveRegion: true,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  const SushiArt(
                                    size: 96,
                                    mood: SushiMood.sleepy,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.noTrend,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Semantics(
                            label: l10n.chartSemantics(summary.sessions.length),
                            child: SizedBox(
                              height: 260,
                              child: TrendChart(
                                sessions: summary.sessions,
                                best: summary.bestSession,
                                average: summary.averageTaps,
                              ),
                            ),
                          ),
                  ),
                  if (lifetime.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    StatsSection(
                      title: l10n.weeklyTitle,
                      rows: [
                        for (final week in weekly.reversed)
                          (
                            label: l10n.weekOf(
                              DateFormat.MMMd(locale).format(week.weekStart),
                            ),
                            value: l10n.piecesCount(week.pieces),
                          ),
                      ],
                      child: Semantics(
                        label: l10n.weeklySemantics(8),
                        child: SizedBox(
                          height: 200,
                          child: WeeklyChart(weeks: weekly),
                        ),
                      ),
                    ),
                  ],
                  if (restaurantStats(lifetime) case final restaurants
                      when restaurants.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    StatsSection(
                      title: l10n.byRestaurantTitle,
                      child: RestaurantList(restaurants: restaurants),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(l10n.recordsTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  KpiGrid(
                    width: constraints.maxWidth,
                    items: [
                      Kpi.art(
                        const SushiArt(size: 30, mood: SushiMood.starry),
                        l10n.bestEver,
                        '${records.bestSession}',
                      ),
                      Kpi(
                        Icons.local_fire_department_outlined,
                        l10n.weeklyStreak,
                        l10n.weeksCount(records.weeklyStreak),
                      ),
                      Kpi(
                        Icons.calendar_month_outlined,
                        l10n.sessionsThisMonth,
                        '${records.sessionsThisMonth}',
                      ),
                      Kpi(
                        Icons.restaurant,
                        l10n.piecesThisMonth,
                        '${records.piecesThisMonth}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 8,
                    children: [
                      Text(
                        l10n.achievementsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        l10n.achievementsCount(
                          achievements.where((a) => a.unlocked).length,
                          achievements.length,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AchievementsGrid(
                    achievements: achievements,
                    width: constraints.maxWidth,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
