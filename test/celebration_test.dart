import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Future<void> _pumpWithRecord(WidgetTester tester, int record) async {
  final repo = FakeRepository();
  final end = DateTime.now().subtract(const Duration(days: 1));
  await repo.completeSession(
    Session(
      id: 'best',
      startedAt: end.subtract(const Duration(hours: 1)),
      endedAt: end,
      count: record,
      durationSeconds: 3600,
    ),
  );
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

Future<void> _tap(WidgetTester tester) async {
  await tester.tap(find.byType(SushiButton));
  await tester.pump(const Duration(milliseconds: 100));
}

List<String> _haptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  return calls;
}

void main() {
  testWidgets('beating the record celebrates once, then goes away', (
    tester,
  ) async {
    final haptics = _haptics(tester);
    await _pumpWithRecord(tester, 3);
    for (var i = 0; i < 3; i++) {
      await _tap(tester);
    }
    await tester.pumpAndSettle();
    expect(find.text('New record!'), findsNothing);
    expect(haptics, isNot(contains('HapticFeedbackType.heavyImpact')));

    await _tap(tester);
    expect(find.text('New record!'), findsOneWidget);
    expect(haptics.last, 'HapticFeedbackType.heavyImpact');

    await tester.pumpAndSettle();
    expect(find.text('New record!'), findsNothing);

    // Further taps do not celebrate again.
    await _tap(tester);
    expect(find.text('New record!'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('no celebration without a saved record', (tester) async {
    await _pumpWithRecord(tester, 0);
    await _tap(tester);
    expect(find.text('New record!'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('each tap floats a +1 that disappears', (tester) async {
    await _pumpWithRecord(tester, 50);
    await _tap(tester);
    await _tap(tester);
    expect(find.text('+1'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('+1'), findsNothing);
  });

  testWidgets('reduced motion keeps the badge but drops the motion', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpWithRecord(tester, 1);
    await _tap(tester);
    await _tap(tester);
    expect(find.text('+1'), findsNothing);
    expect(find.text('New record!'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
