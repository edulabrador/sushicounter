import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sushiscore/core/models/global_state.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/backup.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/features/counter/widgets/session_timer.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/settings/views/settings_view.dart';
import 'package:sushiscore/features/stats/views/stats_view.dart';
import 'package:sushiscore/main.dart';

import 'widget_test.dart' show FakeRepository, makeContainer;

Session _session(
  String id,
  int count, {
  int epoch = 0,
  int durationSeconds = 60,
  DateTime? endedAt,
}) {
  final end = endedAt ?? DateTime(2026, 1, 1, 12);
  return Session(
    id: id,
    startedAt: end.subtract(Duration(seconds: durationSeconds)),
    endedAt: end,
    count: count,
    durationSeconds: durationSeconds,
    contributionEpoch: epoch,
  );
}

class FailingCompletionRepository extends FakeRepository {
  @override
  Future<Session> completeSession(Session session) =>
      Future<Session>.error(StateError('write failed'));
}

class FailingOngoingRepository extends FakeRepository {
  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) async {
    if (count > 0) throw StateError('ongoing write failed');
    await super.saveOngoingSession(count, startedAt);
  }
}

Widget _app(FakeRepository repo, {List<bool>? screenRequests}) => ProviderScope(
  overrides: [
    storageProvider.overrideWithValue(repo),
    if (screenRequests != null)
      screenAwakeProvider.overrideWithValue((value) async {
        screenRequests.add(value);
      }),
  ],
  child: const SushiScoreApp(),
);

String? _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data;

