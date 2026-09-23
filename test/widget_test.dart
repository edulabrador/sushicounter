import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/global_state.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';

/// In-memory repository so tests don't need a real Hive database.
class FakeRepository extends HiveRepository {
  final Map<String, Session> sessions = {};
  GlobalState _global = GlobalState(
    lifetimeTotalTaps: 0,
    lifetimeTotalSessions: 0,
  );
  int _ongoingCount = 0;
  DateTime? _ongoingStartedAt;

  @override
  List<Session> getAllSessions() =>
      sessions.values.toList()..sort((a, b) => b.endedAt.compareTo(a.endedAt));

  @override
  GlobalState getGlobalState() => GlobalState(
    lifetimeTotalTaps: _global.lifetimeTotalTaps,
    lifetimeTotalSessions: _global.lifetimeTotalSessions,
    epoch: _global.epoch,
  );

  Future<void> adjustGlobalState({
    required int tapsDelta,
    required int sessionsDelta,
  }) async {
    final taps = _global.lifetimeTotalTaps + tapsDelta;
    final sessions = _global.lifetimeTotalSessions + sessionsDelta;
    _global = GlobalState(
      lifetimeTotalTaps: taps < 0 ? 0 : taps,
      lifetimeTotalSessions: sessions < 0 ? 0 : sessions,
      epoch: _global.epoch,
    );
  }

  @override
  Future<void> resetGlobalState() async {
    _global = GlobalState(
      lifetimeTotalTaps: 0,
      lifetimeTotalSessions: 0,
      epoch: _global.epoch + 1,
    );
  }

  @override
  Future<Session> completeSession(Session session) async {
    final existing = sessions[session.id];
    if (existing != null) return existing;
    final recorded = Session(
      id: session.id,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      count: session.count,
      durationSeconds: session.durationSeconds,
      contributionEpoch: _global.epoch,
    );
    sessions[recorded.id] = recorded;
    await adjustGlobalState(tapsDelta: recorded.count, sessionsDelta: 1);
    await saveOngoingSession(0, null);
    return recorded;
  }

  @override
  Future<Session?> deleteSessionWithTotals(String id) async {
    final session = sessions.remove(id);
    if (session != null && session.contributionEpoch == _global.epoch) {
      await adjustGlobalState(tapsDelta: -session.count, sessionsDelta: -1);
    }
    return session;
  }

  @override
  Future<void> restoreSessionWithTotals(Session session) async {
    if (sessions.containsKey(session.id)) return;
    sessions[session.id] = session;
    if (session.contributionEpoch == _global.epoch) {
      await adjustGlobalState(tapsDelta: session.count, sessionsDelta: 1);
    }
  }

  @override
  int getOngoingCount() => _ongoingCount;

  @override
  DateTime? getOngoingStartedAt() => _ongoingStartedAt;

  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) async {
    _ongoingCount = count;
    _ongoingStartedAt = startedAt;
  }
}

class DelayedResetRepository extends FakeRepository {
  final resetGate = Completer<void>();
  int resetWrites = 0;

  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) async {
    if (count == 0) {
      resetWrites++;
      await resetGate.future;
    }
    await super.saveOngoingSession(count, startedAt);
  }
}

class DelayedOngoingRepository extends FakeRepository {
  final writeGate = Completer<void>();

  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) async {
    await writeGate.future;
    await super.saveOngoingSession(count, startedAt);
  }
}

