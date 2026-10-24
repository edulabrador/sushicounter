import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

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
    final now = DateTime.now();
    final records = computeRecords(lifetime, now);
    final costPerPiece = summary.costPerPieceCents;
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
                  _KpiGrid(
                    width: constraints.maxWidth,
                    items: [
                      _Kpi(
                        Icons.all_inclusive,
                        l10n.lifetimeTaps,
                        '$lifetimeTaps',
                      ),
                      _Kpi(
                        Icons.event_available,
                        l10n.lifetimeSessions,
                        '${global.lifetimeTotalSessions}',
                      ),
                      _Kpi(
                        Icons.insights,
                        l10n.averageKpi(range),
                        decimal.format(summary.averageTaps),
                      ),
                      _Kpi(
                        Icons.emoji_events_outlined,
                        l10n.bestKpi(range),
                        '${summary.bestSession}',
                      ),
                      if (costPerPiece != null)
                        _Kpi(
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
                  _Section(
                    title: l10n.sessionTrend,
                    trailing: summary.sessions.isEmpty
                        ? null
                        : _AverageLegend(
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
                              child: _SessionChart(
                                sessions: summary.sessions,
                                best: summary.bestSession,
                                average: summary.averageTaps,
                              ),
                            ),
                          ),
                  ),
                  if (lifetime.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Section(
                      title: l10n.weeklyTitle,
                      child: Semantics(
                        label: l10n.weeklySemantics(8),
                        child: SizedBox(
                          height: 200,
                          child: _WeeklyChart(
                            weeks: weeklyPieces(lifetime, now),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(l10n.recordsTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _KpiGrid(
                    width: constraints.maxWidth,
                    items: [
                      _Kpi.art(
                        const SushiArt(size: 30, mood: SushiMood.starry),
                        l10n.bestEver,
                        '${records.bestSession}',
                      ),
                      _Kpi(
                        Icons.local_fire_department_outlined,
                        l10n.weeklyStreak,
                        l10n.weeksCount(records.weeklyStreak),
                      ),
                      _Kpi(
                        Icons.calendar_month_outlined,
                        l10n.sessionsThisMonth,
                        '${records.sessionsThisMonth}',
                      ),
                      _Kpi(
                        Icons.restaurant,
                        l10n.piecesThisMonth,
                        '${records.piecesThisMonth}',
                      ),
                    ],
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

/// A titled card holding one chart.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _Kpi {
  const _Kpi(IconData this.icon, this.label, this.value) : art = null;
  const _Kpi.art(Widget this.art, this.label, this.value) : icon = null;

  final IconData? icon;
  final Widget? art;
  final String label;
  final String value;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.width, required this.items});
  final double width;
  final List<_Kpi> items;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    final columns = width >= 600 ? 3 : 2;
    final tileWidth = (width - gap * (columns - 1)) / columns;
    final colors = context.colors;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final (index, item) in items.indexed)
          SizedBox(
            // An odd last tile spans the row instead of leaving a gap.
            width:
                columns == 2 && items.length.isOdd && index == items.length - 1
                ? width
                : tileWidth,
            child: Semantics(
              label: '${item.label}: ${item.value}',
              excludeSemantics: true,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30,
                        child:
                            item.art ??
                            Container(
                              width: 30,
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color: colors.accent,
                              ),
                            ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.value,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Marks the record session on the trend line with the starry nigiri.
class _NigiriDotPainter extends FlDotPainter {
  const _NigiriDotPainter(this.size);

  final double size;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) => paintNigiri(
    canvas,
    Rect.fromCenter(center: offsetInCanvas, width: size, height: size),
    mood: SushiMood.starry,
  );

  @override
  Size getSize(FlSpot spot) => Size.square(size);

  @override
  Color get mainColor => SushiPalette.salmon;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => b;

  @override
  List<Object?> get props => [size];
}

class _SessionChart extends StatelessWidget {
  const _SessionChart({
    required this.sessions,
    required this.best,
    required this.average,
  });
  final List<Session> sessions;
  final int best;
  final double average;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final colors = context.colors;
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
    final showDots = sessions.length <= 30;
    // Room on the right and top for the record's nigiri marker.
    return Padding(
      padding: const EdgeInsets.only(right: 14, top: 6),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          // Headroom so the record's nigiri marker is not cut off.
          maxY: yStep * 4.0 + yStep * 0.6,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yStep.toDouble(),
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
              dashArray: [4, 6],
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: average,
                color: colors.textMuted.withValues(alpha: 0.7),
                strokeWidth: 1.5,
                dashArray: [6, 4],
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (bar, indexes) => [
              for (final _ in indexes)
                TouchedSpotIndicatorData(
                  FlLine(
                    color: colors.textMuted.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: const [3, 3],
                  ),
                  FlDotData(
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 6,
                      color: SushiPalette.rice,
                      strokeWidth: 3,
                      strokeColor: SushiPalette.salmon,
                    ),
                  ),
                ),
            ],
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => colors.background,
              getTooltipItems: (spots) => spots.map((spot) {
                final session = sessions[spot.spotIndex];
                return LineTooltipItem(
                  '${DateFormat.yMMMd(locale).add_Hm().format(session.endedAt)}\n${l10n.tapsCount(session.count)}',
                  TextStyle(color: colors.text, fontWeight: FontWeight.w600),
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
                reservedSize: 32,
                interval: yStep.toDouble(),
                getTitlesWidget: (value, meta) => value > yStep * 4
                    ? const SizedBox.shrink()
                    : Text(
                        value.toInt().toString(),
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
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
                    child: Text(
                      DateFormat.MMMd(locale).format(date),
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
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
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              gradient: const LinearGradient(
                colors: [SushiPalette.salmonStripe, SushiPalette.salmon],
              ),
              barWidth: 3.5,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SushiPalette.salmonStripe.withValues(alpha: 0.28),
                    SushiPalette.salmonStripe.withValues(alpha: 0),
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => showDots || spot.y == best,
                getDotPainter: (spot, _, _, _) => spot.y == best
                    ? const _NigiriDotPainter(36)
                    : FlDotCirclePainter(
                        radius: 3.5,
                        color: SushiPalette.rice,
                        strokeWidth: 2,
                        strokeColor: SushiPalette.salmon,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.weeks});

  final List<({DateTime weekStart, int pieces})> weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    final colors = context.colors;
    final most = weeks.fold(0, (m, w) => math.max(m, w.pieces));
    final yStep = math.max(1, (most / 4).ceil());
    final maxY = yStep * 4.0;
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yStep.toDouble(),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Colors.white10,
            strokeWidth: 1,
            dashArray: [4, 6],
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => colors.background,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${DateFormat.MMMd(locale).format(weeks[group.x].weekStart)}\n${l10n.piecesCount(rod.toY.round())}',
              TextStyle(color: colors.text, fontWeight: FontWeight.w600),
            ),
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
              reservedSize: 32,
              interval: yStep.toDouble(),
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                // Every other week keeps the dates from overlapping.
                if ((weeks.length - 1 - index).isOdd) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.MMMd(locale).format(weeks[index].weekStart),
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < weeks.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weeks[i].pieces.toDouble(),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: i == weeks.length - 1
                        ? [SushiPalette.salmon, SushiPalette.salmonStripe]
                        // Past weeks stay neutral so this week stands out.
                        : [
                            colors.textMuted.withValues(alpha: 0.35),
                            colors.textMuted.withValues(alpha: 0.5),
                          ],
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Explains the dashed line, kept off the chart so it never covers points.
class _AverageLegend extends StatelessWidget {
  const _AverageLegend({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 5,
            height: 2,
            margin: const EdgeInsets.only(right: 3),
            color: color,
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
