import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/counter/widgets/session_timer.dart';
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

class FailingOngoingRepository extends FakeRepository {
  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) =>
      Future<void>.error(StateError('ongoing write failed'));
}

class FailsOnceOngoingRepository extends FakeRepository {
  var _failed = false;

  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) async {
    if (!_failed) {
      _failed = true;
      throw StateError('temporary ongoing write failure');
    }
    await super.saveOngoingSession(count, startedAt);
  }
}

class FailsOnceCompletionRepository extends FakeRepository {
  final requestedSessionIds = <String>[];

  @override
  Future<Session> completeSession(Session session) async {
    requestedSessionIds.add(session.id);
    if (requestedSessionIds.length == 1) {
      throw StateError('temporary write failure');
    }
    return super.completeSession(session);
  }
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
      expect(find.text('Sushi Score'), findsNothing);
      final sushi = find.byType(GestureDetector).first;
      await tester.tap(sushi);
      await tester.tap(sushi);
      await tester.tap(sushi);
      await tester.pump();

      // Counter and session metric both show 3. Lifetime includes the active
      // session without mutating the saved total.
      expect(_textValue(tester, counterCurrentCountKey), '3');
      expect(_textValue(tester, counterSessionTotalKey), '3');
      expect(_textValue(tester, counterLifetimeTotalKey), '3');

      // End the session.
      await tester.tap(find.byKey(counterEndSessionButtonKey));
      await tester.pumpAndSettle();

      // Counter is back to 0 and Lifetime total remains 3.
      expect(_textValue(tester, counterCurrentCountKey), '0');
      expect(_textValue(tester, counterSessionTotalKey), '0');
      expect(_textValue(tester, counterLifetimeTotalKey), '3');
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
    expect(_textValue(tester, counterCurrentCountKey), '2');

