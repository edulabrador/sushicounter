import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';

class CounterState {
  final int count;
  final DateTime? startedAt;
  final bool isEnding;
  final bool isPersisting;
  final bool isCompletionPending;
  final String? persistenceError;

  CounterState({
    required this.count,
    this.startedAt,
    this.isEnding = false,
    this.isPersisting = false,
    this.isCompletionPending = false,
    this.persistenceError,
  });

  bool get canEdit => !isEnding && !isPersisting && !isCompletionPending;
}

class CounterNotifier extends StateNotifier<CounterState> {
  final Ref ref;
  Session? _pendingSession;

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
    final count = state.count;
    final startedAt = state.startedAt;
    unawaited(_saveOngoing(count, startedAt));
  }

  Future<void> _saveOngoing(int count, DateTime? startedAt) async {
    try {
      await ref.read(storageProvider).saveOngoingSession(count, startedAt);
    } catch (_) {
      if (mounted &&
          state.canEdit &&
          state.count == count &&
          state.startedAt == startedAt) {
        state = CounterState(
          count: count,
          startedAt: startedAt,
          persistenceError: 'Could not save the current session.',
        );
      }
    }
  }

  void increment() {
    if (!state.canEdit) return;
    state = CounterState(
      count: state.count + 1,
      startedAt: state.startedAt ?? DateTime.now(),
    );
    _persistOngoing();
  }

  void decrement() {
    if (state.canEdit && state.count > 0) {
      final count = state.count - 1;
      state = CounterState(
        count: count,
        startedAt: count == 0 ? null : state.startedAt,
      );
      _persistOngoing();
    }
  }

  Future<void> resetCurrent() async {
    if (!state.canEdit) return;
    final previous = state;
    state = CounterState(
      count: previous.count,
      startedAt: previous.startedAt,
      isPersisting: true,
    );
    try {
      await ref.read(storageProvider).saveOngoingSession(0, null);
      if (mounted) state = CounterState(count: 0);
    } catch (_) {
      if (mounted) {
        state = CounterState(
          count: previous.count,
          startedAt: previous.startedAt,
          persistenceError: 'Could not reset the current session.',
        );
      }
      rethrow;
    }
  }

  Future<void> endSession() async {
    if (state.isEnding || state.isPersisting || state.count == 0) return;
    state = CounterState(
      count: state.count,
      startedAt: state.startedAt,
      isEnding: true,
    );
    try {
      final endedAt = DateTime.now();
      final startedAt = state.startedAt ?? endedAt;
      final rawDuration = endedAt.difference(startedAt).inSeconds;
      final duration = rawDuration < 0 ? 0 : rawDuration;
      final session = _pendingSession ??= Session(
        id: const Uuid().v4(),
        startedAt: startedAt,
        endedAt: endedAt,
        count: state.count,
        durationSeconds: duration,
      );

      await ref.read(storageProvider).completeSession(session);
      if (!mounted) return;
      ref.read(globalStateProvider.notifier).reload();
      ref.read(sessionListProvider.notifier).reload();
      state = CounterState(count: 0);
      _pendingSession = null;
    } catch (_) {
      if (mounted) {
        state = CounterState(
          count: state.count,
          startedAt: state.startedAt,
          isCompletionPending: true,
          persistenceError: 'Could not save this session. Please try again.',
        );
      }
      rethrow;
    }
  }
}

final counterProvider = StateNotifierProvider<CounterNotifier, CounterState>((
  ref,
) {
  return CounterNotifier(ref);
});
