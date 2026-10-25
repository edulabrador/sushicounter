import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/home_widget.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/main.dart';
import 'package:sushiscore/shared/widgets/home_widget_sync.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

void main() {
  testWidgets('quick taps reach the home screen widget as one update', (
    tester,
  ) async {
    final updates = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(FakeRepository()),
          backupFilesProvider.overrideWithValue(FakeBackupFiles()),
          screenAwakeProvider.overrideWithValue((_) async {}),
          homeWidgetProvider.overrideWithValue((count) async {
            updates.add(count);
          }),
        ],
        child: const SushiScoreApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(updates, [0]);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(SushiButton));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(updates, [0]);
    await tester.pump(HomeWidgetSync.delay);
    expect(updates, [0, 5]);

    // Leaving the app sends the latest count straight away.
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(updates, [0, 5, 6]);
    await tester.pumpAndSettle();
    expect(updates, [0, 5, 6]);
  });

  test(
    'the channel carries the count and tolerates no widget support',
    () async {
      const channel = MethodChannel('dev.edulabrador.sushiscore/widget');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return null;
      });
      await updateHomeWidget(7);
      expect(received?.method, 'update');
      expect(received?.arguments, {'count': 7});

      messenger.setMockMethodCallHandler(channel, null);
      await updateHomeWidget(8); // MissingPluginException is swallowed.
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'boom'),
      );
      await updateHomeWidget(9);
    },
  );
}
