import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:sushiscore/core/models/global_state.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/backup.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository, makeContainer;

Session _session({List<Companion> companions = const []}) => Session(
  id: 'a',
  startedAt: DateTime(2026, 10, 24, 20),
  endedAt: DateTime(2026, 10, 24, 21),
  count: 12,
  durationSeconds: 3600,
  companions: companions,
);

void main() {
  group('the table in the counter', () {
    test('names must be new, non-blank, short, and fit the table', () {
      final container = makeContainer(FakeRepository());
      final counter = container.read(counterProvider.notifier);
      expect(counter.addCompanion('  Ana '), isTrue);
      expect(counter.addCompanion('ana'), isFalse);
      expect(counter.addCompanion('   '), isFalse);
      expect(counter.addCompanion('x' * 31), isFalse);
      for (var i = 1; i < Companion.maxPerTable; i++) {
        expect(counter.addCompanion('P$i'), isTrue);
      }
      expect(counter.addCompanion('One too many'), isFalse);
      expect(container.read(counterProvider).companions.first.name, 'Ana');
    });

    test('the timer runs while anyone has pieces', () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      final counter = container.read(counterProvider.notifier);
      counter.addCompanion('Ana');
      expect(container.read(counterProvider).startedAt, isNull);

      counter.incrementCompanion(0);
      expect(container.read(counterProvider).startedAt, isNotNull);
      counter.increment();
      counter.decrement();
      expect(container.read(counterProvider).startedAt, isNotNull);
      counter.decrementCompanion(0);
      counter.decrementCompanion(0); // never below zero
      expect(container.read(counterProvider).companions.single.count, 0);
      expect(container.read(counterProvider).startedAt, isNull);
    });

    test('is saved with the unsaved session and restored', () async {
      final repo = FakeRepository();
      var container = makeContainer(repo);
      final counter = container.read(counterProvider.notifier);
      counter.addCompanion('Ana');
      counter.incrementCompanion(0);
      counter.incrementCompanion(0);
      await Future<void>.delayed(Duration.zero);
      expect(repo.getOngoingCompanions(), [
        const Companion(name: 'Ana', count: 2),
      ]);

      container = makeContainer(repo);
      final restored = container.read(counterProvider);
      expect(restored.companions.single.count, 2);
      expect(restored.startedAt, isNotNull);
      expect(restored.tableTotal, 2);
    });

    test('ending saves the table; discarding clears it', () async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      final counter = container.read(counterProvider.notifier);
      counter.addCompanion('Ana');
      counter.incrementCompanion(0);
      counter.increment();
      await counter.endSession();
      expect(repo.sessions.values.single.companions, [
        const Companion(name: 'Ana', count: 1),
      ]);
      expect(container.read(counterProvider).companions, isEmpty);
      // Only your own pieces count towards your totals.
      expect(repo.getGlobalState().lifetimeTotalTaps, 1);

      counter.addCompanion('Leo');
      await counter.resetCurrent();
      expect(container.read(counterProvider).companions, isEmpty);
      expect(repo.getOngoingCompanions(), isEmpty);
    });

    test('lifetime reset waits for an empty table', () {
      final container = makeContainer(FakeRepository());
      container.read(counterProvider.notifier).addCompanion('Ana');
      expect(container.read(counterProvider).canResetLifetime, isFalse);
    });
  });

  group('the table in storage', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('sushiscore_table_');
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('sessions and the unsaved table survive a restart', () async {
      var repo = HiveRepository();
      await repo.init(path: directory.path);
      await repo.completeSession(
        _session(companions: const [Companion(name: 'Ana', count: 7)]),
      );
      await repo.saveOngoingSession(
        2,
        DateTime(2026, 10, 25, 20),
        companions: const [Companion(name: 'Leo', count: 3)],
      );
      await Hive.close();

      repo = HiveRepository();
      await repo.init(path: directory.path);
      expect(repo.getAllSessions().single.companions, [
        const Companion(name: 'Ana', count: 7),
      ]);
      expect(repo.getOngoingCompanions(), [
        const Companion(name: 'Leo', count: 3),
      ]);
    });
  });

  group('the table in backups', () {
    String encoded(List<Companion> companions) => encodeBackup(
      BackupData(
        global: GlobalState(lifetimeTotalTaps: 12, lifetimeTotalSessions: 1),
        sessions: [_session(companions: companions)],
      ),
    );

    test('round-trips, and stays out of solo sessions', () {
      const table = [Companion(name: 'Ana', count: 7)];
      expect(decodeBackup(encoded(table)).sessions.single.companions, table);
      expect(encoded(const []), isNot(contains('companions')));
    });

    test('rejects broken tables', () {
      for (final bad in [
        [
          {'name': 'Ana', 'count': 1},
          {'name': 'ANA', 'count': 2},
        ],
        [
          {'name': '', 'count': 1},
        ],
        [
          {'name': 'Ana', 'count': -1},
        ],
        [
          {'name': 'Ana', 'count': '3'},
        ],
        [
          for (var i = 0; i < 9; i++) {'name': 'P$i', 'count': 1},
        ],
        'Ana',
      ]) {
        final raw = jsonDecode(encoded(const [])) as Map<String, dynamic>;
        (raw['sessions'] as List).first['companions'] = bad;
        expect(
          () => decodeBackup(jsonEncode(raw)),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  testWidgets('count for a friend, then see the table in history', (
    tester,
  ) async {
    final repo = FakeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(repo),
          backupFilesProvider.overrideWithValue(FakeBackupFiles()),
          screenAwakeProvider.overrideWithValue((_) async {}),
        ],
        child: const SushiScoreApp(),
      ),
    );
    final add = find.text('Add someone at your table');
    await tester.scrollUntilVisible(
      add,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final addOne = find.byTooltip('Add one for Ana');
    await tester.ensureVisible(addOne);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(addOne);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CounterView)),
    );
    container.read(counterProvider.notifier).increment();
    await tester.pumpAndSettle();
    expect(find.text('Table total: 4 pieces'), findsOneWidget);

    // Removing someone with pieces asks first.
    await tester.ensureVisible(find.byTooltip('Remove Ana'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove Ana'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Ana and their 3 pieces?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add one for Ana'), findsOneWidget);

    await container.read(counterProvider.notifier).endSession();
    await tester.pumpAndSettle();
    expect(find.text('Table total: 4 pieces'), findsNothing);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('+1'), findsOneWidget);
    await tester.tap(find.text('+1'));
    await tester.pumpAndSettle();
    expect(find.text('At the table'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('3 pieces'), findsOneWidget);
  });
}
