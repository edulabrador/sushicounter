import 'package:flutter_riverpod/legacy.dart';
import '../../../core/storage/hive_repository.dart';
import '../../../core/models/global_state.dart';
import '../../../core/providers/storage_provider.dart';

class GlobalStateNotifier extends StateNotifier<GlobalState> {
  final HiveRepository repository;

  GlobalStateNotifier(this.repository) : super(repository.getGlobalState());

  Future<void> resetGlobal() async {
    await repository.resetGlobalState();
    if (!mounted) return;
    state = repository.getGlobalState();
  }

  void reload() => state = repository.getGlobalState();
}

final globalStateProvider =
    StateNotifierProvider<GlobalStateNotifier, GlobalState>((ref) {
      final repository = ref.watch(storageProvider);
      return GlobalStateNotifier(repository);
    });
