import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';

class CounterState {
  final int count;
  final DateTime? startedAt;

  CounterState({required this.count, this.startedAt});
}

class CounterNotifier extends StateNotifier<CounterState> {
  final Ref ref;

  CounterNotifier(this.ref) : super(CounterState(count: 0)) {
    _restoreOngoing();
  }

  // Restore any unsaved session persisted before the app was closed.
  void _restoreOngoing() {
    final repo = ref.read(storageProvider);
    final count = repo.getOngoingCount();
    if (count > 0) {
      state = CounterState(count: count, startedAt: repo.getOngoingStartedAt());
    }
  }

  void _persistOngoing() {
    ref.read(storageProvider).saveOngoingSession(state.count, state.startedAt);
  }

  void increment() {
    state = CounterState(
      count: state.count + 1,
      startedAt: state.startedAt ?? DateTime.now(),
    );
    _persistOngoing();
  }

  void decrement() {
    if (state.count > 0) {
      state = CounterState(
        count: state.count - 1,
        startedAt: state.startedAt,
      );
      _persistOngoing();
    }
  }

  void resetCurrent() {
    state = CounterState(count: 0, startedAt: null);
    _persistOngoing();
  }

  Future<void> endSession() async {
    if (state.count == 0) return;

    final repo = ref.read(storageProvider);
    final endedAt = DateTime.now();
    final startedAt = state.startedAt ?? endedAt;
    final duration = endedAt.difference(startedAt).inSeconds;

    final session = Session(
      id: const Uuid().v4(),
      startedAt: startedAt,
      endedAt: endedAt,
      count: state.count,
      durationSeconds: duration,
    );

    // Save session via repository
    await repo.saveSession(session);

    // Update global lifetime stats via its provider
    await ref.read(globalStateProvider.notifier).updateGlobal(state.count);

    // Notify session list provider to reload
    ref.read(sessionListProvider.notifier).reload();

    // Reset local counter state
    resetCurrent();
  }
}

final counterProvider = StateNotifierProvider<CounterNotifier, CounterState>((ref) {
  return CounterNotifier(ref);
});

