import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Session _session(String id, int count, {int daysAgo = 1}) {
  final end = DateTime.now().subtract(Duration(days: daysAgo));
  return Session(
    id: id,
    startedAt: end.subtract(const Duration(minutes: 40)),
    endedAt: end,
    count: count,
    durationSeconds: 2400,
  );
}

void main() {
  group('editing in storage', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('sushiscore_edit_');
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test(
      'moves the session, keeps its duration and fixes the totals',
      () async {
        var repo = HiveRepository();
        await repo.init(path: directory.path);
        await repo.completeSession(_session('a', 10));
        await repo.completeSession(_session('b', 5, daysAgo: 3));
        final start = DateTime(2026, 3, 14, 20, 15);

        final edited = await repo.editSession('a', count: 14, startedAt: start);
        expect(edited!.count, 14);
        expect(edited.startedAt, start);
        expect(edited.endedAt, start.add(const Duration(minutes: 40)));
        expect(edited.durationSeconds, 2400);
        expect(repo.getGlobalState().lifetimeTotalTaps, 19);
        expect(repo.getGlobalState().lifetimeTotalSessions, 2);

        await Hive.close();
        repo = HiveRepository();
        await repo.init(path: directory.path);
        expect(repo.getAllSessions().map((s) => s.count), [5, 14]);
        expect(repo.getGlobalState().lifetimeTotalTaps, 19);
      },
    );

    test('leaves the totals of a past lifetime alone', () async {
      final repo = HiveRepository();
      await repo.init(path: directory.path);
      await repo.completeSession(_session('old', 10));
      await repo.resetGlobalState();
      await repo.editSession('old', count: 30, startedAt: DateTime(2026));
      expect(repo.getGlobalState().lifetimeTotalTaps, 0);
      expect(repo.getAllSessions().single.count, 30);
    });

    test('rejects impossible counts and unknown sessions', () async {
      final repo = HiveRepository();
      await repo.init(path: directory.path);
      await repo.completeSession(_session('a', 10));
      expect(
        () => repo.editSession('a', count: 0, startedAt: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        await repo.editSession('gone', count: 3, startedAt: DateTime(2026)),
        isNull,
      );
      expect(repo.getGlobalState().lifetimeTotalTaps, 10);
    });

    test('an interrupted edit is finished on restart', () async {
      final first = HiveRepository();
      await first.init(path: directory.path);
      await first.completeSession(_session('a', 10));
      final session = first.getAllSessions().single;
      await Hive.box('app_state').put('mutation_journal', {
        'kind': 'update',
        'session': {
          'id': 'a',
          'startedAt': session.startedAt.millisecondsSinceEpoch,
          'endedAt': session.endedAt.millisecondsSinceEpoch,
          'count': 12,
          'durationSeconds': 2400,
          'epoch': 0,
        },
        'global': {'taps': 12, 'sessions': 1, 'epoch': 0},
      });
      await Hive.close();

      final recovered = HiveRepository();
      await recovered.init(path: directory.path);
      expect(recovered.getAllSessions().single.count, 12);
      expect(recovered.getGlobalState().lifetimeTotalTaps, 12);
      expect(Hive.box('app_state').containsKey('mutation_journal'), isFalse);
    });
  });

  group('editing in the app', () {
    Widget app(FakeRepository repo) => ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(repo),
        backupFilesProvider.overrideWithValue(FakeBackupFiles()),
        screenAwakeProvider.overrideWithValue((_) async {}),
      ],
      child: const SushiScoreApp(),
    );

    Future<void> openEditor(WidgetTester tester) async {
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duration: 40:00').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit session'));
      await tester.pumpAndSettle();
    }

    testWidgets('corrects the pieces everywhere', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 10));
      await tester.pumpWidget(app(repo));
      await openEditor(tester);

      await tester.enterText(find.byType(TextField), '23');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.sessions['a']!.count, 23);
      expect(repo.getGlobalState().lifetimeTotalTaps, 23);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('23'),
        ),
        findsOneWidget,
      );
      // The counter's lifetime total follows.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Counter'));
      await tester.pumpAndSettle();
      expect(find.text('23'), findsWidgets);
    });

    testWidgets('refuses an empty or zero count', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 10));
      await tester.pumpWidget(app(repo));
      await openEditor(tester);

      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a whole number from 1 to 9999.'), findsOneWidget);
      expect(repo.sessions['a']!.count, 10);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.sessions['a']!.count, 10);
    });
  });
}