void main() {
  group('Hive repository', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('sushiscore_more_');
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    Future<HiveRepository> open() async {
      final repository = HiveRepository();
      await repository.init(path: directory.path);
      return repository;
    }

    test('legacy ongoing count without a start time gets one', () async {
      Hive.init(directory.path);
      final appState = await Hive.openBox('app_state');
      await appState.put('ongoingCount', 3);
      await Hive.close();

      final repository = await open();
      expect(repository.getOngoingCount(), 3);
      expect(repository.getOngoingStartedAt(), isNotNull);
    });

    test('an interrupted delete is replayed on restart', () async {
      final first = await open();
      await first.completeSession(_session('a', 4));
      await Hive.box('app_state').put('mutation_journal', {
        'kind': 'delete',
        'session': {
          'id': 'a',
          'startedAt': 1,
          'endedAt': 2,
          'count': 4,
          'durationSeconds': 1,
          'epoch': 0,
        },
        'global': {'taps': 0, 'sessions': 0, 'epoch': 0},
      });
      await Hive.close();

      final recovered = await open();
      expect(recovered.getAllSessions(), isEmpty);
      expect(recovered.getGlobalState().lifetimeTotalTaps, 0);
    });

    test('undo after a clamped delete in the same lifetime is exact', () async {
      final repository = await open();
      await repository.completeSession(_session('a', 5));
      // Simulate totals lower than the session, as left by old app versions.
      await Hive.box<GlobalState>('global_state').put(
        'state',
        GlobalState(lifetimeTotalTaps: 2, lifetimeTotalSessions: 1),
      );

      final deleted = await repository.deleteSessionWithTotals('a');
      expect(repository.getGlobalState().lifetimeTotalTaps, 0);
      expect(deleted!.tapsRemoved, 2);

      await repository.restoreSessionWithTotals(deleted);
      expect(repository.getGlobalState().lifetimeTotalTaps, 2);
      expect(repository.getGlobalState().lifetimeTotalSessions, 1);
    });

    test('reset records and persists when the lifetime started', () async {
      final repository = await open();
      await repository.resetGlobalState();
      expect(repository.getGlobalState().lastResetAt, isNotNull);
      await Hive.close();

      final restored = await open();
      expect(restored.getGlobalState().epoch, 1);
      expect(restored.getGlobalState().lastResetAt, isNotNull);
    });

    test('export and import round-trip all data', () async {
      final source = await open();
      await source.completeSession(_session('a', 3));
      await source.completeSession(
        _session('b', 7, endedAt: DateTime(2026, 1, 2)),
      );
      final json = encodeBackup(source.exportBackup());
      await Hive.deleteFromDisk();

      final target = await open();
      await target.completeSession(_session('other', 1));
      await target.saveOngoingSession(2, DateTime.now());
      await target.importBackup(decodeBackup(json));

      expect(target.getAllSessions().map((s) => s.id), ['b', 'a']);
      expect(target.getGlobalState().lifetimeTotalTaps, 10);
      expect(target.getGlobalState().lifetimeTotalSessions, 2);
      expect(target.getOngoingCount(), 0);
    });

    test('keep-screen-on defaults to true and persists', () async {
      final repository = await open();
      expect(repository.getKeepScreenOn(), isTrue);
      await repository.setKeepScreenOn(false);
      await Hive.close();
      expect((await open()).getKeepScreenOn(), isFalse);
    });
  });

  group('backup format', () {
    final valid = encodeBackup(
      BackupData(
        global: GlobalState(lifetimeTotalTaps: 3, lifetimeTotalSessions: 1),
        sessions: [_session('a', 3)],
      ),
    );

    test('accepts its own output', () {
      final backup = decodeBackup(valid);
      expect(backup.sessions.single.count, 3);
      expect(backup.global.lifetimeTotalTaps, 3);
    });

    test('rejects malformed input', () {
      final data = jsonDecode(valid) as Map<String, dynamic>;
      final duplicate = {
        ...data,
        'sessions': [data['sessions'][0], data['sessions'][0]],
      };
      final negative = {
        ...data,
        'global': {...data['global'] as Map, 'taps': -1},
      };
      for (final input in [
        'not json',
        '{}',
        jsonEncode({...data, 'format': 'other'}),
        jsonEncode(duplicate),
        jsonEncode(negative),
      ]) {
        expect(() => decodeBackup(input), throwsFormatException, reason: input);
      }
    });
  });

  group('counter', () {
    test('a restored count without a start time gets one', () async {
      final repo = FakeRepository();
      await repo.saveOngoingSession(3, null);
      final container = makeContainer(repo);
      expect(container.read(counterProvider).startedAt, isNotNull);
    });

    testWidgets('restored count without a start time renders the timer', (
      tester,
    ) async {
      final repo = FakeRepository();
      await repo.saveOngoingSession(3, null);
      await tester.pumpWidget(_app(repo));
      expect(tester.takeException(), isNull);
      expect(find.byKey(counterElapsedTimeKey), findsOneWidget);
    });

    test('an unresolved save error stays visible across taps', () async {
      final container = makeContainer(FailingOngoingRepository());
      final notifier = container.read(counterProvider.notifier);
      notifier.increment();
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(counterProvider).persistenceError,
        CounterError.saveOngoing,
      );
      notifier.increment();
      expect(
        container.read(counterProvider).persistenceError,
        CounterError.saveOngoing,
      );
    });

    testWidgets('a session whose save keeps failing can be discarded', (
      tester,
    ) async {
      final repo = FailingCompletionRepository();
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.byType(SushiButton));
      await tester.pump();
      expect(find.byKey(counterDiscardButtonKey), findsNothing);
      await tester.tap(find.byKey(counterEndSessionButtonKey));
      await tester.pump();

      await tester.ensureVisible(find.byKey(counterDiscardButtonKey));
      await tester.tap(find.byKey(counterDiscardButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(_text(tester, counterCurrentCountKey), '0');
      expect(repo.getOngoingCount(), 0);
      expect(
        tester.widget<SushiButton>(find.byType(SushiButton)).enabled,
        isTrue,
      );
    });

    testWidgets('screen stays on only during a session', (tester) async {
      final requests = <bool>[];
      await tester.pumpWidget(_app(FakeRepository(), screenRequests: requests));
      expect(requests, isEmpty);
      await tester.tap(find.byType(SushiButton));
      await tester.pump();
      expect(requests, [true]);
      await tester.tap(find.byKey(counterEndSessionButtonKey));
      await tester.pumpAndSettle();
      expect(requests, [true, false]);
    });

    testWidgets('screen is left alone when the setting is off', (tester) async {
      final requests = <bool>[];
      final repo = FakeRepository()..keepScreenOn = false;
      await tester.pumpWidget(_app(repo, screenRequests: requests));
      await tester.tap(find.byType(SushiButton));
      await tester.pump();
      expect(requests, isEmpty);
    });
  });

  group('stats', () {
    test('only the current lifetime feeds averages and best', () {
      final summary = summarizeSessions(
        [_session('old', 50, epoch: 0), _session('new', 4, epoch: 1)],
        StatsFilter.all,
        epoch: 1,
      );
      expect(summary.sessions.map((s) => s.id), ['new']);
      expect(summary.bestSession, 4);
    });

    test('unattributed legacy history belongs to the first lifetime', () {
      final summary = summarizeSessions(
        [_session('legacy', 6, epoch: Session.unattributedEpoch)],
        StatsFilter.all,
        epoch: 0,
      );
      expect(summary.sessions, hasLength(1));
    });

    testWidgets('lifetime taps agree between Counter and Stats', (
      tester,
    ) async {
      final repo = FakeRepository();
      await repo.adjustGlobalState(tapsDelta: 10, sessionsDelta: 1);
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.byType(SushiButton));
      await tester.tap(find.byType(SushiButton));
      await tester.pump();
      expect(_text(tester, counterLifetimeTotalKey), '12');

      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('stats explain a lifetime reset', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('old', 40));
      await repo.resetGlobalState();
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Since the lifetime reset on'), findsOne);
      // The 40-tap session from before the reset is not the "best" anymore.
      expect(find.text('40'), findsNothing);
    });
  });

  group('history', () {
    Future<void> openHistory(WidgetTester tester, FakeRepository repo) async {
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
    }

    testWidgets('durations are human readable', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 3, durationSeconds: 3725));
      await openHistory(tester, repo);
      expect(find.text('Duration: 1:02:05'), findsOneWidget);
    });

    testWidgets('sessions from before a reset are marked', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 3));
      await repo.resetGlobalState();
      await openHistory(tester, repo);
      expect(find.textContaining('Before lifetime reset'), findsOneWidget);
    });

    testWidgets('consecutive deletes can all be undone', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 3));
      await repo.completeSession(
        _session('b', 2, endedAt: DateTime(2026, 1, 2)),
      );
      await openHistory(tester, repo);

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byTooltip('Delete session').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
      }
      expect(repo.sessions, isEmpty);
      expect(find.text('2 sessions deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(repo.sessions.keys, unorderedEquals(['a', 'b']));
      expect(repo.getGlobalState().lifetimeTotalTaps, 5);
      expect(repo.getGlobalState().lifetimeTotalSessions, 2);
    });

    testWidgets('session details show pace and allow deleting', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 30, durationSeconds: 600));
      await openHistory(tester, repo);
      await tester.tap(find.text('Duration: 10:00'));
      await tester.pumpAndSettle();
      expect(find.text('Pace: 3.0 per minute'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Delete session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(repo.sessions, isEmpty);
    });
  });

  group('settings', () {
    test('reset keyword forgives case and spaces only', () {
      expect(matchesResetKeyword(' reset ', 'RESET'), isTrue);
      expect(matchesResetKeyword('RESE', 'RESET'), isFalse);
    });

    testWidgets('export copies a valid backup and import restores it', (
      tester,
    ) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboard};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final repo = FakeRepository();
      await repo.completeSession(_session('a', 3));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageProvider.overrideWithValue(repo)],
          child: const SushiScoreApp(),
        ),
      );
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export data'));
      await tester.pumpAndSettle();
      expect(decodeBackup(clipboard!).sessions.single.id, 'a');

      repo.sessions.clear();
      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Paste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace data'));
      await tester.pumpAndSettle();

      expect(repo.sessions.keys, ['a']);
      expect(find.text('Imported 1 session.'), findsOneWidget);
    });

    testWidgets('import rejects text that is not a backup', (tester) async {
      final repo = FakeRepository();
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.text('Replace data'));
      await tester.pumpAndSettle();
      expect(
        find.text('This is not a valid Sushi Tracker backup.'),
        findsOneWidget,
      );
    });

    testWidgets('keep-screen-on can be turned off', (tester) async {
      final repo = FakeRepository();
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(repo.keepScreenOn, isFalse);
    });
  });

  testWidgets('the app follows a Spanish device language', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'ES')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final repo = FakeRepository();
    await repo.completeSession(_session('a', 30, durationSeconds: 600));
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Terminar sesión'), findsOneWidget);
    expect(find.bySemanticsLabel('Sumar un sushi'), findsOneWidget);

    // Dates and numbers use Spanish formats without missing locale data.
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ene 2026'), findsOneWidget);
    await tester.tap(find.text('Duración: 10:00'));
    await tester.pumpAndSettle();
    expect(find.text('Ritmo: 3,0 por minuto'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estadísticas'));
    await tester.pumpAndSettle();
    expect(find.text('Media (Todas)'), findsOneWidget);
    expect(find.text('30,0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the startup error screen is localized too', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(StartupApp(createRepository: _FailingInit.new));
    await tester.pump();
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

class _FailingInit extends HiveRepository {
  @override
  Future<void> init({String? path}) =>
      Future<void>.error(StateError('storage unavailable'));
}
