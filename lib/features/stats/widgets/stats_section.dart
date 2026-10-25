import 'package:flutter/material.dart';
import 'package:sushiscore/core/theme/app_colors.dart';

/// A titled card holding one chart.
class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

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

/// Explains the dashed line, kept off the chart so it never covers points.
class AverageLegend extends StatelessWidget {
  const AverageLegend({super.key, required this.label});

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
