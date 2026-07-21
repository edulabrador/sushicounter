import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_repository.dart';
import '../../../core/models/global_state.dart';
import '../../../core/providers/storage_provider.dart';

class GlobalStateNotifier extends StateNotifier<GlobalState> {
  final HiveRepository repository;

  GlobalStateNotifier(this.repository) : super(repository.getGlobalState());

  Future<void> updateGlobal(int additionalTaps) async {
    await repository.updateGlobalState(additionalTaps);
    state = repository.getGlobalState(); // Update state to trigger rebuilds
  }

  // Applies signed deltas — used when deleting a session (negative delta).
  Future<void> applyDelta(int tapsDelta, int sessionsDelta) async {
    await repository.adjustGlobalState(
      tapsDelta: tapsDelta,
      sessionsDelta: sessionsDelta,
    );
    state = repository.getGlobalState();
  }

  // Restores the totals to an exact captured snapshot. Used to undo a deletion
  // losslessly (idempotent, so a repeated undo is harmless).
  Future<void> restoreState(GlobalState snapshot) async {
    await repository.setGlobalState(
      snapshot.lifetimeTotalTaps,
      snapshot.lifetimeTotalSessions,
    );
    state = repository.getGlobalState();
  }

  Future<void> resetGlobal() async {
    await repository.resetGlobalState();
    state = repository.getGlobalState();
  }
}

final globalStateProvider = StateNotifierProvider<GlobalStateNotifier, GlobalState>((ref) {
  final repository = ref.watch(storageProvider);
  return GlobalStateNotifier(repository);
});
