import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/stats/providers/stats_provider.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/features/stats/widgets/trend_chart.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository, makeContainer;

Future<FakeRepository> _withHistory() async {
  final repo = FakeRepository();
  for (var i = 0; i < 4; i++) {
    final endedAt = DateTime(2026, 10, 1 + i * 5, 21);
    await repo.completeSession(
      Session(
        id: 's$i',
        startedAt: endedAt.subtract(const Duration(hours: 1)),
        endedAt: endedAt,
        count: 20 + i,
        durationSeconds: 3600,
      ),
    );
  }
  return repo;
}

void main() {
  test('counter taps do not recompute the stats', () async {
    final container = makeContainer(await _withHistory());
    final before = container.read(statsDataProvider);
    for (var i = 0; i < 5; i++) {
      container.read(counterProvider.notifier).increment();
      await Future<void>.delayed(Duration.zero);
    }
    expect(container.read(counterProvider).count, 5);
    expect(identical(container.read(statsDataProvider), before), isTrue);

    container.read(statsFilterProvider.notifier).select(StatsFilter.last7);
    expect(identical(container.read(statsDataProvider), before), isFalse);
  });

  test('the counter screen sees one change per tap', () async {
    final container = makeContainer(FakeRepository());
    var raw = 0;
    var onScreen = 0;
    container.listen(counterProvider, (_, _) => raw++);
    container.listen(counterProvider.select(counterOnScreen), (_, _) {
      onScreen++;
    });
    for (var i = 0; i < 3; i++) {
      container.read(counterProvider.notifier).increment();
      await Future<void>.delayed(Duration.zero);
    }
    // Each tap also flips the background-save flag on and off.
    expect(raw, 9);
    expect(onScreen, 3);
  });

  testWidgets('the hidden stats tab does not rebuild while counting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(await _withHistory()),
          backupFilesProvider.overrideWithValue(FakeBackupFiles()),
          screenAwakeProvider.overrideWithValue((_) async {}),
        ],
        child: const SushiScoreApp(),
      ),
    );
    await tester.pumpAndSettle();
    final chart = find.byType(TrendChart, skipOffstage: false);
    final before = tester.widget(chart);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(SushiButton));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(identical(tester.widget(chart), before), isTrue);

    // The live lifetime tile still follows the counter.
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();
    expect(find.text('${20 + 21 + 22 + 23 + 4}'), findsOneWidget);
  });
}
