import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/global_state.dart';
import '../../../core/providers/storage_provider.dart';

class GlobalStateNotifier extends Notifier<GlobalState> {
  @override
  GlobalState build() => ref.watch(storageProvider).getGlobalState();

  Future<void> resetGlobal() async {
    final repository = ref.read(storageProvider);
    await repository.resetGlobalState();
    if (!ref.mounted) return;
    state = repository.getGlobalState();
  }

  void reload() => state = ref.read(storageProvider).getGlobalState();
}

final globalStateProvider = NotifierProvider<GlobalStateNotifier, GlobalState>(
  GlobalStateNotifier.new,
);
