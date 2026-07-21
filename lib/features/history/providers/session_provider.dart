import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/models/global_state.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';

// Everything needed to undo a deletion losslessly: the removed session plus a
// snapshot of the global totals as they were *before* the delete. Restoring the
// snapshot (rather than re-adding a delta) is exact even when the delete's
// subtraction was clamped at zero.
class DeletedSession {
  const DeletedSession(this.session, this.globalBefore);

  final Session session;
  final GlobalState globalBefore;
}

class SessionListNotifier extends StateNotifier<List<Session>> {
  final Ref ref;

  SessionListNotifier(this.ref) : super([]) {
    reload();
  }

  void reload() {
    state = ref.read(storageProvider).getAllSessions();
  }

  // Deletes a session and subtracts its taps from the global lifetime totals.
  // Returns the deleted session plus the pre-delete global snapshot so the UI
  // can offer a lossless undo.
  Future<DeletedSession?> deleteSession(String id) async {
    final matches = state.where((s) => s.id == id);
    if (matches.isEmpty) return null;
    final session = matches.first;
    final globalBefore = ref.read(storageProvider).getGlobalState();

    await ref.read(storageProvider).deleteSession(id);
    await ref
        .read(globalStateProvider.notifier)
        .applyDelta(-session.count, -1);
    reload();
    return DeletedSession(session, globalBefore);
  }

  // Re-inserts a previously deleted session and restores the global totals to
  // their exact pre-delete snapshot. Rebuilds the Session so the (deleted)
  // HiveObject isn't reused. Idempotent, so a repeated undo is harmless.
  Future<void> restoreSession(DeletedSession deleted) async {
    final session = deleted.session;
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
        .restoreState(deleted.globalBefore);
    reload();
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, List<Session>>((ref) {
  return SessionListNotifier(ref);
});
