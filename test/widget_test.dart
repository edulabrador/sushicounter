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
  GlobalState _global = GlobalState(lifetimeTotalTaps: 0, lifetimeTotalSessions: 0);
  int _ongoingCount = 0;
  DateTime? _ongoingStartedAt;

  @override
  List<Session> getAllSessions() =>
      sessions.values.toList()..sort((a, b) => b.endedAt.compareTo(a.endedAt));

  @override
  Future<void> saveSession(Session session) async {
    sessions[session.id] = session;
  }

  @override
  Future<void> deleteSession(String id) async {
    sessions.remove(id);
  }

  @override
  GlobalState getGlobalState() => GlobalState(
        lifetimeTotalTaps: _global.lifetimeTotalTaps,
        lifetimeTotalSessions: _global.lifetimeTotalSessions,
      );

  @override
  Future<void> updateGlobalState(int additionalTaps) async {
    await adjustGlobalState(tapsDelta: additionalTaps, sessionsDelta: 1);
  }

  @override
  Future<void> adjustGlobalState({
    required int tapsDelta,
    required int sessionsDelta,
  }) async {
    final taps = _global.lifetimeTotalTaps + tapsDelta;
    final sessions = _global.lifetimeTotalSessions + sessionsDelta;
    _global = GlobalState(
      lifetimeTotalTaps: taps < 0 ? 0 : taps,
      lifetimeTotalSessions: sessions < 0 ? 0 : sessions,
    );
  }

  @override
  Future<void> resetGlobalState() async {
    _global = GlobalState(lifetimeTotalTaps: 0, lifetimeTotalSessions: 0);
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

ProviderContainer makeContainer(FakeRepository repo) {
  final container = ProviderContainer(
    overrides: [storageProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CounterNotifier', () {
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

    test('endSession saves session, updates global stats and resets counter',
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
    test('updateGlobal notifies listeners with fresh state', () async {
      final container = makeContainer(FakeRepository());
      final states = <GlobalState>[];
      container.listen(globalStateProvider, (_, next) => states.add(next));

      await container.read(globalStateProvider.notifier).updateGlobal(5);

      expect(states, hasLength(1));
      expect(states.single.lifetimeTotalTaps, 5);
    });

    test('resetGlobal notifies listeners and zeroes totals', () async {
      final container = makeContainer(FakeRepository());
      await container.read(globalStateProvider.notifier).updateGlobal(5);

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
          id: 'a', startedAt: now, endedAt: now, count: 3, durationSeconds: 0);
      repo.sessions['b'] = Session(
          id: 'b', startedAt: now, endedAt: now, count: 2, durationSeconds: 0);
      await container.read(globalStateProvider.notifier).updateGlobal(3);
      await container.read(globalStateProvider.notifier).updateGlobal(2);
      container.read(sessionListProvider.notifier).reload();

      final deleted =
          await container.read(sessionListProvider.notifier).deleteSession('a');

      expect(deleted, isNotNull);
      final global = container.read(globalStateProvider);
      expect(global.lifetimeTotalTaps, 2); // 5 - 3
      expect(global.lifetimeTotalSessions, 1); // 2 - 1
    });

    test('restoreSession re-adds the session and its taps to the global',
        () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      final now = DateTime.now();
      repo.sessions['a'] = Session(
          id: 'a', startedAt: now, endedAt: now, count: 3, durationSeconds: 0);
      await container.read(globalStateProvider.notifier).updateGlobal(3);
      container.read(sessionListProvider.notifier).reload();

      final deleted =
          await container.read(sessionListProvider.notifier).deleteSession('a');
      expect(container.read(sessionListProvider), isEmpty);
      expect(container.read(globalStateProvider).lifetimeTotalTaps, 0);

      await container
          .read(sessionListProvider.notifier)
          .restoreSession(deleted!);

      expect(container.read(sessionListProvider), hasLength(1));
      final global = container.read(globalStateProvider);
      expect(global.lifetimeTotalTaps, 3);
      expect(global.lifetimeTotalSessions, 1);
    });

    test('deleting after a global reset never drives the total negative',
        () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      final now = DateTime.now();
      repo.sessions['a'] = Session(
          id: 'a', startedAt: now, endedAt: now, count: 5, durationSeconds: 0);
      await container.read(globalStateProvider.notifier).updateGlobal(5);
      // Global reset preserves history but zeroes lifetime totals.
      await container.read(globalStateProvider.notifier).resetGlobal();
      container.read(sessionListProvider.notifier).reload();

      await container.read(sessionListProvider.notifier).deleteSession('a');

      final global = container.read(globalStateProvider);
      expect(global.lifetimeTotalTaps, 0);
      expect(global.lifetimeTotalSessions, 0);
    });
  });
}
