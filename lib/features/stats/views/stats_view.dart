import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/l10n/l10n.dart';

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
    final global = ref.watch(globalStateProvider);
    final lifetimeTaps = ref.watch(lifetimeTapsProvider);
    final sessions = ref.watch(sessionListProvider);
    final summary = summarizeSessions(sessions, _filter, epoch: global.epoch);
    final records = computeRecords(
      lifetimeSessions(sessions, global.epoch),
      DateTime.now(),
    );
    final costPerPiece = summary.costPerPieceCents;
    final theme = Theme.of(context);
    final resetAt = global.lastResetAt;
    final range = _filter.label(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: LayoutBuilder(
                builder: (context, contentConstraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (resetAt != null) ...[
                      Text(
                        l10n.sinceReset(
                          DateFormat.yMMMd(context.localeName).format(resetAt),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _KpiGrid(
                      width: contentConstraints.maxWidth,
                      items: [
                        _Kpi(l10n.lifetimeTaps, '$lifetimeTaps'),
                        _Kpi(
                          l10n.lifetimeSessions,
                          '${global.lifetimeTotalSessions}',
                        ),
                        _Kpi(
                          l10n.averageKpi(range),
                          NumberFormat(
                            '0.0',
                            context.localeName,
                          ).format(summary.averageTaps),
                        ),
                        _Kpi(l10n.bestKpi(range), '${summary.bestSession}'),
                        if (costPerPiece != null)
                          _Kpi(
                            l10n.costPerPiece(range),
                            formatMoney(context, costPerPiece),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.recordsTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _KpiGrid(
                      width: contentConstraints.maxWidth,
                      items: [
                        _Kpi(l10n.bestEver, '${records.bestSession}'),
                        _Kpi(
                          l10n.weeklyStreak,
                          l10n.weeksCount(records.weeklyStreak),
                        ),
                        _Kpi(
                          l10n.sessionsThisMonth,
                          '${records.sessionsThisMonth}',
                        ),
                        _Kpi(
                          l10n.piecesThisMonth,
                          '${records.piecesThisMonth}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Semantics(
                      label: l10n.rangeSemantics,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<StatsFilter>(
                          segments: StatsFilter.values
                              .map(
                                (filter) => ButtonSegment(
                                  value: filter,
                                  label: Text(filter.label(l10n)),
                                ),
                              )
                              .toList(),
                          selected: {_filter},
                          onSelectionChanged: (selection) =>
                              setState(() => _filter = selection.first),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.sessionTrend, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (summary.sessions.isEmpty)
                      Semantics(
                        liveRegion: true,
                        child: Center(child: Text(l10n.noTrend)),
                      )
                    else
                      Semantics(
                        label: l10n.chartSemantics(summary.sessions.length),
                        child: SizedBox(
                          height: 300,
                          child: _SessionChart(
                            sessions: summary.sessions,
                            best: summary.bestSession,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value);
  final String label;
  final String value;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.width, required this.items});
  final double width;
  final List<_Kpi> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: items
        .map(
          (item) => SizedBox(
            width: width >= 600 ? (width - 12) / 2 : width,
            child: Semantics(
              label: '${item.label}: ${item.value}',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.value,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _SessionChart extends StatelessWidget {
  const _SessionChart({required this.sessions, required this.best});
  final List<Session> sessions;
  final int best;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final yStep = math.max(1, (best / 4).ceil());
    // X is days since the first session, so a month without visits shows as
    // a gap instead of two neighbouring points.
    final origin = sessions.first.endedAt;
    final xs = [for (final s in sessions) chartDay(s.endedAt, origin)];
    final span = xs.last;
    // A short range (one session, or all on one day) is widened and centred.
    final narrow = span < 1;
    final minX = narrow ? span / 2 - 1 : 0.0;
    final maxX = narrow ? span / 2 + 1 : span;
    final labelInterval = narrow ? 1.0 : math.max(1.0, span / 3);
    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: yStep * 4.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yStep.toDouble(),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            getTooltipItems: (spots) => spots.map((spot) {
              final session = sessions[spot.spotIndex];
              return LineTooltipItem(
                '${DateFormat.yMMMd(locale).add_Hm().format(session.endedAt)}\n${l10n.tapsCount(session.count)}',
                TextStyle(
                  color: context.colors.text,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: yStep.toDouble(),
              getTitlesWidget: (value, _) => Text(value.toInt().toString()),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: labelInterval,
              getTitlesWidget: (value, meta) {
                // Only label real days inside the data range.
                if (value < -0.01 || value > span + 0.01) {
                  return const SizedBox.shrink();
                }
                final date = origin.add(
                  Duration(minutes: (value * Duration.minutesPerDay).round()),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(DateFormat.MMMd(locale).format(date)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < sessions.length; i++)
                FlSpot(xs[i], sessions[i].count.toDouble()),
            ],
            isCurved: false,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: sessions.length <= 30),
          ),
        ],
      ),
    );
  }
}
