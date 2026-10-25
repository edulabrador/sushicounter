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
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Session _session(
  String id,
  int count, {
  String? restaurant,
  int? price,
  int daysAgo = 1,
}) {
  final end = DateTime.now().subtract(Duration(days: daysAgo));
  return Session(
    id: id,
    startedAt: end.subtract(const Duration(minutes: 40)),
    endedAt: end,
    count: count,
    durationSeconds: 2400,
    restaurant: restaurant,
    priceCents: price,
  );
}

Widget _app(FakeRepository repo) => ProviderScope(
  overrides: [
    storageProvider.overrideWithValue(repo),
    backupFilesProvider.overrideWithValue(FakeBackupFiles()),
    screenAwakeProvider.overrideWithValue((_) async {}),
  ],
  child: const SushiScoreApp(),
);

void main() {
  group('restaurant logic', () {
    test('blank names are no restaurant', () {
      expect(Session.normalizeRestaurant('  '), isNull);
      expect(Session.normalizeRestaurant(null), isNull);
      expect(Session.normalizeRestaurant(' Zen '), 'Zen');
    });

    test('groups ignoring case, busiest first, latest spelling', () {
      final stats = restaurantStats([
        _session('a', 10, restaurant: 'sushi zen', price: 2000, daysAgo: 9),
        _session('b', 30, restaurant: 'Sushi Zen ', price: 2000, daysAgo: 2),
        _session('c', 20, restaurant: 'Koi', price: 3000),
        _session('d', 99),
      ]);
      expect(stats.map((r) => r.name), ['Sushi Zen', 'Koi']);
      final zen = stats.first;
      expect((zen.sessions, zen.pieces, zen.averagePieces), (2, 40, 20.0));
      expect(zen.costPerPieceCents, 100);
      expect(stats.last.costPerPieceCents, 150);
    });

    test('suggests each known name once, most recent first', () {
      expect(
        knownRestaurants([
          _session('a', 1, restaurant: 'Koi', daysAgo: 5),
          _session('b', 1, restaurant: 'Zen', daysAgo: 1),
          _session('c', 1, restaurant: 'koi', daysAgo: 3),
          _session('d', 1),
        ]),
        ['Zen', 'koi'],
      );
    });
  });

  group('restaurant storage', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('sushiscore_rest_');
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('is saved, cleared, survives restarts and undo', () async {
      var repo = HiveRepository();
      await repo.init(path: directory.path);
      await repo.completeSession(_session('a', 5));
      expect(await repo.setSessionRestaurant('missing', 'Zen'), isNull);
      expect(
        (await repo.setSessionRestaurant('a', ' Zen '))!.restaurant,
        'Zen',
      );
      final deleted = await repo.deleteSessionWithTotals('a');
      await repo.restoreSessionWithTotals(deleted!);
      await Hive.close();

      repo = HiveRepository();
      await repo.init(path: directory.path);
      expect(repo.getAllSessions().single.restaurant, 'Zen');
      await repo.setSessionRestaurant('a', '   ');
      expect(repo.getAllSessions().single.restaurant, isNull);
    });

    test('backups carry it and reject absurd names', () {
      final encoded = encodeBackup(
        BackupData(
          global: GlobalState(lifetimeTotalTaps: 5, lifetimeTotalSessions: 1),
          sessions: [_session('a', 5, restaurant: 'Zen')],
        ),
      );
      expect(decodeBackup(encoded).sessions.single.restaurant, 'Zen');
      final raw = jsonDecode(encoded) as Map<String, dynamic>;
      (raw['sessions'] as List).first['restaurant'] = 'x' * 61;
      expect(() => decodeBackup(jsonEncode(raw)), throwsFormatException);
      (raw['sessions'] as List).first['restaurant'] = 42;
      expect(() => decodeBackup(jsonEncode(raw)), throwsFormatException);
    });
  });

  group('restaurant UI', () {
    testWidgets('set from the details with a suggestion, shown in history', (
      tester,
    ) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('old', 9, restaurant: 'Sushi Zen'));
      await repo.completeSession(_session('new', 12, daysAgo: 0));
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // The newest session has no restaurant yet.
      await tester.tap(find.text('Duration: 40:00').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add restaurant'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zen');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Sushi Zen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.sessions['new']!.restaurant, 'Sushi Zen');
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Sushi Zen'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('can be removed', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 9, restaurant: 'Koi'));
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Koi'), findsOneWidget); // chip on the card
      await tester.tap(find.text('Duration: 40:00'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Koi'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(repo.sessions['a']!.restaurant, isNull);
    });

    testWidgets('stats compare restaurants', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(
        _session('a', 20, restaurant: 'Zen', price: 2000),
      );
      await repo.completeSession(
        _session('b', 10, restaurant: 'Koi', price: 2000, daysAgo: 2),
      );
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('By restaurant'));
      expect(find.text('Zen'), findsOneWidget);
      expect(find.text('1 session · avg 20.0'), findsNWidgets(1));
      expect(find.text(r'$1.00/piece'), findsOneWidget);
      expect(find.text(r'$2.00/piece'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsWidgets);
    });

    testWidgets('no restaurant section without restaurants', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 20));
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('By restaurant'), findsNothing);
    });
  });
}
