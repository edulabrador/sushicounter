import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';

class CounterState {
  final int count;
  final DateTime? startedAt;

  CounterState({required this.count, this.startedAt});

  CounterState copyWith({int? count, DateTime? startedAt}) {
    return CounterState(
      count: count ?? this.count,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class CounterNotifier extends StateNotifier<CounterState> {
  final Ref ref;

  CounterNotifier(this.ref) : super(CounterState(count: 0));

  void increment() {
    state = CounterState(
      count: state.count + 1,
      startedAt: state.startedAt ?? DateTime.now(),
    );
  }

  void decrement() {
    if (state.count > 0) {
      state = CounterState(
        count: state.count - 1,
        startedAt: state.startedAt,
      );
    }
  }

  void resetCurrent() {
    state = CounterState(count: 0, startedAt: null);
  }

  Future<void> endSession() async {
    if (state.count == 0 || state.startedAt == null) return;

    final repo = ref.read(storageProvider);
    final endedAt = DateTime.now();
    final duration = endedAt.difference(state.startedAt!).inSeconds;

    final session = Session(
      id: const Uuid().v4(),
      startedAt: state.startedAt!,
      endedAt: endedAt,
      count: state.count,
      durationSeconds: duration,
    );

    // Save session via repository
    await repo.saveSession(session);

    // Update global lifetime stats via its provider
    await ref.read(globalStateProvider.notifier).updateGlobal(state.count);

    // Reset local counter state
    resetCurrent();
  }
}

final counterProvider = StateNotifierProvider<CounterNotifier, CounterState>((ref) {
  return CounterNotifier(ref);
});
