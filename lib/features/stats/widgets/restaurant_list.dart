import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/l10n/l10n.dart';

/// One row per restaurant; the cheapest per piece gets a trophy, since that
/// is the question this section answers.
class RestaurantList extends StatelessWidget {
  const RestaurantList({super.key, required this.restaurants});

  final List<RestaurantStats> restaurants;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final decimal = NumberFormat('0.0', context.localeName);
    final priced = restaurants.where((r) => r.costPerPieceCents != null);
    final cheapest = priced.length < 2
        ? null
        : priced.reduce(
            (a, b) => a.costPerPieceCents! <= b.costPerPieceCents! ? a : b,
          );
    return Column(
      children: [
        for (final (index, restaurant) in restaurants.indexed) ...[
          if (index > 0) const Divider(height: 16),
          Row(
            children: [
              Icon(
                identical(restaurant, cheapest)
                    ? Icons.emoji_events
                    : Icons.storefront_outlined,
                color: colors.accent,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      l10n.restaurantSummary(
                        restaurant.sessions,
                        decimal.format(restaurant.averagePieces),
                      ),
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (restaurant.costPerPieceCents case final cents?)
                Text(
                  l10n.perPiece(formatMoney(context, cents)),
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
