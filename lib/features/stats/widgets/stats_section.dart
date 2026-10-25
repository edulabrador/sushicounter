import 'package:flutter/material.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/l10n/l10n.dart';

/// A label and its value, for reading a chart as a list.
typedef ChartRow = ({String label, String value});

/// A titled card holding one chart. With [rows], a button switches between
/// the chart and a plain list of its values, which screen readers can read
/// item by item and which shows exact figures.
class StatsSection extends StatefulWidget {
  const StatsSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.rows,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final List<ChartRow>? rows;

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  bool _asList = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = widget.rows;
    final showList = _asList && rows != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (!showList) ?widget.trailing,
                      ],
                    ),
                  ),
                ),
                if (rows != null)
                  IconButton(
                    tooltip: showList ? l10n.showAsChart : l10n.showAsList,
                    icon: Icon(
                      showList ? Icons.show_chart : Icons.view_list_outlined,
                    ),
                    onPressed: () => setState(() => _asList = !_asList),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: showList ? _ChartList(rows: rows) : widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartList extends StatelessWidget {
  const _ChartList({required this.rows});

  final List<ChartRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const Divider(height: 1),
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  ),
                  Text(
                    row.value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
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
