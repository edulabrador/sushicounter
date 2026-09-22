import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

  Future<Session?> deleteSession(String id) async {
    final session = await ref.read(storageProvider).deleteSessionWithTotals(id);
    if (session == null) return null;
    if (!mounted) return null;
    ref.read(globalStateProvider.notifier).reload();
    reload();
    return session;
  }

  Future<void> restoreSession(Session session) async {
    await ref.read(storageProvider).restoreSessionWithTotals(session);
    if (!mounted) return;
    ref.read(globalStateProvider.notifier).reload();
    reload();
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, List<Session>>((ref) {
      return SessionListNotifier(ref);
    });
