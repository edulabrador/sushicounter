import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';

/// What the counter is doing. Only [editing] accepts taps.
enum CounterPhase {
  editing,

  /// Saving the session to history.
  ending,

  /// Clearing the current session.
  persisting,

  /// Saving to history failed; the session waits for a retry or a discard.
  completionPending,
}

enum CounterError { saveOngoing, resetCurrent, completeSession }

const _keep = Object();

class CounterState {
  final int count;
  final DateTime? startedAt;
  final CounterPhase phase;
  final bool isSavingOngoing;
  final CounterError? persistenceError;

  const CounterState({
    required this.count,
    this.startedAt,
    this.phase = CounterPhase.editing,
    this.isSavingOngoing = false,
    this.persistenceError,
  });

  bool get isEnding => phase == CounterPhase.ending;
  bool get isPersisting => phase == CounterPhase.persisting;
  bool get isCompletionPending => phase == CounterPhase.completionPending;
  bool get canEdit => phase == CounterPhase.editing;

  /// The session can be thrown away when idle or stuck after a failed save.
  bool get canDiscard => canEdit || isCompletionPending;
  bool get canResetLifetime =>
      count == 0 && canEdit && !isSavingOngoing && persistenceError == null;

  CounterState copyWith({
    int? count,
    Object? startedAt = _keep,
    CounterPhase? phase,
    bool? isSavingOngoing,
    Object? persistenceError = _keep,
  }) => CounterState(
    count: count ?? this.count,
    startedAt: identical(startedAt, _keep)
        ? this.startedAt
        : startedAt as DateTime?,
    phase: phase ?? this.phase,
    isSavingOngoing: isSavingOngoing ?? this.isSavingOngoing,
    persistenceError: identical(persistenceError, _keep)
        ? this.persistenceError
        : persistenceError as CounterError?,
  );

  @override
  bool operator ==(Object other) =>
      other is CounterState &&
      other.count == count &&
      other.startedAt == startedAt &&
      other.phase == phase &&
      other.isSavingOngoing == isSavingOngoing &&
      other.persistenceError == persistenceError;

  @override
  int get hashCode =>
      Object.hash(count, startedAt, phase, isSavingOngoing, persistenceError);
}

class CounterNotifier extends Notifier<CounterState> {
  Session? _pendingSession;
  int _ongoingWrites = 0;

  // Restore any unsaved session persisted before the app was closed.
  @override
  CounterState build() {
    final repo = ref.read(storageProvider);
    final count = repo.getOngoingCount();
    if (count <= 0) return const CounterState(count: 0);
    // Older installs could persist a count without a start time.
    return CounterState(
      count: count,
      startedAt: repo.getOngoingStartedAt() ?? DateTime.now(),
    );
  }

  void _persistOngoing() {
    unawaited(_saveOngoing(state.count, state.startedAt));
  }

  Future<void> _saveOngoing(int count, DateTime? startedAt) async {
    _ongoingWrites++;
    _setSavingOngoing(true);
    try {
      await ref.read(storageProvider).saveOngoingSession(count, startedAt);
      if (_isCurrent(count, startedAt) &&
          state.persistenceError == CounterError.saveOngoing) {
        state = state.copyWith(
          isSavingOngoing: _ongoingWrites > 1,
          persistenceError: null,
        );
      }
    } catch (_) {
      if (_isCurrent(count, startedAt)) {
        state = state.copyWith(persistenceError: CounterError.saveOngoing);
      }
    } finally {
      _ongoingWrites--;
      _setSavingOngoing(_ongoingWrites > 0);
    }
  }

  /// Only the write matching what is on screen may change the error state.
  bool _isCurrent(int count, DateTime? startedAt) =>
      ref.mounted &&
      state.canEdit &&
      state.count == count &&
      state.startedAt == startedAt;

  void _setSavingOngoing(bool value) {
    if (!ref.mounted || state.isSavingOngoing == value) return;
    state = state.copyWith(isSavingOngoing: value);
  }

  void increment() {
    if (!state.canEdit) return;
    state = state.copyWith(
      count: state.count + 1,
      startedAt: state.startedAt ?? DateTime.now(),
    );
    _persistOngoing();
  }

  void decrement() {
    if (!state.canEdit || state.count == 0) return;
    final count = state.count - 1;
    state = state.copyWith(
      count: count,
      startedAt: count == 0 ? null : state.startedAt,
    );
    _persistOngoing();
  }

  /// Clears the current session without saving it. Also the way out of a
  /// session whose save keeps failing.
  Future<void> resetCurrent() async {
    if (!state.canDiscard) return;
    final previous = state;
    state = state.copyWith(phase: CounterPhase.persisting);
    try {
      await ref.read(storageProvider).saveOngoingSession(0, null);
      _pendingSession = null;
      if (!ref.mounted) return;
      state = CounterState(count: 0, isSavingOngoing: _ongoingWrites > 0);
      // An interrupted save may have been completed by journal recovery.
      ref.read(globalStateProvider.notifier).reload();
      ref.read(sessionListProvider.notifier).reload();
    } catch (_) {
      if (ref.mounted) {
        state = previous.copyWith(
          isSavingOngoing: _ongoingWrites > 0,
          persistenceError: CounterError.resetCurrent,
        );
      }
      rethrow;
    }
  }

  Future<void> endSession() async {
    if (state.isEnding || state.isPersisting || state.count == 0) return;
    state = state.copyWith(phase: CounterPhase.ending);
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
      _pendingSession = null;
      if (!ref.mounted) return;
      ref.read(globalStateProvider.notifier).reload();
      ref.read(sessionListProvider.notifier).reload();
      state = CounterState(count: 0, isSavingOngoing: _ongoingWrites > 0);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          phase: CounterPhase.completionPending,
          persistenceError: CounterError.completeSession,
        );
      }
      rethrow;
    }
  }
}

final counterProvider = NotifierProvider<CounterNotifier, CounterState>(
  CounterNotifier.new,
);

/// Saved lifetime taps plus the active session, so every screen agrees.
final lifetimeTapsProvider = Provider<int>(
  (ref) =>
      ref.watch(globalStateProvider).lifetimeTotalTaps +
      ref.watch(counterProvider.select((state) => state.count)),
);
