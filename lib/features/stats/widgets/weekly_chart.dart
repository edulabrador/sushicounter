import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.weeks});

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
