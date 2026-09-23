import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';

enum StatsFilter { last7, last30, all }

extension on StatsFilter {
  String get label => switch (this) {
    StatsFilter.last7 => '7 sessions',
    StatsFilter.last30 => '30 sessions',
    StatsFilter.all => 'All sessions',
  };

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
}

/// Sort by actual completion time so the chart remains chronological even if
/// storage returns sessions in a different order.
StatsSummary summarizeSessions(List<Session> source, StatsFilter filter) {
  final sessions = [...source]..sort((a, b) => a.endedAt.compareTo(b.endedAt));
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

class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});

  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView> {
  StatsFilter _filter = StatsFilter.all;

  @override
  Widget build(BuildContext context) {
    final global = ref.watch(globalStateProvider);
    final summary = summarizeSessions(ref.watch(sessionListProvider), _filter);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('STATISTICS')),
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
                    _KpiGrid(
                      width: contentConstraints.maxWidth,
                      items: [
                        _Kpi('Lifetime Taps', '${global.lifetimeTotalTaps}'),
                        _Kpi(
                          'Lifetime Sessions',
                          '${global.lifetimeTotalSessions}',
                        ),
                        _Kpi(
                          'Average (${_filter.label})',
                          summary.averageTaps.toStringAsFixed(1),
                        ),
                        _Kpi(
                          'Best (${_filter.label})',
                          '${summary.bestSession}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Semantics(
                      label: 'Session range in number of sessions',
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<StatsFilter>(
                          segments: StatsFilter.values
                              .map(
                                (filter) => ButtonSegment(
                                  value: filter,
                                  label: Text(filter.label),
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
                    Text('Session trend', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (summary.sessions.isEmpty)
                      Semantics(
                        liveRegion: true,
                        child: Center(
                          child: Text('Complete a session to see your trend.'),
                        ),
                      )
                    else
                      Semantics(
                        label:
                            'Session trend chart for ${summary.sessions.length} sessions. Tap a point to hear its date and tap count.',
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
    final yStep = math.max(1, (best / 4).ceil());
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, sessions.length - 1).toDouble(),
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
              final session = sessions[spot.x.round()];
              return LineTooltipItem(
                '${DateFormat.yMMMd().add_Hm().format(session.endedAt)}\n${session.count} taps',
                const TextStyle(
                  color: Colors.white,
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
              interval: math.max(1, (sessions.length - 1) ~/ 3).toDouble(),
              getTitlesWidget: (value, _) {
                final index = value.round();
                if (index < 0 || index >= sessions.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.MMMd().format(sessions[index].endedAt),
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
                FlSpot(i.toDouble(), sessions[i].count.toDouble()),
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
