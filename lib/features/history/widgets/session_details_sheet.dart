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
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/features/history/widgets/edit_session_dialog.dart';
import 'package:sushiscore/features/history/widgets/share_session_dialog.dart';

/// Watches the session list so a price change shows up immediately.
class SessionDetailsSheet extends ConsumerWidget {
  const SessionDetailsSheet({
    super.key,
    required this.id,
    required this.onDelete,
  });

  final String id;
  final VoidCallback onDelete;

  Future<void> _editRestaurant(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final suggestions = knownRestaurants(ref.read(sessionListProvider));
    final result = await showDialog<_RestaurantResult>(
      context: context,
      builder: (_) => _RestaurantDialog(
        initial: session.restaurant,
        suggestions: suggestions,
      ),
    );
    if (result == null) return;
    try {
      await ref.read(storageProvider).setSessionRestaurant(id, result.name);
      ref.read(sessionListProvider.notifier).reload();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotSaveRestaurant)),
      );
    }
  }

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

  Future<void> _editSession(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<SessionEdit>(
      context: context,
      builder: (_) => EditSessionDialog(session: session),
    );
    if (result == null) return;
    try {
      await ref
          .read(storageProvider)
          .editSession(id, count: result.count, startedAt: result.startedAt);
      ref.read(globalStateProvider.notifier).reload();
      ref.read(sessionListProvider.notifier).reload();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotSaveSession)));
    }
  }

  Future<void> _share(
    BuildContext context,
    Session session, {
    required bool isRecord,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<ShareResult>(
      context: context,
      builder: (_) => ShareSessionDialog(session: session, isRecord: isRecord),
    );
    final message = switch (result) {
      ShareResult.copied => l10n.summaryCopied,
      ShareResult.failed => l10n.couldNotShare,
      ShareResult.shared || null => null,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
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
                IconButton(
                  onPressed: () => _share(context, session, isRecord: isRecord),
                  tooltip: l10n.shareSession,
                  icon: const Icon(Icons.share_outlined),
                ),
                IconButton(
                  onPressed: () => _editSession(context, ref, session),
                  tooltip: l10n.editSession,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RestaurantRow(
              name: session.restaurant,
              onTap: () => _editRestaurant(context, ref, session),
            ),
            const SizedBox(height: 12),
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
            if (session.companions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TableList(session: session),
            ],
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

/// Everyone at the table, most pieces first, with the table total.
class _TableList extends StatelessWidget {
  const _TableList({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final people = [
      (name: l10n.you, count: session.count, isYou: true),
      for (final c in session.companions)
        (name: c.name, count: c.count, isYou: false),
    ]..sort((a, b) => b.count.compareTo(a.count));
    final total = people.fold(0, (sum, p) => sum + p.count);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, size: 20, color: colors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.tableTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                l10n.tableTotal(l10n.piecesCount(total)),
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final person in people)
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: person.isYou
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: person.isYou ? colors.accent : colors.text,
                        ),
                      ),
                    ),
                    Text(
                      l10n.piecesCount(person.count),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
/// Shows the restaurant, or invites adding one; tapping edits it.
class _RestaurantRow extends StatelessWidget {
  const _RestaurantRow({required this.name, required this.onTap});

  final String? name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final name = this.name;
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, size: 20, color: colors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name ?? l10n.addRestaurant,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: name == null ? colors.accent : colors.text,
                  ),
                ),
              ),
              Icon(
                name == null ? Icons.add : Icons.edit_outlined,
                size: 18,
                color: colors.textMuted,
                semanticLabel: name == null ? null : l10n.editRestaurant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Null name means "remove the restaurant".
typedef _RestaurantResult = ({String? name});

class _RestaurantDialog extends StatefulWidget {
  const _RestaurantDialog({required this.initial, required this.suggestions});

  final String? initial;
  final List<String> suggestions;

  @override
  State<_RestaurantDialog> createState() => _RestaurantDialogState();
}

class _RestaurantDialogState extends State<_RestaurantDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  late final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop<_RestaurantResult>(context, (
    name: Session.normalizeRestaurant(_controller.text),
  ));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.restaurantDialogTitle),
      content: RawAutocomplete<String>(
        textEditingController: _controller,
        focusNode: _focus,
        optionsBuilder: (value) {
          final query = value.text.trim().toLowerCase();
          return widget.suggestions.where(
            (name) =>
                name.toLowerCase().contains(query) &&
                name.toLowerCase() != query,
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              maxLength: Session.maxRestaurantLength,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(hintText: l10n.restaurantHint),
            ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: context.colors.surface,
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.storefront_outlined, size: 18),
                      title: Text(option),
                      onTap: () => onSelected(option),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () =>
                Navigator.pop<_RestaurantResult>(context, (name: null)),
            child: Text(l10n.removeRestaurant),
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
