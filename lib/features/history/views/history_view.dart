import 'package:flutter/material.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/stats/providers/records_provider.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/widgets/empty_state.dart';
import 'package:sushiscore/features/history/history_entries.dart';
import 'package:sushiscore/features/history/widgets/session_card.dart';
import 'package:sushiscore/features/history/widgets/session_details_sheet.dart';

export 'package:sushiscore/features/history/history_entries.dart';

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
    final best = ref.watch(lifetimeBestProvider);
    final entries = historyEntries(sessions);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: sessions.isEmpty
          ? EmptyState(title: l10n.noSessions, hint: l10n.emptyHistoryHint)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: entries.length,
              itemBuilder: (context, index) => switch (entries[index]) {
                MonthHeader header => MonthHeaderTile(header: header),
                SessionEntry(:final session) => SessionCard(
                  session: session,
                  inLifetime: session.isInLifetime(epoch),
                  isRecord:
                      best > 0 &&
                      session.count == best &&
                      session.isInLifetime(epoch),
                  deleting: _deleting,
                  onTap: () => _showDetails(session.id),
                  onDelete: () => _deleteSession(session.id),
                ),
              },
            ),
    );
  }

  void _showDetails(String id) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (_) => SessionDetailsSheet(
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
