import 'package:flutter/material.dart';
import 'package:sushiscore/core/models/session.dart';
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
                style: const TextStyle(color: Colors.white54),
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
                    color: inLifetime ? Colors.orange : Colors.white38,
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
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: l10n.deleteSessionTooltip,
                          onPressed: _deleting
                              ? null
                              : () => _deleteSession(session.id),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _showDetails(session, inLifetime),
                );
              },
            ),
    );
  }

  void _showDetails(Session session, bool inLifetime) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final format = DateFormat.yMd(sheetContext.localeName).add_Hms();
        final pace = session.tapsPerMinute;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sessionDetails,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.startedLabel(format.format(session.startedAt))),
                Text(l10n.endedLabel(format.format(session.endedAt))),
                Text(l10n.countLabel(session.count)),
                Text(
                  l10n.durationLabel(
                    formatSessionSeconds(session.durationSeconds),
                  ),
                ),
                if (pace != null)
                  Text(
                    l10n.paceLabel(
                      NumberFormat('0.0', sheetContext.localeName).format(pace),
                    ),
                  ),
                if (!inLifetime) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.beforeResetDetail,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _deleteSession(session.id);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.deleteSessionTooltip),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
