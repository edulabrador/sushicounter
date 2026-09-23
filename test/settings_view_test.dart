import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/settings/views/settings_view.dart';

import 'widget_test.dart' show FakeRepository;

class DelayedOngoingRepository extends FakeRepository {
  final gate = Completer<void>();

  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) async {
    await gate.future;
    await super.saveOngoingSession(count, startedAt);
  }
}

class DelayedCompletionRepository extends FakeRepository {
  final gate = Completer<void>();

  @override
  Future<Session> completeSession(Session session) async {
    await gate.future;
    return super.completeSession(session);
  }
}

class FailingOngoingRepository extends FakeRepository {
  @override
  Future<void> saveOngoingSession(int count, DateTime? startedAt) =>
      Future<void>.error(StateError('write failed'));
}

void main() {
  testWidgets('lifetime reset is disabled with an active session', (tester) async {
    final repository = FakeRepository();
    await repository.saveOngoingSession(2, DateTime.now());
    await tester.pumpWidget(_settings(repository));

    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Reset Lifetime Global'),
    );
    expect(tile.onTap, isNull);
    expect(find.text('End or reset the current session first.'), findsOneWidget);
  });

  testWidgets('lifetime reset is available with no active session', (tester) async {
    await tester.pumpWidget(_settings(FakeRepository()));

    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Reset Lifetime Global'),
    );
    expect(tile.onTap, isNotNull);
  });

  testWidgets('lifetime reset becomes available after ending a session', (tester) async {
    final repository = DelayedCompletionRepository();
    await tester.pumpWidget(_settings(repository));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsView)),
    );
    final notifier = container.read(counterProvider.notifier);
    notifier.increment();
    final completion = notifier.endSession();
    await tester.pump();

    expect(container.read(counterProvider).isEnding, isTrue);
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'Reset Lifetime Global')).onTap,
      isNull,
    );

    repository.gate.complete();
    await completion;
    await tester.pump();
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'Reset Lifetime Global')).onTap,
      isNotNull,
    );
  });

  testWidgets('typing RESET is still required and history remains', (tester) async {
    final repository = FakeRepository();
    final now = DateTime.now();
    await repository.completeSession(
      Session(
        id: 'kept-history',
        startedAt: now,
        endedAt: now,
        count: 4,
        durationSeconds: 0,
      ),
    );
    await tester.pumpWidget(_settings(repository));
    await tester.tap(find.widgetWithText(ListTile, 'Reset Lifetime Global'));
    await tester.pumpAndSettle();

    final confirm = find.widgetWithText(ElevatedButton, 'CONFIRM RESET');
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'RESET');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(repository.getGlobalState().lifetimeTotalTaps, 0);
    expect(repository.getGlobalState().lifetimeTotalSessions, 0);
    expect(repository.getAllSessions().map((item) => item.id), ['kept-history']);
  });

  testWidgets('lifetime reset is disabled while session reset is persisting', (tester) async {
    final repository = DelayedOngoingRepository();
    await tester.pumpWidget(_settings(repository));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsView)),
    );
    final reset = container.read(counterProvider.notifier).resetCurrent();
    await tester.pump();

    expect(container.read(counterProvider).isPersisting, isTrue);
    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Reset Lifetime Global'),
    );
    expect(tile.onTap, isNull);

    repository.gate.complete();
    await reset;
    await tester.pump();
  });

  testWidgets('lifetime reset is disabled while ongoing writes are pending', (tester) async {
    final repository = DelayedOngoingRepository();
    await tester.pumpWidget(_settings(repository));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsView)),
    );
    final notifier = container.read(counterProvider.notifier);
    notifier.increment();
    notifier.decrement();
    await tester.pump();

    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Reset Lifetime Global'),
    );
    expect(container.read(counterProvider).count, 0);
    expect(container.read(counterProvider).isSavingOngoing, isTrue);
    expect(tile.onTap, isNull);

    repository.gate.complete();
    await tester.pump();
    await tester.pump();
  });

  testWidgets('lifetime reset stays disabled when an ongoing write fails', (tester) async {
    await tester.pumpWidget(_settings(FailingOngoingRepository()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsView)),
    );
    final notifier = container.read(counterProvider.notifier);
    notifier.increment();
    notifier.decrement();
    await tester.pump();
    await tester.pump();

    expect(container.read(counterProvider).count, 0);
    expect(container.read(counterProvider).persistenceError, isNotNull);
    expect(
      tester.widget<ListTile>(find.widgetWithText(ListTile, 'Reset Lifetime Global')).onTap,
      isNull,
    );
  });
}

Widget _settings(FakeRepository repository) => ProviderScope(
  overrides: [storageProvider.overrideWithValue(repository)],
  child: const MaterialApp(home: SettingsView()),
);
