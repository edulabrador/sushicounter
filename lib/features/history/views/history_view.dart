import 'package:flutter/material.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/counter/views/counter_timer.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:intl/intl.dart';

String formatSessionSeconds(int seconds) =>
    formatSessionDuration(Duration(seconds: seconds));

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({super.key});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  bool _deleting = false;

  /// Deletes covered by the visible Undo snackbar, so consecutive deletes
  /// stay undoable instead of the newest snackbar dropping the older ones.
  final List<DeletedSession> _undoable = [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessions = ref.watch(sessionListProvider);
    final epoch = ref.watch(globalStateProvider.select((g) => g.epoch));
    final dateFormat = DateFormat.yMMMd(context.localeName).add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: sessions.isEmpty
          ? Center(
              child: Text(
                l10n.noSessions,
                style: TextStyle(color: context.colors.textMuted),
              ),
            )
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final inLifetime = session.isInLifetime(epoch);
                final duration = l10n.durationLabel(
                  formatSessionSeconds(session.durationSeconds),
                );
                return ListTile(
                  leading: Icon(
                    Icons.history,
                    color: inLifetime
                        ? context.colors.accent
                        : context.colors.textMuted,
                  ),
                  title: Text(
                    dateFormat.format(session.endedAt),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    inLifetime ? duration : '$duration · ${l10n.beforeReset}',
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 132),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${session.count}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: context.colors.danger,
                          ),
                          tooltip: l10n.deleteSessionTooltip,
                          onPressed: _deleting
                              ? null
                              : () => _deleteSession(session.id),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _showDetails(session.id),
                );
              },
            ),
    );
  }

  void _showDetails(String id) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _SessionDetails(
        id: id,
        onDelete: () {
          Navigator.pop(context);
          _deleteSession(id);
        },
      ),
    );
  }

  Future<void> _deleteSession(String id) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSessionTitle),
        content: Text(l10n.deleteSessionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: context.colors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final deleted = await ref
          .read(sessionListProvider.notifier)
          .deleteSession(id);
      if (deleted == null || !mounted) return;
      _undoable.add(deleted);
      _showUndo();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.couldNotDelete)));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showUndo() {
    final batch = List<DeletedSession>.of(_undoable);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger
        .showSnackBar(
          SnackBar(
            content: Text(context.l10n.sessionsDeleted(batch.length)),
            action: SnackBarAction(
              label: context.l10n.undo,
              onPressed: () => _restoreSessions(batch),
            ),
          ),
        )
        .closed
        .then((reason) {
          // A newer snackbar replaced this one and carries the same batch.
          if (reason == SnackBarClosedReason.hide) return;
          _undoable.removeWhere(batch.contains);
        });
  }

  Future<void> _restoreSessions(List<DeletedSession> batch) async {
    _undoable.removeWhere(batch.contains);
    final failed = context.l10n.couldNotRestore;
    // Restore newest delete first so totals unwind in reverse order.
    for (final deleted in batch.reversed) {
      try {
        await ref.read(sessionListProvider.notifier).restoreSession(deleted);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failed)));
        }
        return;
      }
    }
  }
}

/// Watches the session list so a price change shows up immediately.
class _SessionDetails extends ConsumerWidget {
  const _SessionDetails({required this.id, required this.onDelete});

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
    final format = DateFormat.yMd(context.localeName).add_Hms();
    final pace = session.tapsPerMinute;
    final price = session.priceCents;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sessionDetails,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(l10n.startedLabel(format.format(session.startedAt))),
            Text(l10n.endedLabel(format.format(session.endedAt))),
            Text(l10n.countLabel(session.count)),
            Text(
              l10n.durationLabel(formatSessionSeconds(session.durationSeconds)),
            ),
            if (pace != null)
              Text(
                l10n.paceLabel(
                  NumberFormat('0.0', context.localeName).format(pace),
                ),
              ),
            if (price != null)
              Text(l10n.priceLabel(formatMoney(context, price))),
            if (!session.isInLifetime(epoch)) ...[
              const SizedBox(height: 12),
              Text(
                l10n.beforeResetDetail,
                style: TextStyle(color: context.colors.textMuted),
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _editPrice(context, ref, session),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(price == null ? l10n.setPrice : l10n.editPrice),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteSessionTooltip),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.danger,
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
          border: const OutlineInputBorder(),
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
