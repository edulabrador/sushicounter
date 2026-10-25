import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

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

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
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
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.outline,
              strokeWidth: 1,
              dashArray: const [4, 6],
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
