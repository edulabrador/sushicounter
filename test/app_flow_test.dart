import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/main.dart';

import 'widget_test.dart' show FakeRepository;

class FailingRepository extends HiveRepository {
  @override
  Future<void> init({String? path}) =>
      Future<void>.error(StateError('storage unavailable'));
}

class FailingCompletionRepository extends FakeRepository {
  @override
  Future<Session> completeSession(Session session) =>
      Future<Session>.error(StateError('write failed'));
}

void main() {
  testWidgets(
    'full flow: tap sushi, end session, see it in history and stats',
    (tester) async {
      final repo = FakeRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageProvider.overrideWithValue(repo)],
          child: const SushiScoreApp(),
        ),
      );

      // Tap the sushi 3 times (hit the tappable area around the graphic).
      expect(find.text('Sushi Tracker'), findsOneWidget);
      expect(find.text('SUSHI SCORE'), findsNothing);
      final sushi = find.byType(GestureDetector).first;
      await tester.tap(sushi);
      await tester.tap(sushi);
      await tester.tap(sushi);
      await tester.pump();

      // Counter and session metric both show 3. Lifetime includes the active
      // session without mutating the saved total.
      expect(find.text('3'), findsNWidgets(2));
      expect(find.text('Lifetime total'), findsOneWidget);

      // End the session.
      await tester.tap(find.text('End Session'));
      await tester.pumpAndSettle();

      // Counter is back to 0 and Lifetime total remains 3.
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
      expect(repo.sessions.length, 1);

      // History tab shows the saved session.
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('No sessions yet.'), findsNothing);
      expect(find.byIcon(Icons.history), findsWidgets);

      // Stats tab shows updated KPIs.
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.text('Lifetime Taps'), findsOneWidget);
      expect(find.text('Lifetime Sessions'), findsOneWidget);
    },
  );

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

  testWidgets('visible Undo decrements once and is disabled at zero', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(FakeRepository())],
        child: const SushiScoreApp(),
      ),
    );

    final undo = find.widgetWithText(TextButton, 'Undo');
    expect(tester.widget<TextButton>(undo).onPressed, isNull);
    await tester.tap(find.byType(SushiButton));
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.tap(undo);
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Undo'), findsOneWidget);
  });

  testWidgets('lifetime total includes the active count without double counting', (tester) async {
    final repo = FakeRepository();
    await repo.adjustGlobalState(tapsDelta: 10, sessionsDelta: 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );
    final sushi = find.byType(SushiButton);
    await tester.tap(sushi);
    await tester.tap(sushi);
    await tester.tap(sushi);
    await tester.pump();
    expect(find.text('13'), findsOneWidget);
    expect(repo.getGlobalState().lifetimeTotalTaps, 10);

    await tester.tap(find.text('End Session'));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    expect(repo.getGlobalState().lifetimeTotalTaps, 13);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('restored timer advances and clears when session ends', (tester) async {
    final repo = FakeRepository();
    await repo.saveOngoingSession(2, DateTime.now().subtract(const Duration(seconds: 5)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );
    expect(find.text('00:05'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:06'), findsOneWidget);
    await tester.tap(find.text('End Session'));
    await tester.pump();
    await tester.pump();
    expect(find.text('00:06'), findsNothing);
  });

  testWidgets('ongoing session is restored into the UI after restart', (
    tester,
  ) async {
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

  testWidgets('sushi has a visible keyboard action without double counting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(FakeRepository())],
        child: const SushiScoreApp(),
      ),
    );

    final sushi = find.byType(SushiButton);
    await tester.tap(sushi);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(find.text('3'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Add one sushi'), findsOneWidget);
  });

  testWidgets('counter remains reachable on a large layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(FakeRepository())],
        child: const SushiScoreApp(),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('startup failure offers a retry screen', (tester) async {
    await tester.pumpWidget(
      StartupApp(createRepository: FailingRepository.new),
    );
    await tester.pump();

    expect(find.text('Could not open your saved data.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('save failure stays visible and leaves the session retryable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(FailingCompletionRepository()),
        ],
        child: const SushiScoreApp(),
      ),
    );

    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.tap(find.text('End Session'));
    await tester.pump();

    expect(
      find.text('Could not save this session. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('End Session'), findsOneWidget);
  });

  testWidgets('short, large-text layouts scroll instead of overflowing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 240));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1;
      tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(FakeRepository())],
        child: const SushiScoreApp(),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
