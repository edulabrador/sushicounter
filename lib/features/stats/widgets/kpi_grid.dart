import 'package:flutter/material.dart';
import 'package:sushiscore/core/theme/app_colors.dart';

class Kpi {
  const Kpi(IconData this.icon, this.label, this.value) : art = null;
  const Kpi.art(Widget this.art, this.label, this.value) : icon = null;

  final IconData? icon;
  final Widget? art;
  final String label;
  final String value;
}

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.width, required this.items});
  final double width;
  final List<Kpi> items;

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
