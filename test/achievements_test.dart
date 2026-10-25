import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/stats/achievements.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Session _s(
  String id,
  int count, {
  DateTime? at,
  int? price,
  String? restaurant,
}) {
  final end = at ?? DateTime(2026, 10, 1, 21);
  return Session(
    id: id,
    startedAt: end.subtract(const Duration(minutes: 30)),
    endedAt: end,
    count: count,
    durationSeconds: 1800,
    priceCents: price,
    restaurant: restaurant,
  );
}

Achievement _get(List<Achievement> all, AchievementId id) =>
    all.firstWhere((a) => a.id == id);

void main() {
  group('achievement rules', () {
    test('nothing is unlocked without history', () {
      expect(computeAchievements([]).where((a) => a.unlocked), isEmpty);
    });

    test('thresholds unlock exactly at the target', () {
      final all = computeAchievements([
        for (var i = 0; i < 9; i++) _s('s$i', 3),
        _s('big', 30),
      ]);
      expect(_get(all, AchievementId.firstSession).unlocked, isTrue);
      expect(_get(all, AchievementId.tenSessions).unlocked, isTrue);
      expect(_get(all, AchievementId.bigAppetite).unlocked, isTrue);
      expect(_get(all, AchievementId.sushiMaster).unlocked, isFalse);
      expect(_get(all, AchievementId.sushiMaster).progress, 30);
      final hundred = _get(all, AchievementId.hundredPieces);
      expect((hundred.progress, hundred.unlocked), (57, false));
    });

    test('progress shown never passes the target', () {
      final first = _get(
        computeAchievements([_s('a', 1), _s('b', 1)]),
        AchievementId.firstSession,
      );
      expect((first.progress, first.shownProgress), (2, 1));
    });

    test('prices and restaurants count distinct entries', () {
      final all = computeAchievements([
        for (var i = 0; i < 5; i++)
          _s('p$i', 2, price: 1000, restaurant: ['Zen', 'zen', 'Koi'][i % 3]),
        _s('x', 2, restaurant: 'Umi'),
      ]);
      expect(_get(all, AchievementId.priceWatcher).unlocked, isTrue);
      expect(_get(all, AchievementId.explorer).progress, 3);
    });

    test('longest weekly streak survives later gaps', () {
      final mondays = [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 12),
        DateTime(2026, 1, 19),
        DateTime(2026, 1, 26),
        DateTime(2026, 3, 2), // gap
        DateTime(2026, 3, 9),
      ];
      final sessions = [
        for (final (i, day) in mondays.indexed) _s('w$i', 5, at: day),
      ];
      expect(longestWeeklyStreak(sessions), 4);
      expect(
        _get(computeAchievements(sessions), AchievementId.regular).unlocked,
        isTrue,
      );
      expect(longestWeeklyStreak([]), 0);
    });

    test('newly unlocked lists only the change', () {
      final before = computeAchievements([_s('a', 29)]);
      final after = computeAchievements([_s('a', 29), _s('b', 30)]);
      expect(newlyUnlocked(before, after), [AchievementId.bigAppetite]);
      expect(newlyUnlocked(after, after), isEmpty);
    });
  });

  group('achievements UI', () {
    Widget app(FakeRepository repo) => ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(repo),
        backupFilesProvider.overrideWithValue(FakeBackupFiles()),
        screenAwakeProvider.overrideWithValue((_) async {}),
      ],
      child: const SushiScoreApp(),
    );

    testWidgets('ending the first session celebrates it', (tester) async {
      await tester.pumpWidget(app(FakeRepository()));
      await tester.tap(find.byType(SushiButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(counterEndSessionButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Achievement unlocked: First bite'), findsOneWidget);
    });

    testWidgets('no celebration when nothing new is unlocked', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_s('old', 2));
      await tester.pumpWidget(app(repo));
      await tester.tap(find.byType(SushiButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(counterEndSessionButtonKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Achievement unlocked'), findsNothing);
    });

    testWidgets('stats list every achievement with the count', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_s('a', 31));
      await tester.pumpWidget(app(repo));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Achievements'));
      expect(find.text('2 of 10'), findsOneWidget);
      await tester.ensureVisible(find.text('Explorer'));
      expect(find.text('0/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
