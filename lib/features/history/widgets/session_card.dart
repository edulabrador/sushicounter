import 'package:flutter/material.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/features/history/history_entries.dart';

class MonthHeaderTile extends StatelessWidget {
  const MonthHeaderTile({super.key, required this.header});

  final MonthHeader header;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final month = toBeginningOfSentenceCase(
      DateFormat.yMMMM(context.localeName).format(header.month),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 8,
        children: [
          Text(month, style: Theme.of(context).textTheme.titleMedium),
          Text(
            l10n.monthSummary(header.sessions, header.pieces),
            style: TextStyle(color: context.colors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.inLifetime,
    required this.isRecord,
    required this.deleting,
    required this.onTap,
    required this.onDelete,
  });

  final Session session;
  final bool inLifetime;
  final bool isRecord;
  final bool deleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final duration = l10n.durationLabel(
      formatSessionSeconds(session.durationSeconds),
    );
    final price = session.priceCents;
    final date = DateFormat.MMMEd(
      context.localeName,
    ).add_Hm().format(session.endedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Opacity(
                  opacity: inLifetime ? 1 : 0.5,
                  child: SushiArt(
                    size: 44,
                    mood: isRecord ? SushiMood.starry : SushiMood.happy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toBeginningOfSentenceCase(date),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inLifetime
                            ? duration
                            : '$duration · ${l10n.beforeReset}',
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                      ),
                      if (price != null ||
                          isRecord ||
                          session.restaurant != null ||
                          session.companions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (isRecord)
                              _Chip(
                                icon: Icons.emoji_events,
                                label: l10n.recordBadge,
                                highlighted: true,
                              ),
                            if (session.restaurant case final name?)
                              _Chip(
                                icon: Icons.storefront_outlined,
                                label: name,
                              ),
                            if (price != null)
                              _Chip(
                                icon: Icons.payments_outlined,
                                label: formatMoney(context, price),
                              ),
                            if (session.companions.isNotEmpty)
                              _Chip(
                                icon: Icons.group_outlined,
                                label: '+${session.companions.length}',
                                semanticsLabel: l10n.tablePeople(
                                  session.companions.length,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      '${session.count}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: inLifetime ? colors.accent : colors.textMuted,
                      ),
                    ),
                    Text(
                      l10n.piecesUnit(session.count),
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colors.danger),
                  tooltip: l10n.deleteSessionTooltip,
                  onPressed: deleting ? null : onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.highlighted = false,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = highlighted ? colors.accent : colors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            semanticsLabel: semanticsLabel,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
