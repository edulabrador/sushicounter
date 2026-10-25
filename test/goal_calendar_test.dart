import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/core/storage/preferences.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/features/stats/widgets/calendar_heatmap.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Widget _app(FakeRepository repo) => ProviderScope(
  overrides: [
    storageProvider.overrideWithValue(repo),
    backupFilesProvider.overrideWithValue(FakeBackupFiles()),
    screenAwakeProvider.overrideWithValue((_) async {}),
  ],
  child: const SushiScoreApp(),
);

Session _session(String id, DateTime endedAt, int count) => Session(
  id: id,
  startedAt: endedAt.subtract(const Duration(hours: 1)),
  endedAt: endedAt,
  count: count,
  durationSeconds: 3600,
);

void main() {
  group('session goal', () {
    test('is stored, cleared, and ignores bad values', () async {
      final directory = await Directory.systemTemp.createTemp('goal_');
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      var repo = HiveRepository();
      await repo.init(path: directory.path);
      expect(repo.preferences.sessionGoal, isNull);
      await repo.preferences.setSessionGoal(25);
      await Hive.close();

      repo = HiveRepository();
      await repo.init(path: directory.path);
      expect(repo.preferences.sessionGoal, 25);
      await Hive.box('app_state').put('session_goal', 5000);
      expect(repo.preferences.sessionGoal, isNull);
      await repo.preferences.setSessionGoal(null);
      expect(Hive.box('app_state').containsKey('session_goal'), isFalse);
    });

    testWidgets('set in settings, followed on the counter', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      await tester.pumpWidget(_app(FakeRepository()));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Session goal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Off'), findsOneWidget);
      await tester.tap(find.text('Session goal'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a whole number from 1 to 999.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('3 pieces'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Goal 3 · 3 to go'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(SushiButton));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.text('Goal of 3 reached!'), findsOneWidget);
      expect(
        haptics.where((h) => h == 'HapticFeedbackType.mediumImpact'),
        hasLength(1),
      );
    });

    testWidgets('can be turned off', (tester) async {
      final repo = FakeRepository()
        ..preferences = InMemoryPreferences(sessionGoal: 30);
      await tester.pumpWidget(_app(repo));
      expect(find.text('Goal 30 · 30 to go'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Session goal'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Session goal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();
      expect(repo.preferences.sessionGoal, isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.textContaining('Goal'), findsNothing);
    });
  });

  group('calendar', () {
    test('adds up pieces per local day', () {
      final days = piecesByDay([
        _session('a', DateTime(2026, 10, 24, 13), 10),
        _session('b', DateTime(2026, 10, 24, 22), 5),
        _session('c', DateTime(2026, 10, 20, 21), 7),
      ]);
      expect(days, {DateTime(2026, 10, 24): 15, DateTime(2026, 10, 20): 7});
    });

    test('shades in four steps up to the busiest day', () {
      expect(heatLevel(0, 40), 0);
      expect(heatLevel(1, 40), 1);
      expect(heatLevel(10, 40), 1);
      expect(heatLevel(11, 40), 2);
      expect(heatLevel(30, 40), 3);
      expect(heatLevel(40, 40), 4);
      expect(heatLevel(5, 0), 0);
    });

    test('fits whole weeks in the width', () {
      expect(calendarWeeksFor(100), 8);
      expect(calendarWeeksFor(22 + 17 * 18 - 3), 18);
      expect(calendarWeeksFor(2000), 26);
    });

    testWidgets('appears in Stats and reads as a list of days', (tester) async {
      final now = DateTime(2026, 10, 25, 12);
      final repo = FakeRepository();
      await repo.completeSession(_session('a', DateTime(2026, 10, 24, 21), 22));
      await repo.completeSession(_session('b', DateTime(2026, 9, 3, 21), 9));
      await withClock(Clock.fixed(now), () async {
        await tester.pumpWidget(_app(repo));
        await tester.tap(find.text('Stats'));
        await tester.pumpAndSettle();
        final calendar = find.byType(CalendarHeatmap);
        await tester.ensureVisible(calendar);
        await tester.pumpAndSettle();
        expect(find.text('Calendar'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final toggle = find.byTooltip('Show as list').at(2);
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byType(CalendarHeatmap), findsNothing);
        expect(find.text('Sat, Oct 24, 2026'), findsOneWidget);
        expect(find.text('22 pieces'), findsWidgets);
        expect(find.text('Thu, Sep 3, 2026'), findsOneWidget);
      });
    });
  });
}
