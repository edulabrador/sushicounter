import 'package:flutter/material.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:intl/intl.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({super.key});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SESSION HISTORY')),
      body: sessions.isEmpty
          ? const Center(
              child: Text(
                'No sessions yet.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final dateStr = DateFormat('MMM dd, yyyy - HH:mm')
                    .format(session.endedAt);
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: Text(
                    dateStr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Duration: ${session.durationSeconds}s'),
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
                          tooltip: 'Delete session',
                          onPressed: _deleting
                              ? null
                              : () => _deleteSession(session.id),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // Session Detail View (Minimal)
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Session Details',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Started: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startedAt)}',
                              ),
                              Text(
                                'Ended: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endedAt)}',
                              ),
                              Text('Count: ${session.count} taps'),
                              Text(
                                'Duration: ${session.durationSeconds} seconds',
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _deleteSession(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'This removes it from history. It updates the lifetime total when it belongs to the current lifetime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Session deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _restoreSession(deleted),
            ),
          ),
        );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this session. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _restoreSession(Session deleted) async {
    try {
      await ref.read(sessionListProvider.notifier).restoreSession(deleted);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not restore this session.')),
        );
      }
    }
  }
}
