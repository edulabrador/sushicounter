import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/main.dart';

import 'widget_test.dart' show FakeRepository;

void main() {
  testWidgets('full flow: tap sushi, end session, see it in history and stats',
      (tester) async {
    final repo = FakeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );

    // Tap the sushi 3 times (hit the tappable area around the graphic).
    final sushi = find.byType(GestureDetector).first;
    await tester.tap(sushi);
    await tester.tap(sushi);
    await tester.tap(sushi);
    await tester.pump();

    // Counter and session card both show 3.
    expect(find.text('3'), findsNWidgets(2));

    // End the session.
    await tester.tap(find.text('End Session'));
    await tester.pumpAndSettle();

    // Counter is back to 0 and Global shows 3.
    expect(find.text('0'), findsNWidgets(2)); // giant counter + session card
    expect(find.text('3'), findsOneWidget); // global total
    expect(repo.sessions.length, 1);

    // History tab shows the saved session.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No sessions yet.'), findsNothing);
    expect(find.byIcon(Icons.history), findsWidgets);

    // Stats tab shows updated KPIs.
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Total Taps'), findsOneWidget);
    expect(find.text('Total Sessions'), findsOneWidget);
  });

  testWidgets('long-press on sushi decrements the counter', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(FakeRepository())],
        child: const SushiScoreApp(),
      ),
    );

    final sushi = find.byType(GestureDetector).first;
    await tester.tap(sushi);
    await tester.tap(sushi);
    await tester.pump();
    expect(find.text('2'), findsNWidgets(2));

    await tester.longPress(sushi);
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('ongoing session is restored into the UI after restart',
      (tester) async {
    final repo = FakeRepository();
    await repo.saveOngoingSession(7, DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );
    await tester.pump();

    expect(find.text('7'), findsNWidgets(2));
  });
}
