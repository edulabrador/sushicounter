import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:intl/intl.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SESSION HISTORY')),
      body: sessions.isEmpty
          ? const Center(child: Text('No sessions yet.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final dateStr = DateFormat('MMM dd, yyyy - HH:mm').format(session.endedAt);
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: Text(dateStr),
                  subtitle: Text('Duration: ${session.durationSeconds}s'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${session.count}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteSession(context, ref, session.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Session Detail View (Minimal)
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Session Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Text('Started: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startedAt)}'),
                            Text('Ended: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endedAt)}'),
                            Text('Count: ${session.count} taps'),
                            Text('Duration: ${session.durationSeconds} seconds'),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _deleteSession(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'This will remove it from history and subtract its taps from your Global total.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    final deleted = await ref.read(sessionListProvider.notifier).deleteSession(id);
    if (deleted == null || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Session deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(sessionListProvider.notifier).restoreSession(deleted);
            },
          ),
        ),
      );
  }
}