ProviderContainer makeContainer(FakeRepository repo) {
  final container = ProviderContainer(
    overrides: [storageProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CounterNotifier', () {
    test('pending writes do not publish an unchanged saving state', () async {
      final repo = DelayedOngoingRepository();
      final container = makeContainer(repo);
      final states = <CounterState>[];
      final subscription = container.listen(
        counterProvider,
        (_, next) => states.add(next),
      );
      addTearDown(subscription.close);
      final notifier = container.read(counterProvider.notifier);

      notifier.increment();
      notifier.increment();

      expect(states.map((state) => state.count), [1, 1, 2]);
      expect(states.last.isSavingOngoing, isTrue);

      repo.writeGate.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(counterProvider).isSavingOngoing, isFalse);
    });

    test('pending reset blocks edits and completion', () async {
      final repo = DelayedResetRepository();
      final container = makeContainer(repo);
      final notifier = container.read(counterProvider.notifier);
      notifier.increment();
      final reset = notifier.resetCurrent();

      notifier.increment();
      notifier.decrement();
      await notifier.endSession();
      await notifier.resetCurrent();
      expect(container.read(counterProvider).count, 1);
      expect(container.read(counterProvider).canEdit, isFalse);
      expect(repo.sessions, isEmpty);
      expect(repo.resetWrites, 1);

      repo.resetGate.complete();
      await reset;
      expect(container.read(counterProvider).count, 0);
      expect(container.read(counterProvider).canEdit, isTrue);
      expect(repo.getOngoingCount(), 0);
    });

    test('increment increases count and sets startedAt', () {
      final container = makeContainer(FakeRepository());
      final notifier = container.read(counterProvider.notifier);

      notifier.increment();
      notifier.increment();

      final state = container.read(counterProvider);
      expect(state.count, 2);
      expect(state.startedAt, isNotNull);
    });

    test('decrement never goes below zero', () {
      final container = makeContainer(FakeRepository());
      final notifier = container.read(counterProvider.notifier);

      notifier.decrement();
      expect(container.read(counterProvider).count, 0);

      notifier.increment();
      notifier.decrement();
      notifier.decrement();
      expect(container.read(counterProvider).count, 0);
    });

    test('decrementing to zero starts the next session fresh', () {
      final container = makeContainer(FakeRepository());
      final notifier = container.read(counterProvider.notifier);

      notifier.increment();
      notifier.decrement();
      expect(container.read(counterProvider).startedAt, isNull);
    });

    test(
      'endSession saves session, updates global stats and resets counter',
      () async {
        final repo = FakeRepository();
        final container = makeContainer(repo);
        final notifier = container.read(counterProvider.notifier);

        notifier.increment();
        notifier.increment();
        notifier.increment();
        await notifier.endSession();

        expect(repo.sessions.length, 1);
        expect(repo.sessions.values.first.count, 3);
        expect(container.read(counterProvider).count, 0);

        final global = container.read(globalStateProvider);
        expect(global.lifetimeTotalTaps, 3);
        expect(global.lifetimeTotalSessions, 1);
      },
    );

    test('concurrent end requests create one session', () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      final notifier = container.read(counterProvider.notifier);
      notifier.increment();

      await Future.wait([notifier.endSession(), notifier.endSession()]);

      expect(repo.sessions, hasLength(1));
      expect(container.read(globalStateProvider).lifetimeTotalSessions, 1);
    });

    test('endSession with zero taps does nothing', () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);

      await container.read(counterProvider.notifier).endSession();

      expect(repo.sessions, isEmpty);
      expect(container.read(globalStateProvider).lifetimeTotalSessions, 0);
    });

    test('ongoing session is persisted and restored', () {
      final repo = FakeRepository();
      final container = makeContainer(repo);

      container.read(counterProvider.notifier).increment();
      container.read(counterProvider.notifier).increment();
      expect(repo.getOngoingCount(), 2);

      // Simulate an app restart: a new container reading the same repo.
      final container2 = makeContainer(repo);
      expect(container2.read(counterProvider).count, 2);
    });
  });

  group('GlobalStateNotifier', () {
    test('reload notifies listeners with fresh state', () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      final states = <GlobalState>[];
      container.listen(globalStateProvider, (_, next) => states.add(next));

      await repo.adjustGlobalState(tapsDelta: 5, sessionsDelta: 1);
      container.read(globalStateProvider.notifier).reload();

      expect(states, hasLength(1));
      expect(states.single.lifetimeTotalTaps, 5);
    });

    test('resetGlobal notifies listeners and zeroes totals', () async {
      final container = makeContainer(FakeRepository());
      final repo = container.read(storageProvider) as FakeRepository;
      await repo.adjustGlobalState(tapsDelta: 5, sessionsDelta: 1);

      final states = <GlobalState>[];
      container.listen(globalStateProvider, (_, next) => states.add(next));
      await container.read(globalStateProvider.notifier).resetGlobal();

      expect(states, hasLength(1));
      expect(states.single.lifetimeTotalTaps, 0);
      expect(states.single.lifetimeTotalSessions, 0);
    });
  });

  group('SessionListNotifier', () {
    test('deleteSession removes it from the list', () async {
      final repo = FakeRepository();
      final now = DateTime.now();
      repo.sessions['a'] = Session(
        id: 'a',
        startedAt: now,
        endedAt: now,
        count: 1,
        durationSeconds: 0,
      );
      final container = makeContainer(repo);

      expect(container.read(sessionListProvider), hasLength(1));
      await container.read(sessionListProvider.notifier).deleteSession('a');
      expect(container.read(sessionListProvider), isEmpty);
    });

    test('deleteSession subtracts its taps from the global total', () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      // Two sessions of 3 and 2 taps -> global 5 taps / 2 sessions.
      final now = DateTime.now();
      repo.sessions['a'] = Session(
        id: 'a',
        startedAt: now,
        endedAt: now,
        count: 3,
        durationSeconds: 0,
      );
      repo.sessions['b'] = Session(
        id: 'b',
        startedAt: now,
        endedAt: now,
        count: 2,
        durationSeconds: 0,
      );
      await repo.adjustGlobalState(tapsDelta: 5, sessionsDelta: 2);
      container.read(sessionListProvider.notifier).reload();

      final deleted = await container
          .read(sessionListProvider.notifier)
          .deleteSession('a');

      expect(deleted, isNotNull);
      final global = container.read(globalStateProvider);
      expect(global.lifetimeTotalTaps, 2); // 5 - 3
      expect(global.lifetimeTotalSessions, 1); // 2 - 1
    });

    test(
      'restoreSession re-adds the session and its taps to the global',
      () async {
        final repo = FakeRepository();
        final container = makeContainer(repo);
        final now = DateTime.now();
        repo.sessions['a'] = Session(
          id: 'a',
          startedAt: now,
          endedAt: now,
          count: 3,
          durationSeconds: 0,
        );
        await repo.adjustGlobalState(tapsDelta: 3, sessionsDelta: 1);
        container.read(sessionListProvider.notifier).reload();

        final deleted = await container
            .read(sessionListProvider.notifier)
            .deleteSession('a');
        expect(container.read(sessionListProvider), isEmpty);
        expect(container.read(globalStateProvider).lifetimeTotalTaps, 0);

        await container
            .read(sessionListProvider.notifier)
            .restoreSession(deleted!);

        expect(container.read(sessionListProvider), hasLength(1));
        final global = container.read(globalStateProvider);
        expect(global.lifetimeTotalTaps, 3);
        expect(global.lifetimeTotalSessions, 1);
      },
    );

    test(
      'deleting after a global reset never drives the total negative',
      () async {
        final repo = FakeRepository();
        final container = makeContainer(repo);
        final now = DateTime.now();
        repo.sessions['a'] = Session(
          id: 'a',
          startedAt: now,
          endedAt: now,
          count: 5,
          durationSeconds: 0,
        );
        await repo.adjustGlobalState(tapsDelta: 5, sessionsDelta: 1);
        // Global reset preserves history but zeroes lifetime totals.
        await container.read(globalStateProvider.notifier).resetGlobal();
        container.read(sessionListProvider.notifier).reload();

        await container.read(sessionListProvider.notifier).deleteSession('a');

        final global = container.read(globalStateProvider);
        expect(global.lifetimeTotalTaps, 0);
        expect(global.lifetimeTotalSessions, 0);
      },
    );

    test(
      'undo after a clamped delete restores the exact pre-delete global',
      () async {
        final repo = FakeRepository();
        final container = makeContainer(repo);
        final now = DateTime.now();
        repo.sessions['a'] = Session(
          id: 'a',
          startedAt: now,
          endedAt: now,
          count: 5,
          durationSeconds: 0,
        );
        await repo.adjustGlobalState(tapsDelta: 5, sessionsDelta: 1);
        // Global reset zeroes the totals but keeps the session in history.
        await container.read(globalStateProvider.notifier).resetGlobal();
        container.read(sessionListProvider.notifier).reload();

        // Delete clamps the global at 0 (can't subtract 5 from 0)...
        final deleted = await container
            .read(sessionListProvider.notifier)
            .deleteSession('a');
        expect(container.read(globalStateProvider).lifetimeTotalTaps, 0);

        // ...and undo must return to the exact pre-delete state (0), NOT +5.
        await container
            .read(sessionListProvider.notifier)
            .restoreSession(deleted!);

        final global = container.read(globalStateProvider);
        expect(global.lifetimeTotalTaps, 0);
        expect(global.lifetimeTotalSessions, 0);
        expect(container.read(sessionListProvider), hasLength(1));
      },
    );

    test(
      'undo is idempotent (repeated undo does not inflate the global)',
      () async {
        final repo = FakeRepository();
        final container = makeContainer(repo);
        final now = DateTime.now();
        repo.sessions['a'] = Session(
          id: 'a',
          startedAt: now,
          endedAt: now,
          count: 3,
          durationSeconds: 0,
        );
        await repo.adjustGlobalState(tapsDelta: 3, sessionsDelta: 1);
        container.read(sessionListProvider.notifier).reload();

        final deleted = await container
            .read(sessionListProvider.notifier)
            .deleteSession('a');
        await container
            .read(sessionListProvider.notifier)
            .restoreSession(deleted!);
        await container
            .read(sessionListProvider.notifier)
            .restoreSession(deleted);

        final global = container.read(globalStateProvider);
        expect(global.lifetimeTotalTaps, 3);
        expect(global.lifetimeTotalSessions, 1);
        expect(container.read(sessionListProvider), hasLength(1));
      },
    );

    test('undo preserves sessions completed after the delete', () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      final now = DateTime.now();
      final original = Session(
        id: 'original',
        startedAt: now,
        endedAt: now,
        count: 3,
        durationSeconds: 0,
      );
      await repo.completeSession(original);
      container.read(globalStateProvider.notifier).reload();
      container.read(sessionListProvider.notifier).reload();

      final deleted = await container
          .read(sessionListProvider.notifier)
          .deleteSession(original.id);
      await repo.completeSession(
        Session(
          id: 'later',
          startedAt: now,
          endedAt: now,
          count: 2,
          durationSeconds: 0,
        ),
      );
      await container
          .read(sessionListProvider.notifier)
          .restoreSession(deleted!);

      final global = repo.getGlobalState();
      expect(global.lifetimeTotalTaps, 5);
      expect(global.lifetimeTotalSessions, 2);
    });
  });
}
