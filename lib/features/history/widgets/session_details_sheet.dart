import 'package:flutter/material.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/stats/providers/records_provider.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/features/history/history_entries.dart';

/// Watches the session list so a price change shows up immediately.
class SessionDetailsSheet extends ConsumerWidget {
  const SessionDetailsSheet({
    super.key,
    required this.id,
    required this.onDelete,
  });

  final String id;
  final VoidCallback onDelete;

  Future<void> _editPrice(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<_PriceResult>(
      context: context,
      builder: (_) => _PriceDialog(initialCents: session.priceCents),
    );
    if (result == null) return;
    try {
      await ref.read(storageProvider).setSessionPrice(id, result.cents);
      ref.read(sessionListProvider.notifier).reload();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotSavePrice)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref
        .watch(sessionListProvider)
        .where((s) => s.id == id)
        .firstOrNull;
    if (session == null) return const SizedBox.shrink();
    final epoch = ref.watch(globalStateProvider.select((g) => g.epoch));
    final locale = context.localeName;
    final colors = context.colors;
    final pace = session.tapsPerMinute;
    final price = session.priceCents;
    final best = ref.watch(lifetimeBestProvider);
    final inLifetime = session.isInLifetime(epoch);
    final isRecord = inLifetime && best > 0 && session.count == best;
    final time = DateFormat.Hm(locale);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SushiArt(
                  size: 64,
                  mood: isRecord ? SushiMood.starry : SushiMood.happy,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.sessionDetails,
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                      ),
                      Text(
                        toBeginningOfSentenceCase(
                          DateFormat.yMMMMEEEEd(locale).format(session.endedAt),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        l10n.timeRange(
                          time.format(session.startedAt),
                          time.format(session.endedAt),
                        ),
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (icon, label, value) in [
                      (Icons.restaurant, l10n.detailPieces, '${session.count}'),
                      (
                        Icons.timer_outlined,
                        l10n.detailDuration,
                        formatSessionSeconds(session.durationSeconds),
                      ),
                      (
                        Icons.speed,
                        l10n.detailPace,
                        pace == null
                            ? l10n.noValue
                            : l10n.paceValue(
                                NumberFormat('0.0', locale).format(pace),
                              ),
                      ),
                      (
                        Icons.payments_outlined,
                        l10n.detailPrice,
                        price == null
                            ? l10n.noValue
                            : formatMoney(context, price),
                      ),
                    ])
                      SizedBox(
                        width: width,
                        child: _DetailTile(
                          icon: icon,
                          label: label,
                          value: value,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (!inLifetime) ...[
              const SizedBox(height: 12),
              Text(
                l10n.beforeResetDetail,
                style: TextStyle(color: colors.textMuted),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editPrice(context, ref, session),
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(price == null ? l10n.setPrice : l10n.editPrice),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accent,
                      side: BorderSide(color: colors.accent),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.deleteSessionTooltip),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.danger,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Null cents means "remove the price".
typedef _PriceResult = ({int? cents});

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.initialCents});

  final int? initialCents;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _controller;
  bool _invalid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initial = widget.initialCents;
    if (initial != null && _controller.text.isEmpty) {
      _controller.text = priceInputText(context, initial);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final cents = parsePriceCents(_controller.text);
    if (cents == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop<_PriceResult>(context, (cents: cents));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.priceDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          hintText: l10n.priceHint,
          errorText: _invalid ? l10n.priceInvalid : null,
        ),
      ),
      actions: [
        if (widget.initialCents != null)
          TextButton(
            onPressed: () =>
                Navigator.pop<_PriceResult>(context, (cents: null)),
            child: Text(l10n.removePrice),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
