import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';

class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});

  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView> {
  String filter = 'All'; // All, Last 7, Last 30

  @override
  Widget build(BuildContext context) {
    final globalState = ref.watch(globalStateProvider);
    final repo = ref.read(storageProvider);
    var sessions = repo.getAllSessions();
    sessions = sessions.reversed.toList(); // chronological for chart

    int maxCount = 0;
    double avgTaps = 0;

    if (sessions.isNotEmpty) {
      if (filter == 'Last 7') {
        sessions = sessions.length > 7 ? sessions.sublist(sessions.length - 7) : sessions;
      } else if (filter == 'Last 30') {
        sessions = sessions.length > 30 ? sessions.sublist(sessions.length - 30) : sessions;
      }
      
      int t = 0;
      for (var s in sessions) {
        if (s.count > maxCount) maxCount = s.count;
        t += s.count;
      }
      avgTaps = t / sessions.length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('STATISTICS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // KPIs
            Row(
              children: [
                _buildKpiCard('Total Taps', '${globalState.lifetimeTotalTaps}'),
                _buildKpiCard('Total Sessions', '${globalState.lifetimeTotalSessions}'),
              ],
            ),
            Row(
              children: [
                _buildKpiCard('Avg Taps/Session', avgTaps.toStringAsFixed(1)),
                _buildKpiCard('Best Session', '$maxCount'),
              ],
            ),
            const SizedBox(height: 32),
            
            // Filters
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Last 7', label: Text('Last 7')),
                ButtonSegment(value: 'Last 30', label: Text('Last 30')),
                ButtonSegment(value: 'All', label: Text('All')),
              ],
              selected: {filter},
              onSelectionChanged: (set) {
                setState(() {
                  filter = set.first;
                });
              },
            ),
            const SizedBox(height: 32),

            // Chart
            if (sessions.isNotEmpty)
              SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sessions.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value.count.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Center(child: Text('Not enough data for chart')),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
        ),
      ),
    );
  }
}
