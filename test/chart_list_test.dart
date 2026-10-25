import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

void main() {
  Future<void> openStats(WidgetTester tester) async {
    final repo = FakeRepository();
    final now = DateTime.now();
    for (final (i, count) in [7, 12].indexed) {
      final end = now.subtract(Duration(days: 3 - i));
      await repo.completeSession(
        Session(
          id: '$i',
          startedAt: end.subtract(const Duration(minutes: 30)),
          endedAt: end,
          count: count,
          durationSeconds: 1800,
        ),
      );
    }
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
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
  }

  testWidgets('the trend reads as a list, newest first, and back', (
    tester,
  ) async {
    await openStats(tester);
    await tester.ensureVisible(find.byTooltip('Show as list').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show as list').first);
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsNothing);
    final values = tester
        .widgetList<Text>(find.textContaining(' taps'))
        .map((t) => t.data)
        .toList();
    expect(values, ['12 taps', '7 taps']);

    await tester.ensureVisible(find.byTooltip('Show as chart'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show as chart'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('weekly pieces read as eight labelled weeks', (tester) async {
    await openStats(tester);
    // Trend, then weekly, then the calendar.
    final weekly = find.byTooltip('Show as list').at(1);
    await tester.ensureVisible(weekly);
    await tester.pumpAndSettle();
    await tester.tap(weekly);
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsNothing);
    expect(find.textContaining('Week of '), findsNWidgets(8));
    expect(find.text('0 pieces'), findsWidgets);
  });

  testWidgets('each list row is announced as one item', (tester) async {
    final semantics = tester.ensureSemantics();
    await openStats(tester);
    await tester.ensureVisible(find.byTooltip('Show as list').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show as list').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'\n12 taps$')), findsOneWidget);
    semantics.dispose();
  });
}
