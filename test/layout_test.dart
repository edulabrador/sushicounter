import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/settings/views/settings_view.dart';
import 'package:sushiscore/features/stats/widgets/trend_chart.dart';
import 'package:sushiscore/features/stats/widgets/weekly_chart.dart';
import 'package:sushiscore/main.dart';
import 'package:sushiscore/shared/widgets/bottom_nav.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  FakeViewPadding padding = FakeViewPadding.zero,
  Locale? locale,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (locale != null) tester.platformDispatcher.localeTestValue = locale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final repo = FakeRepository();
  for (var i = 0; i < 4; i++) {
    final end = DateTime.now().subtract(Duration(days: 2 + i * 6));
    await repo.completeSession(
      Session(
        id: 's$i',
        startedAt: end.subtract(const Duration(hours: 1)),
        endedAt: end,
        count: 20 + i,
        durationSeconds: 3600,
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
  await tester.pumpAndSettle();
}

void main() {
  test('the rail is for tablets and sideways phones', () {
    expect(RootNavigation.useRail(const Size(390, 844)), isFalse);
    expect(RootNavigation.useRail(const Size(800, 600)), isFalse);
    expect(RootNavigation.useRail(const Size(844, 390)), isTrue);
    expect(RootNavigation.useRail(const Size(1280, 800)), isTrue);
  });

  testWidgets('a phone held upright uses the bottom bar', (tester) async {
    await _pump(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('sideways, the counter splits into two columns beside a rail', (
    tester,
  ) async {
    await _pump(tester, const Size(844, 390));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final nigiri = tester.getCenter(find.byType(SushiButton));
    final total = tester.getCenter(find.byKey(counterSessionTotalKey));
    expect(nigiri.dx, lessThan(total.dx));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('on a tablet the charts sit side by side', (tester) async {
    await _pump(tester, const Size(1280, 800));
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    final trend = tester.getTopLeft(find.byType(TrendChart));
    final weekly = tester.getTopLeft(find.byType(WeeklyChart));
    expect(weekly.dx, greaterThan(trend.dx));
    expect((weekly.dy - trend.dy).abs(), lessThan(80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('content stays clear of the system bars and the cutout', (
    tester,
  ) async {
    // Physical pixels at a device pixel ratio of 2: a 30 dp cutout on the
    // left of a sideways phone and a 24 dp gesture bar at the bottom.
    await _pump(
      tester,
      const Size(844, 390),
      padding: const FakeViewPadding(left: 60, top: 48, bottom: 48),
    );
    expect(tester.getTopLeft(find.byType(NavigationRail)).dx, 30);
    final count = tester.getRect(find.byKey(counterCurrentCountKey));
    expect(count.top, greaterThanOrEqualTo(24));
    final end = tester.getRect(find.byKey(counterEndSessionButtonKey));
    expect(end.bottom, lessThanOrEqualTo(390 - 24));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    final settings = find.byType(SettingsView);
    await tester.drag(
      find.descendant(of: settings, matching: find.byType(ListView)),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    final last = tester
        .renderObjectList<RenderBox>(
          find.descendant(of: settings, matching: find.byType(Card)),
        )
        .map((box) => box.localToGlobal(Offset.zero).dy + box.size.height)
        .reduce((a, b) => a > b ? a : b);
    expect(last, lessThanOrEqualTo(390 - 24));
  });

  testWidgets('Spanish with large text fits sideways', (tester) async {
    await _pump(
      tester,
      const Size(780, 360),
      locale: const Locale('es'),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
