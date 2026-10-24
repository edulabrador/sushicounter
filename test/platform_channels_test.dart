import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/main.dart';
import 'package:sushiscore/shared/widgets/launch_action_controller.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

const filesChannel = MethodChannel('dev.edulabrador.sushiscore/files');
const screenChannel = MethodChannel('dev.edulabrador.sushiscore/screen');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mock(MethodChannel channel, Future<Object?> Function(MethodCall) fn) {
    messenger.setMockMethodCallHandler(channel, fn);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  group('BackupFiles', () {
    test('save sends the name and content and reports the outcome', () async {
      final calls = <MethodCall>[];
      Object? reply = true;
      mock(filesChannel, (call) async {
        calls.add(call);
        return reply;
      });
      const files = BackupFiles();
      expect(await files.save('a.json', '{}'), SaveOutcome.saved);
      expect(calls.single.method, 'exportFile');
      expect(calls.single.arguments, {'name': 'a.json', 'content': '{}'});
      reply = null;
      expect(await files.save('a.json', '{}'), SaveOutcome.cancelled);
    });

    test('a missing picker means unsupported; I/O errors surface', () async {
      var code = 'unavailable';
      mock(filesChannel, (call) async => throw PlatformException(code: code));
      const files = BackupFiles();
      expect(await files.save('a', 'b'), SaveOutcome.unsupported);
      expect((await files.open()).supported, isFalse);
      code = 'io';
      expect(files.save('a', 'b'), throwsA(isA<PlatformException>()));
      expect(files.open(), throwsA(isA<PlatformException>()));
    });

    test('open returns the text, or null when cancelled', () async {
      Object? reply = '{"format":1}';
      mock(filesChannel, (call) async {
        expect(call.method, 'importFile');
        return reply;
      });
      const files = BackupFiles();
      expect(await files.open(), (supported: true, text: '{"format":1}'));
      reply = null;
      expect(await files.open(), (supported: true, text: null));
    });

    test('platforms without the channel are unsupported', () async {
      const files = BackupFiles(MethodChannel('unregistered/test'));
      expect(await files.save('a', 'b'), SaveOutcome.unsupported);
      expect((await files.open()).supported, isFalse);
    });
  });

  test('screen awake calls the channel and never throws', () async {
    final values = <Object?>[];
    mock(screenChannel, (call) async {
      expect(call.method, 'setKeepScreenOn');
      values.add(call.arguments);
      if (values.length == 2) throw PlatformException(code: 'boom');
      return null;
    });
    await setKeepScreenOn(true);
    await setKeepScreenOn(false);
    expect(values, [true, false]);
  });

  group('launcher shortcut', () {
    Widget app(FakeRepository repo) => ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(repo),
        backupFilesProvider.overrideWithValue(FakeBackupFiles()),
        screenAwakeProvider.overrideWithValue((_) async {}),
      ],
      child: const SushiScoreApp(),
    );

    String? count(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(counterCurrentCountKey)).data;

    testWidgets('actions queued before start are applied once', (tester) async {
      var pending = <String>['addSushi', 'addSushi', 'somethingElse'];
      var takes = 0;
      mock(launchChannel, (call) async {
        expect(call.method, 'takePendingActions');
        takes++;
        final out = pending;
        pending = [];
        return out;
      });
      final repo = FakeRepository();
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      expect(count(tester), '2');
      expect(takes, 1);
      expect(repo.getOngoingCount(), 2);
    });

    testWidgets('a shortcut tap while the app runs is applied', (tester) async {
      var pending = <String>[];
      mock(launchChannel, (call) async {
        final out = pending;
        pending = [];
        return out;
      });
      await tester.pumpWidget(app(FakeRepository()));
      await tester.pumpAndSettle();
      expect(count(tester), '0');

      pending = ['addSushi'];
      await messenger.handlePlatformMessage(
        launchChannel.name,
        launchChannel.codec.encodeMethodCall(
          const MethodCall('actionAvailable'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(count(tester), '1');
    });

    testWidgets('shortcut taps are ignored while a save is pending', (
      tester,
    ) async {
      final repo = _FailingCompletion();
      await repo.saveOngoingSession(3, DateTime.now());
      var pending = <String>[];
      mock(launchChannel, (call) async {
        final out = pending;
        pending = [];
        return out;
      });
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CounterView)),
      );
      await expectLater(
        container.read(counterProvider.notifier).endSession(),
        throwsStateError,
      );
      pending = ['addSushi'];
      await messenger.handlePlatformMessage(
        launchChannel.name,
        launchChannel.codec.encodeMethodCall(
          const MethodCall('actionAvailable'),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(count(tester), '3');
    });
  });
}

class _FailingCompletion extends FakeRepository {
  @override
  Future<Session> completeSession(Session session) =>
      Future<Session>.error(StateError('write failed'));
}
