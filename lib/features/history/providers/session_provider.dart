import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';

class SessionListNotifier extends Notifier<List<Session>> {
  @override
  List<Session> build() => ref.watch(storageProvider).getAllSessions();

  void reload() {
    state = ref.read(storageProvider).getAllSessions();
  }

  Future<DeletedSession?> deleteSession(String id) async {
    final deleted = await ref.read(storageProvider).deleteSessionWithTotals(id);
    if (deleted == null || !ref.mounted) return null;
    ref.read(globalStateProvider.notifier).reload();
    reload();
    return deleted;
  }

  Future<void> restoreSession(DeletedSession deleted) async {
    await ref.read(storageProvider).restoreSessionWithTotals(deleted);
    if (!ref.mounted) return;
    ref.read(globalStateProvider.notifier).reload();
    reload();
  }
}

final sessionListProvider =
    NotifierProvider<SessionListNotifier, List<Session>>(
      SessionListNotifier.new,
    );
