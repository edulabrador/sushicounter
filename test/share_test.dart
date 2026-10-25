import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/image_sharer.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/features/history/widgets/share_session_dialog.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'test_app.dart';
import 'widget_test.dart' show FakeRepository;

class FakeSharer extends ImageSharer {
  FakeSharer({this.supported = true, this.fail = false});

  final bool supported;
  final bool fail;
  final shares = <({Uint8List png, String name, String text})>[];

  @override
  Future<bool> share({
    required Uint8List png,
    required String name,
    required String text,
    required String title,
  }) async {
    if (fail) throw PlatformException(code: 'io');
    if (!supported) return false;
    shares.add((png: png, name: name, text: text));
    return true;
  }
}

final _ended = DateTime(2026, 10, 24, 21, 30);

Session _session({String? restaurant, int count = 12}) => Session(
  id: 'a',
  startedAt: _ended.subtract(const Duration(minutes: 40)),
  endedAt: _ended,
  count: count,
  durationSeconds: 2400,
  priceCents: 2490,
  restaurant: restaurant,
);

Future<void> _openShare(
  WidgetTester tester,
  ImageSharer sharer, {
  String? restaurant,
}) async {
  final repo = FakeRepository();
  await repo.completeSession(_session(restaurant: restaurant));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(repo),
        backupFilesProvider.overrideWithValue(FakeBackupFiles()),
        screenAwakeProvider.overrideWithValue((_) async {}),
        imageSharerProvider.overrideWithValue(sharer),
      ],
      child: const SushiScoreApp(),
    ),
  );
  await tester.tap(find.text('History'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Duration: 40:00'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Share session'));
  await tester.pumpAndSettle();
}

Future<void> _tapShare(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.widgetWithText(FilledButton, 'Share'));
    // Let the image capture and encoding finish outside fake time.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
      if (find.byType(ShareSessionDialog).evaluate().isEmpty) break;
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  group('image sharer channel', () {
    const channel = MethodChannel('test/share');
    final calls = <MethodCall>[];
    Object? Function(MethodCall)? answer;

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return answer?.call(call);
          });
    });

    Future<bool> share() => const ImageSharer(channel).share(
      png: Uint8List.fromList([1, 2]),
      name: 'a.png',
      text: 'hi',
      title: 'Share',
    );

    test('sends the image, its name and the text', () async {
      answer = (_) => true;
      expect(await share(), isTrue);
      expect(calls.single.method, 'shareImage');
      final args = calls.single.arguments as Map;
      expect(args['bytes'], [1, 2]);
      expect(args['name'], 'a.png');
      expect(args['text'], 'hi');
    });

    test('reports unavailable sharing and rethrows real errors', () async {
      answer = (_) => throw PlatformException(code: 'unavailable');
      expect(await share(), isFalse);
      answer = (_) => throw PlatformException(code: 'io');
      expect(share, throwsA(isA<PlatformException>()));
    });

    test('a platform without the channel is unsupported', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(await share(), isFalse);
    });
  });

  testWidgets('shares a 1080 px PNG of the card with a summary', (
    tester,
  ) async {
    final sharer = FakeSharer();
    await _openShare(tester, sharer, restaurant: 'Koi');
    expect(find.byType(SessionShareCard), findsOneWidget);
    await _tapShare(tester);

    final share = sharer.shares.single;
    expect(share.name, 'sushi-session-20261024-2130.png');
    expect(
      share.text,
      'I ate 12 pieces of sushi at Koi on Oct 24, 2026. '
      'Counted with Sushi Tracker.',
    );
    // PNG signature, then the width in the IHDR chunk.
    expect(share.png.sublist(1, 4), 'PNG'.codeUnits);
    expect(ByteData.sublistView(share.png).getUint32(16), 1080);
    expect(find.byType(ShareSessionDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('copies the summary where images cannot be shared', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await _openShare(tester, FakeSharer(supported: false));
    await _tapShare(tester);
    expect(
      copied,
      'I ate 12 pieces of sushi on Oct 24, 2026. '
      'Counted with Sushi Tracker.',
    );
    expect(find.text('Summary copied to the clipboard.'), findsOneWidget);
  });

  testWidgets('says so when sharing fails', (tester) async {
    await _openShare(tester, FakeSharer(fail: true));
    await _tapShare(tester);
    expect(find.text('Could not share the session.'), findsOneWidget);
  });

  testWidgets('the card reads in Spanish too', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        Center(
          child: SessionShareCard(
            session: _session(count: 1, restaurant: 'Umi'),
            isRecord: true,
          ),
        ),
        locale: const Locale('es'),
      ),
    );
    expect(find.text('pieza'), findsOneWidget);
    expect(find.text('Récord'), findsOneWidget);
    expect(find.text('Umi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
