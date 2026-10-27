import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
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

  /// Others at the table, counted alongside you.
  final List<Companion> companions;
  final DateTime? startedAt;
  final CounterPhase phase;
  final bool isSavingOngoing;
  final CounterError? persistenceError;

  const CounterState({
    required this.count,
    this.companions = const [],
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
      count == 0 &&
      companions.isEmpty &&
      canEdit &&
      !isSavingOngoing &&
      persistenceError == null;

  /// Pieces at the table, yours included.
  int get tableTotal => count + companionsTotal(companions);

  CounterState copyWith({
    int? count,
    List<Companion>? companions,
    Object? startedAt = _keep,
    CounterPhase? phase,
    bool? isSavingOngoing,
    Object? persistenceError = _keep,
  }) => CounterState(
    count: count ?? this.count,
    companions: companions ?? this.companions,
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
      listEquals(other.companions, companions) &&
      other.startedAt == startedAt &&
      other.phase == phase &&
      other.isSavingOngoing == isSavingOngoing &&
      other.persistenceError == persistenceError;

  @override
  int get hashCode => Object.hash(
    count,
    Object.hashAll(companions),
    startedAt,
    phase,
    isSavingOngoing,
    persistenceError,
  );
}

class CounterNotifier extends Notifier<CounterState> {
  Session? _pendingSession;
  int _ongoingWrites = 0;

  // Restore any unsaved session persisted before the app was closed.
  @override
  CounterState build() {
    final repo = ref.read(storageProvider);
    final count = repo.getOngoingCount();
    final companions = repo.getOngoingCompanions();
    if (count <= 0 && companions.isEmpty) return const CounterState(count: 0);
    final anyPieces = count > 0 || companionsTotal(companions) > 0;
    // Older installs could persist a count without a start time.
    return CounterState(
      count: count < 0 ? 0 : count,
      companions: companions,
      startedAt: anyPieces ? repo.getOngoingStartedAt() ?? clock.now() : null,
    );
  }

  void _persistOngoing() {
    unawaited(_saveOngoing(state.count, state.startedAt, state.companions));
  }

  Future<void> _saveOngoing(
    int count,
    DateTime? startedAt,
    List<Companion> companions,
  ) async {
    _ongoingWrites++;
    _setSavingOngoing(true);
    try {
      await ref
          .read(storageProvider)
          .saveOngoingSession(count, startedAt, companions: companions);
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
      startedAt: state.startedAt ?? clock.now(),
    );
    _persistOngoing();
  }

  void decrement() {
    if (!state.canEdit || state.count == 0) return;
    _apply(state.copyWith(count: state.count - 1));
  }

  /// Applies [next], keeping the timer running while anyone at the table
  /// has pieces and stopping it when the table is back to zero.
  void _apply(CounterState next) {
    state = next.copyWith(
      startedAt: next.tableTotal == 0 ? null : next.startedAt ?? clock.now(),
    );
    _persistOngoing();
  }

  /// Adds someone to the table. Returns false for a blank or repeated name
  /// or a full table.
  bool addCompanion(String name) {
    final normalized = Companion.normalizeName(name);
    if (!state.canEdit ||
        normalized == null ||
        normalized.length > Companion.maxNameLength ||
        state.companions.length >= Companion.maxPerTable ||
        state.companions.any(
          (c) => c.name.toLowerCase() == normalized.toLowerCase(),
        )) {
      return false;
    }
    _apply(
      state.copyWith(
        companions: [
          ...state.companions,
          Companion(name: normalized),
        ],
      ),
    );
    return true;
  }

  void removeCompanion(int index) {
    if (!state.canEdit || index < 0 || index >= state.companions.length) {
      return;
    }
    _apply(state.copyWith(companions: [...state.companions]..removeAt(index)));
  }

  void incrementCompanion(int index) => _changeCompanion(index, 1);
  void decrementCompanion(int index) => _changeCompanion(index, -1);

  void _changeCompanion(int index, int delta) {
    if (!state.canEdit || index < 0 || index >= state.companions.length) {
      return;
    }
    final companion = state.companions[index];
    final count = companion.count + delta;
    if (count < 0 || count > Session.maxCount) return;
    final companions = [...state.companions];
    companions[index] = companion.copyWith(count: count);
    _apply(state.copyWith(companions: companions));
  }

  /// Clears the current session without saving it. Also the way out of a
  /// session whose save keeps failing.
  ///
  /// Returns true when the session turned out to be in history anyway: a
  /// save interrupted after its journal was written is completed by journal
  /// recovery before this write runs, and keeping the data beats losing it.
  Future<bool> resetCurrent() async {
    if (!state.canDiscard) return false;
    final previous = state;
    final pendingId = _pendingSession?.id;
    state = state.copyWith(phase: CounterPhase.persisting);
    try {
      final repo = ref.read(storageProvider);
      await repo.saveOngoingSession(0, null);
      _pendingSession = null;
      final alreadySaved =
          pendingId != null &&
          repo.getAllSessions().any((session) => session.id == pendingId);
      if (!ref.mounted) return alreadySaved;
      state = CounterState(count: 0, isSavingOngoing: _ongoingWrites > 0);
      ref.read(globalStateProvider.notifier).reload();
      ref.read(sessionListProvider.notifier).reload();
      return alreadySaved;
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
      final endedAt = clock.now();
      final startedAt = state.startedAt ?? endedAt;
      final rawDuration = endedAt.difference(startedAt).inSeconds;
      final duration = rawDuration < 0 ? 0 : rawDuration;
      final session = _pendingSession ??= Session(
        id: const Uuid().v4(),
        startedAt: startedAt,
        endedAt: endedAt,
        count: state.count,
        durationSeconds: duration,
        companions: state.companions,
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

/// The counter as its screen shows it. The background-save flag only gates
/// the lifetime reset in Settings, so dropping it here spares the counter
/// two extra rebuilds on every tap (the flag turns on, then off).
CounterState counterOnScreen(CounterState state) =>
    state.isSavingOngoing ? state.copyWith(isSavingOngoing: false) : state;

/// Saved lifetime taps plus the active session, so every screen agrees.
final lifetimeTapsProvider = Provider<int>(
  (ref) =>
      ref.watch(globalStateProvider).lifetimeTotalTaps +
      ref.watch(counterProvider.select((state) => state.count)),
);
