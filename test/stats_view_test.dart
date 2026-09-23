import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/theme/app_theme.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/features/stats/views/stats_view.dart';

import 'widget_test.dart' show FakeRepository;

Session session(String id, DateTime endedAt, int count) => Session(
  id: id,
  startedAt: endedAt.subtract(const Duration(minutes: 1)),
  endedAt: endedAt,
  count: count,
  durationSeconds: 60,
);

void main() {
  test('summarizeSessions sorts sessions chronologically', () {
    final start = DateTime(2026, 1, 1);
    final summary = summarizeSessions([
      session('third', start.add(const Duration(days: 2)), 9),
      session('first', start, 3),
      session('second', start.add(const Duration(days: 1)), 6),
    ], StatsFilter.all);

    expect(summary.sessions.map((item) => item.id), [
      'first',
      'second',
      'third',
    ]);
    expect(summary.totalTaps, 18);
    expect(summary.bestSession, 9);
    expect(summary.averageTaps, 6);
  });

  test('summarizeSessions keeps the latest sessions for a range', () {
    final start = DateTime(2026, 1, 1);
    final source = List.generate(
      8,
      (index) => session('$index', start.add(Duration(days: index)), index + 1),
    ).reversed.toList();

    final summary = summarizeSessions(source, StatsFilter.last7);

    expect(summary.sessions.map((item) => item.id), [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
    ]);
    expect(summary.totalTaps, 35);
    expect(summary.bestSession, 8);
  });

  test('summarizeSessions handles empty and single-session ranges', () {
    final empty = summarizeSessions([], StatsFilter.all);
    expect(empty.sessions, isEmpty);
    expect(empty.averageTaps, 0);
    expect(empty.bestSession, 0);

    final one = summarizeSessions([
      session('one', DateTime(2026, 1, 1), 4),
    ], StatsFilter.last30);
    expect(one.sessions, hasLength(1));
    expect(one.averageTaps, 4);
  });

  testWidgets('empty stats fit a narrow, large-text display', (tester) async {
    await tester.pumpWidget(
      _statsApp(FakeRepository(), const Size(320, 800), textScale: 2),
    );

    expect(find.text('Complete a session to see your trend.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('7 sessions'), findsOneWidget);
    expect(find.text('30 sessions'), findsOneWidget);
    expect(find.text('All sessions'), findsOneWidget);
  });

  testWidgets('a single session renders a chart without an error', (
    tester,
  ) async {
    final repository = FakeRepository();
    final endedAt = DateTime(2026, 1, 2);
    repository.sessions['one'] = session('one', endedAt, 4);

    await tester.pumpWidget(_statsApp(repository, const Size(800, 700)));

    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _statsApp(
  FakeRepository repository,
  Size size, {
  double textScale = 1,
}) => MediaQuery(
  data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
  child: ProviderScope(
    overrides: [storageProvider.overrideWithValue(repository)],
    child: MaterialApp(theme: AppTheme.darkTheme, home: const StatsView()),
  ),
);
