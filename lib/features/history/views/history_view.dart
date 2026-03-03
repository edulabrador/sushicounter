import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/storage_provider.dart';
import '../../core/models/session.dart';
import 'package:intl/intl.dart';

class HistoryView extends ConsumerStatefulWidget {
  const HistoryView({super.key});

  @override
  ConsumerState<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<HistoryView> {
  List<Session> sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      sessions = ref.read(storageProvider).getAllSessions();
    });
  }

  void _deleteSession(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('This will remove it from history but not affect Global Totals.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(storageProvider).deleteSession(id);
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        onPressed: () => _deleteSession(session.id),
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
}
