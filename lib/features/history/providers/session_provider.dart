import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';

class SessionListNotifier extends StateNotifier<List<Session>> {
  final Ref ref;

  SessionListNotifier(this.ref) : super([]) {
    reload();
  }

  void reload() {
    state = ref.read(storageProvider).getAllSessions();
  }

  // Deletes a session and subtracts its taps from the global lifetime totals.
  // Returns the deleted session so the UI can offer an undo.
  Future<Session?> deleteSession(String id) async {
    final matches = state.where((s) => s.id == id);
    if (matches.isEmpty) return null;
    final session = matches.first;

    await ref.read(storageProvider).deleteSession(id);
    await ref
        .read(globalStateProvider.notifier)
        .applyDelta(-session.count, -1);
    reload();
    return session;
  }

  // Re-inserts a previously deleted session and adds its taps back to the global
  // totals. Rebuilds the Session so the (deleted) HiveObject isn't reused.
  Future<void> restoreSession(Session session) async {
    await ref.read(storageProvider).saveSession(
          Session(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            count: session.count,
            durationSeconds: session.durationSeconds,
          ),
        );
    await ref
        .read(globalStateProvider.notifier)
        .applyDelta(session.count, 1);
    reload();
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, List<Session>>((ref) {
  return SessionListNotifier(ref);
});
