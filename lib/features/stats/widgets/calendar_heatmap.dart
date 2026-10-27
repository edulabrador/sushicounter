import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/l10n/l10n.dart';

const _cell = 14.0;
const _gap = 3.0;
const _labelWidth = 22.0;
const _monthHeight = 16.0;

/// How many whole weeks fit in [width], within a readable range.
int calendarWeeksFor(double width) =>
    ((width - _labelWidth + _gap) / (_cell + _gap)).floor().clamp(8, 26);

/// Days as columns of weeks (Monday on top), ending with the week of [now].
/// Darker salmon means more pieces that day.
class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    super.key,
    required this.days,
    required this.now,
    required this.weeks,
  });

  final Map<DateTime, int> days;
  final DateTime now;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = context.localeName;
    final mondays = [
      for (var i = weeks - 1; i >= 0; i--) weekStart(weekIndex(now) - i),
    ];
    final weekday = DateFormat.E(locale);
    final legend = TextStyle(color: colors.textMuted, fontSize: 11);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _monthHeight + 7 * _cell + 6 * _gap,
          width: _labelWidth + weeks * (_cell + _gap) - _gap,
          child: CustomPaint(
            painter: _HeatmapPainter(
              days: days,
              mondays: mondays,
              today: DateTime(now.year, now.month, now.day),
              colors: colors,
              month: DateFormat.MMM(locale),
              weekdays: [
                // Monday, Wednesday and Friday, like most calendars.
                for (final offset in [0, 2, 4])
                  weekday
                      .format(mondays.first.add(Duration(days: offset)))
                      .characters
                      .first
                      .toUpperCase(),
              ],
              textStyle: legend,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(l10n.calendarLess, style: legend),
            const SizedBox(width: 6),
            for (var level = 0; level <= 4; level++) ...[
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: _levelColor(colors, level),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 3),
            ],
            const SizedBox(width: 3),
            Text(l10n.calendarMore, style: legend),
          ],
        ),
      ],
    );
  }
}

Color _levelColor(AppColors colors, int level) => switch (level) {
  0 => colors.outline,
  1 => colors.accent.withValues(alpha: 0.3),
  2 => colors.accent.withValues(alpha: 0.5),
  3 => colors.accent.withValues(alpha: 0.75),
  _ => colors.accent,
};

/// Whether the month label goes above [column]: where a month starts, if
/// there is room for it before the next label and the right edge. The first
/// column only gets one when its month lasts long enough to be read.
bool monthLabelAt(List<int> months, int column, int lastLabel) {
  const room = 3;
  if (column >= months.length - 1 || column - lastLabel < room) return false;
  if (column == 0) {
    return months.length > room &&
        months.take(room).every((month) => month == months.first);
  }
  return months[column] != months[column - 1];
}

/// 0 for no pieces, then four steps up to the busiest day shown.
int heatLevel(int pieces, int max) {
  if (pieces <= 0 || max <= 0) return 0;
  return math.max(1, (pieces / max * 4).ceil()).clamp(1, 4);
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.days,
    required this.mondays,
    required this.today,
    required this.colors,
    required this.month,
    required this.weekdays,
    required this.textStyle,
  });

  final Map<DateTime, int> days;
  final List<DateTime> mondays;
  final DateTime today;
  final AppColors colors;
  final DateFormat month;
  final List<String> weekdays;
  final TextStyle textStyle;

  DateTime _day(DateTime monday, int offset) =>
      DateTime(monday.year, monday.month, monday.day + offset);

  void _text(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    var max = 0;
    for (final monday in mondays) {
      for (var d = 0; d < 7; d++) {
        max = math.max(max, days[_day(monday, d)] ?? 0);
      }
    }
    for (final (row, label) in weekdays.indexed) {
      _text(
        canvas,
        label,
        Offset(0, _monthHeight + row * 2 * (_cell + _gap) - 1),
      );
    }
    final months = [for (final monday in mondays) _day(monday, 6).month];
    var lastLabel = -3;
    for (final (column, monday) in mondays.indexed) {
      final x = _labelWidth + column * (_cell + _gap);
      if (monthLabelAt(months, column, lastLabel)) {
        _text(canvas, month.format(_day(monday, 6)), Offset(x, 0));
        lastLabel = column;
      }
      for (var d = 0; d < 7; d++) {
        final day = _day(monday, d);
        if (day.isAfter(today)) continue;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, _monthHeight + d * (_cell + _gap), _cell, _cell),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = _levelColor(colors, heatLevel(days[day] ?? 0, max)),
        );
        if (day == today) {
          canvas.drawRRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = colors.textMuted,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.days != days ||
      old.today != today ||
      old.colors != colors ||
      old.mondays.length != mondays.length ||
      old.mondays.first != mondays.first;
}
