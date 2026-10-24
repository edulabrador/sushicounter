import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/main.dart';
import 'package:sushiscore/shared/widgets/launch_action_controller.dart';

/// Runs the real app on a device or emulator: real Hive storage, real
/// Android method channels. CI runs it on an emulator.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const screen = MethodChannel('dev.edulabrador.sushiscore/screen');

  String? count(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(counterCurrentCountKey)).data;

  testWidgets('count, keep the screen on, save, and find it in history', (
    tester,
  ) async {
    await tester.pumpWidget(const StartupApp());
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CounterView)),
    );
    final repository = container.read(storageProvider);
    final sessionsBefore = repository.getAllSessions().length;
    final start = int.parse(count(tester)!);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(SushiButton));
      await tester.pump(const Duration(milliseconds: 600));
    }
    await tester.pumpAndSettle();
    expect(count(tester), '${start + 3}');
    expect(repository.getOngoingCount(), start + 3);

    // The Kotlin side really set FLAG_KEEP_SCREEN_ON on the window.
    expect(await screen.invokeMethod<bool>('isKeepScreenOn'), isTrue);

    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pumpAndSettle();
    expect(count(tester), '0');
    expect(await screen.invokeMethod<bool>('isKeepScreenOn'), isFalse);
    expect(repository.getAllSessions(), hasLength(sessionsBefore + 1));
    expect(repository.getAllSessions().first.count, start + 3);
    expect(repository.getOngoingCount(), 0);

    // The launcher-shortcut channel is wired and starts empty.
    expect(
      await launchChannel.invokeListMethod<String>('takePendingActions'),
      isEmpty,
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No sessions yet.'), findsNothing);
  });
}
