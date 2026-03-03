import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/hive_repository.dart';
import '../../core/models/global_state.dart';
import '../../core/providers/storage_provider.dart';

class GlobalStateNotifier extends StateNotifier<GlobalState> {
  final HiveRepository repository;

  GlobalStateNotifier(this.repository) : super(repository.getGlobalState());

  Future<void> updateGlobal(int additionalTaps) async {
    await repository.updateGlobalState(additionalTaps);
    state = repository.getGlobalState(); // Update state to trigger rebuilds
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
