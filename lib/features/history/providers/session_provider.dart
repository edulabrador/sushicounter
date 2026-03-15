import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';

class SessionListNotifier extends StateNotifier<List<Session>> {
  final Ref ref;

  SessionListNotifier(this.ref) : super([]) {
    reload();
  }

  void reload() {
    state = ref.read(storageProvider).getAllSessions();
  }

  Future<void> deleteSession(String id) async {
    await ref.read(storageProvider).deleteSession(id);
    reload();
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, List<Session>>((ref) {
  return SessionListNotifier(ref);
});
