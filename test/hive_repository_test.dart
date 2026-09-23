import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sushiscore/core/models/global_state.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sushiscore_hive_');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('serialized rapid ongoing writes restore the latest count and start', () async {
    final repository = HiveRepository();
    await repository.init(path: directory.path);
    final startedAt = DateTime.utc(2026, 9, 23, 12);
    await Future.wait([
      repository.saveOngoingSession(1, startedAt),
      repository.saveOngoingSession(2, startedAt),
      repository.saveOngoingSession(3, startedAt),
      repository.saveOngoingSession(2, startedAt),
      repository.saveOngoingSession(3, startedAt),
    ]);
    expect(repository.getOngoingCount(), 3);
    expect(
      repository.getOngoingStartedAt()!.millisecondsSinceEpoch,
      startedAt.millisecondsSinceEpoch,
    );

    await Hive.close();
    final restored = HiveRepository();
    await restored.init(path: directory.path);
    expect(restored.getOngoingCount(), 3);
    expect(
      restored.getOngoingStartedAt()!.millisecondsSinceEpoch,
      startedAt.millisecondsSinceEpoch,
    );
  });

  test('replays an interrupted completion journal on restart', () async {
    final first = HiveRepository();
    await first.init(path: directory.path);
    await first.saveOngoingSession(4, DateTime.fromMillisecondsSinceEpoch(1));
    await Hive.box('app_state').put('mutation_journal', {
      'kind': 'complete',
      'session': {
        'id': 'pending',
        'startedAt': 1,
        'endedAt': 2,
        'count': 4,
        'durationSeconds': 1,
        'epoch': 0,
      },
      'global': {'taps': 4, 'sessions': 1, 'epoch': 0},
      'ongoing': {'count': 0, 'startedAt': null},
    });
    await Hive.close();

    final recovered = HiveRepository();
    await recovered.init(path: directory.path);

    expect(recovered.getAllSessions().single.id, 'pending');
    expect(recovered.getGlobalState().lifetimeTotalTaps, 4);
    expect(recovered.getOngoingCount(), 0);
    expect(Hive.box('app_state').containsKey('mutation_journal'), isFalse);
  });

  test(
    'completion and undo are idempotent and reset isolates old history',
    () async {
      final repository = HiveRepository();
      await repository.init(path: directory.path);
      final session = Session(
        id: 'one',
        startedAt: DateTime.fromMillisecondsSinceEpoch(1),
        endedAt: DateTime.fromMillisecondsSinceEpoch(2),
        count: 3,
        durationSeconds: 1,
      );

      await repository.completeSession(session);
      await repository.completeSession(session);
      expect(repository.getGlobalState().lifetimeTotalTaps, 3);
      await repository.resetGlobalState();
      await repository.deleteSessionWithTotals('one');
      expect(repository.getGlobalState().lifetimeTotalTaps, 0);
      await repository.restoreSessionWithTotals(session);
      await repository.restoreSessionWithTotals(session);
      expect(repository.getGlobalState().lifetimeTotalSessions, 0);
    },
  );

  test(
    'legacy history with mismatched totals is conservatively un-attributed',
    () async {
      Hive.init(directory.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SessionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(GlobalStateAdapter());
      }
      final sessions = await Hive.openBox<Session>('sessions');
      final globals = await Hive.openBox<GlobalState>('global_state');
      await sessions.put(
        'legacy',
        Session(
          id: 'legacy',
          startedAt: DateTime.fromMillisecondsSinceEpoch(1),
          endedAt: DateTime.fromMillisecondsSinceEpoch(2),
          count: 10,
          durationSeconds: 1,
        ),
      );
      await globals.put(
        'state',
        GlobalState(lifetimeTotalTaps: 2, lifetimeTotalSessions: 1),
      );
      await Hive.close();

      final repository = HiveRepository();
      await repository.init(path: directory.path);
      await repository.deleteSessionWithTotals('legacy');

      expect(repository.getGlobalState().lifetimeTotalTaps, 2);
      expect(repository.getGlobalState().lifetimeTotalSessions, 1);
    },
  );
}