    await tester.longPress(sushi);
    await tester.pump();
    expect(_textValue(tester, counterCurrentCountKey), '1');
  });

  testWidgets('End Session remains retryable with the same session ID', (tester) async {
    final repo = FailsOnceCompletionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pumpAndSettle();

    expect(_textValue(tester, counterCurrentCountKey), '1');
    expect(
      tester.widget<SushiButton>(find.byType(SushiButton)).enabled,
      isFalse,
    );
    expect(
      tester.widget<TextButton>(find.byKey(counterUndoButtonKey)).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(counterEndSessionButtonKey)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pumpAndSettle();
    expect(repo.requestedSessionIds, hasLength(2));
    expect(repo.requestedSessionIds[1], repo.requestedSessionIds[0]);
    expect(repo.sessions, hasLength(1));
    expect(repo.getGlobalState().lifetimeTotalTaps, 1);
    expect(repo.getGlobalState().lifetimeTotalSessions, 1);
  });

  testWidgets('visible Undo decrements once and is disabled at zero', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(FakeRepository())],
        child: const SushiScoreApp(),
      ),
    );

    final undo = find.byKey(counterUndoButtonKey);
    expect(tester.widget<TextButton>(undo).onPressed, isNull);
    await tester.tap(find.byType(SushiButton));
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.tap(undo);
    await tester.pump();
    expect(_textValue(tester, counterCurrentCountKey), '1');
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
    expect(_textValue(tester, counterLifetimeTotalKey), '13');
    expect(_textValue(tester, counterSessionTotalKey), '3');
    expect(repo.getGlobalState().lifetimeTotalTaps, 10);

    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pumpAndSettle();
    expect(_textValue(tester, counterLifetimeTotalKey), '13');
    expect(repo.getGlobalState().lifetimeTotalTaps, 13);
    expect(_textValue(tester, counterCurrentCountKey), '0');
    expect(_textValue(tester, counterSessionTotalKey), '0');
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
    expect(_textValue(tester, counterElapsedTimeKey), '00:05');
    await tester.pump(const Duration(seconds: 1));
    expect(_textValue(tester, counterElapsedTimeKey), '00:06');
    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(counterElapsedTimeKey), findsNothing);
  });

  testWidgets('timer recalculates elapsed time after app resume', (tester) async {
    var now = DateTime(2026, 9, 23, 12);
    final startedAt = now.subtract(const Duration(seconds: 5));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionElapsedTimer(startedAt: startedAt, now: () => now),
        ),
      ),
    );
    expect(_textValue(tester, counterElapsedTimeKey), '00:05');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(_textValue(tester, counterElapsedTimeKey), '00:13');
  });

  testWidgets('Undo to zero clears the timer and starts the next session fresh', (tester) async {
    final repo = FakeRepository();
    await repo.saveOngoingSession(
      1,
      DateTime.now().subtract(const Duration(minutes: 1)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );
    expect(find.byKey(counterElapsedTimeKey), findsOneWidget);
    await tester.tap(find.byKey(counterUndoButtonKey));
    await tester.pump();
    expect(find.byKey(counterElapsedTimeKey), findsNothing);
    expect(_textValue(tester, counterCurrentCountKey), '0');
  });

  testWidgets('resetting the current session clears the timer', (tester) async {
    final repo = FakeRepository();
    await repo.saveOngoingSession(2, DateTime.now());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );
    expect(find.byKey(counterElapsedTimeKey), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CounterView)),
    );
    await container.read(counterProvider.notifier).resetCurrent();
    await tester.pump();
    expect(find.byKey(counterElapsedTimeKey), findsNothing);
    expect(_textValue(tester, counterCurrentCountKey), '0');
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

    expect(_textValue(tester, counterCurrentCountKey), '7');
    expect(_textValue(tester, counterSessionTotalKey), '7');
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

    expect(_textValue(tester, counterCurrentCountKey), '3');
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
    expect(_textValue(tester, counterCurrentCountKey), '1');
  });

  testWidgets('primary session controls fit common phone layouts', (tester) async {
    const sizes = [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(1000, 900),
    ];
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(size),
          overrides: [storageProvider.overrideWithValue(FakeRepository())],
          child: const SushiScoreApp(),
        ),
      );
      await tester.tap(find.byType(SushiButton));
      await tester.pump();

      final action = tester.getRect(find.byKey(counterEndSessionButtonKey));
      expect(action.bottom, lessThanOrEqualTo(size.height - 80));
      await tester.tap(find.byKey(counterEndSessionButtonKey));
      await tester.pumpAndSettle();
      expect(_textValue(tester, counterCurrentCountKey), '0');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('primary controls remain scrollable with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
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
    await tester.ensureVisible(find.byType(SushiButton));
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.ensureVisible(find.byKey(counterEndSessionButtonKey));
    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pumpAndSettle();
    expect(_textValue(tester, counterCurrentCountKey), '0');
    expect(tester.takeException(), isNull);
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
    await tester.ensureVisible(find.byKey(counterEndSessionButtonKey));
    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pump();

    expect(
      find.text('Could not save this session. Please try again.'),
      findsOneWidget,
    );
    expect(_textValue(tester, counterCurrentCountKey), '1');
    expect(
      tester.widget<FilledButton>(find.byKey(counterEndSessionButtonKey)).onPressed,
      isNotNull,
    );
  });

  testWidgets('ongoing storage failure preserves the active count', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(FailingOngoingRepository())],
        child: const SushiScoreApp(),
      ),
    );
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.pump();

    expect(_textValue(tester, counterCurrentCountKey), '1');
    expect(
      find.text('Could not save the current session.'),
      findsOneWidget,
    );
  });

  testWidgets('a later ongoing save clears the storage error', (tester) async {
    final repo = FailsOnceOngoingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(repo)],
        child: const SushiScoreApp(),
      ),
    );
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.pump();
    expect(find.text('Could not save the current session.'), findsOneWidget);

    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.pump();
    expect(find.text('Could not save the current session.'), findsNothing);
    expect(_textValue(tester, counterCurrentCountKey), '2');
    expect(repo.getOngoingCount(), 2);
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

String? _textValue(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data;
