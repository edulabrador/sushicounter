import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/core/theme/app_theme.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/history/views/history_view.dart';
import 'package:sushiscore/features/stats/stats_logic.dart';
import 'package:sushiscore/main.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

import 'app_colors_test.dart' show contrast;
import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Session _session(String id, int count, DateTime endedAt) => Session(
  id: id,
  startedAt: endedAt.subtract(const Duration(minutes: 30)),
  endedAt: endedAt,
  count: count,
  durationSeconds: 1800,
);

Widget _app(FakeRepository repo) => ProviderScope(
  overrides: [
    storageProvider.overrideWithValue(repo),
    backupFilesProvider.overrideWithValue(FakeBackupFiles()),
    screenAwakeProvider.overrideWithValue((_) async {}),
  ],
  child: const SushiScoreApp(),
);

Future<List<int>> _render(CustomPainter painter, double size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(size));
  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes!.buffer.asUint8List();
}

void main() {
  _moreTests();
  group('sushi art', () {
    testWidgets('the happy nigiri is pixel-identical to the original drawing', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // Every size the counter button can take (96 to 200 px).
        for (final size in [96.0, 150.0, 200.0]) {
          final original = await _render(_OriginalSushiPainter(), size);
          final shared = await _render(const NigiriPainter(), size);
          expect(shared, original, reason: 'size $size');
        }
      });
    });

    testWidgets('every mood draws something different', (tester) async {
      await tester.runAsync(() async {
        final happy = await _render(const NigiriPainter(), 120);
        final sleepy = await _render(
          const NigiriPainter(mood: SushiMood.sleepy),
          120,
        );
        final starry = await _render(
          const NigiriPainter(mood: SushiMood.starry),
          120,
        );
        expect(sleepy, isNot(happy));
        expect(starry, isNot(happy));
        expect(starry, isNot(sleepy));
        final worried = await _render(
          const NigiriPainter(mood: SushiMood.worried),
          120,
        );
        expect(worried, isNot(happy));
        expect(worried, isNot(sleepy));
      });
    });

    test('repaints only when the mood changes', () {
      const happy = NigiriPainter();
      expect(happy.shouldRepaint(const NigiriPainter()), isFalse);
      expect(
        happy.shouldRepaint(const NigiriPainter(mood: SushiMood.starry)),
        isTrue,
      );
    });

    testWidgets('decorative art is hidden from screen readers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: SushiArt(size: 64))),
      );
      expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(child: SushiArt(size: 64, semanticLabel: 'Record')),
        ),
      );
      expect(find.bySemanticsLabel('Record'), findsOneWidget);
    });
  });

  test('text on the salmon accent is readable', () {
    const colors = AppColors.dark;
    expect(contrast(colors.onAccent, colors.accent), greaterThanOrEqualTo(4.5));
  });

  group('history grouping', () {
    test('adds a header per month with its totals', () {
      final entries = historyEntries([
        _session('c', 7, DateTime(2026, 10, 20, 21)),
        _session('b', 5, DateTime(2026, 10, 2, 21)),
        _session('a', 9, DateTime(2026, 9, 30, 21)),
      ]);
      expect(entries, hasLength(5));
      final october = entries[0] as MonthHeader;
      expect(october.month, DateTime(2026, 10));
      expect((october.sessions, october.pieces), (2, 12));
      expect((entries[1] as SessionEntry).session.id, 'c');
      expect((entries[2] as SessionEntry).session.id, 'b');
      final september = entries[3] as MonthHeader;
      expect((september.month, september.pieces), (DateTime(2026, 9), 9));
      expect((entries[4] as SessionEntry).session.id, 'a');
    });

    test('is empty without sessions', () {
      expect(historyEntries([]), isEmpty);
    });
  });

  group('weekly pieces', () {
    final now = DateTime(2026, 10, 21, 20); // Wednesday

    test('covers the last weeks, oldest first, ending this week', () {
      final weeks = weeklyPieces([
        _session('this', 10, DateTime(2026, 10, 19, 13)),
        _session('this2', 5, DateTime(2026, 10, 21, 13)),
        _session('last', 7, DateTime(2026, 10, 18, 21)),
        _session('old', 99, DateTime(2026, 6, 1)),
      ], now);
      expect(weeks, hasLength(8));
      expect(weeks.last.weekStart, DateTime(2026, 10, 19));
      expect(weeks.last.pieces, 15);
      expect(weeks[6].pieces, 7);
      expect(weeks.first.weekStart, DateTime(2026, 8, 31));
      expect(weeks.take(6).every((w) => w.pieces == 0), isTrue);
    });

    test('every week starts on a Monday', () {
      for (final week in weeklyPieces([], now, weeks: 30)) {
        expect(week.weekStart.weekday, DateTime.monday);
      }
    });
  });

  group('record progress on the counter', () {
    Future<void> tapTimes(WidgetTester tester, int times) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.byType(SushiButton));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('counts down to the record, then celebrates', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 5, DateTime(2026, 10, 1)));
      await tester.pumpWidget(_app(repo));
      expect(find.textContaining('Record 5'), findsNothing);

      await tapTimes(tester, 3);
      expect(find.text('Record 5 · 2 to go'), findsOneWidget);
      expect(
        tester.widget<SushiButton>(find.byType(SushiButton)).mood,
        SushiMood.happy,
      );

      await tapTimes(tester, 2);
      expect(find.text('You matched your record of 5!'), findsOneWidget);

      await tapTimes(tester, 1);
      expect(find.text('New record! Previous best: 5'), findsOneWidget);
      expect(
        tester.widget<SushiButton>(find.byType(SushiButton)).mood,
        SushiMood.starry,
      );
    });

    testWidgets('stays hidden before the first saved session', (tester) async {
      await tester.pumpWidget(_app(FakeRepository()));
      await tapTimes(tester, 2);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  testWidgets('history marks the record session with a starry nigiri', (
    tester,
  ) async {
    final repo = FakeRepository();
    await repo.completeSession(_session('small', 5, DateTime(2026, 10, 1)));
    await repo.completeSession(_session('best', 12, DateTime(2026, 10, 2)));
    await tester.pumpWidget(_app(repo));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Record'), findsOneWidget);
    final moods = tester
        .widgetList<SushiArt>(find.byType(SushiArt))
        .map((art) => art.mood);
    expect(moods.where((m) => m == SushiMood.starry), hasLength(1));
    expect(find.text('October 2026'), findsOneWidget);
  });

  testWidgets('empty history shows the sleepy nigiri', (tester) async {
    await tester.pumpWidget(_app(FakeRepository()));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SushiArt>(find.byType(SushiArt)).mood,
      SushiMood.sleepy,
    );
    expect(find.text('End a session and it will show up here.'), findsOne);
  });

  group('stats charts', () {
    testWidgets('trend marks the record and shows the average legend', (
      tester,
    ) async {
      final repo = FakeRepository();
      final start = DateTime.now().subtract(const Duration(days: 20));
      for (final (i, count) in [10, 30, 20].indexed) {
        await repo.completeSession(
          _session('$i', count, start.add(Duration(days: i * 5))),
        );
      }
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();

      expect(find.text('Avg 20.0'), findsOneWidget);
      final line = tester.widget<LineChart>(find.byType(LineChart));
      final bar = line.data.lineBarsData.single;
      expect(bar.isCurved, isTrue);
      final painters = [
        for (final (i, spot) in bar.spots.indexed)
          bar.dotData.getDotPainter(spot, 0, bar, i),
      ];
      expect(painters[1].getSize(bar.spots[1]), const Size.square(36));
      expect(painters[0], isA<FlDotCirclePainter>());
      expect(line.data.extraLinesData.horizontalLines.single.y, 20);
      expect(line.data.maxY, greaterThan(30));

      final weekly = tester.widget<BarChart>(find.byType(BarChart));
      expect(weekly.data.barGroups, hasLength(8));
      final pieces = [
        for (final group in weekly.data.barGroups) group.barRods.single.toY,
      ];
      expect(pieces.reduce((a, b) => a + b), 60);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty stats show the sleepy nigiri and no charts', (
      tester,
    ) async {
      await tester.pumpWidget(_app(FakeRepository()));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(BarChart), findsNothing);
      expect(
        tester
            .widgetList<SushiArt>(find.byType(SushiArt))
            .any((art) => art.mood == SushiMood.sleepy),
        isTrue,
      );
    });

    testWidgets('stats fit a narrow screen with large text', (tester) async {
      final repo = FakeRepository();
      await repo.completeSession(
        _session('a', 12, DateTime.now().subtract(const Duration(days: 1))),
      );
      await repo.setSessionPrice('a', 2000);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(() {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('Pieces this month'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -300),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

void _moreTests() {
  group('remaining screens', () {
    testWidgets('startup shows the nigiri while loading', (tester) async {
      await tester.pumpWidget(StartupApp(createRepository: _NeverOpens.new));
      await tester.pump();
      expect(find.byType(SushiArt), findsOneWidget);
      expect(find.text('Getting your sushi ready…'), findsOneWidget);
    });

    testWidgets('a startup failure shows the worried nigiri and retry', (
      tester,
    ) async {
      await tester.pumpWidget(StartupApp(createRepository: _FailsToOpen.new));
      await tester.pump();
      expect(
        tester.widget<SushiArt>(find.byType(SushiArt)).mood,
        SushiMood.worried,
      );
      expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    });

    testWidgets('settings are grouped in titled sections', (tester) async {
      await tester.pumpWidget(_app(FakeRepository()));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      for (final title in ['SESSION', 'PREFERENCES', 'YOUR DATA']) {
        expect(find.text(title), findsOneWidget);
      }
      await tester.scrollUntilVisible(find.text('ABOUT'), 200);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('session details show a tile per figure', (tester) async {
      final repo = FakeRepository();
      // 30 seconds: too short for a pace, and no price yet.
      await repo.completeSession(
        Session(
          id: 'quick',
          startedAt: DateTime(2026, 10, 2, 20),
          endedAt: DateTime(2026, 10, 2, 20, 0, 30),
          count: 4,
          durationSeconds: 30,
        ),
      );
      await tester.pumpWidget(_app(repo));
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duration: 00:30'));
      await tester.pumpAndSettle();

      Finder inSheet(String text) => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(text),
      );
      for (final label in ['Pieces', 'Duration', 'Pace', 'Price']) {
        expect(inSheet(label), findsOneWidget);
      }
      expect(inSheet('4'), findsOneWidget);
      expect(inSheet('00:30'), findsOneWidget);
      expect(inSheet('—'), findsNWidgets(2));
      expect(inSheet('20:00 – 20:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _NeverOpens extends HiveRepository {
  @override
  Future<void> init({String? path}) => Completer<void>().future;
}

class _FailsToOpen extends HiveRepository {
  @override
  Future<void> init({String? path}) =>
      Future<void>.error(StateError('storage unavailable'));
}

/// The drawing exactly as it shipped in 0.4.0 (sushi_button.dart), kept to
/// prove the shared art did not change the character.
class _OriginalSushiPainter extends CustomPainter {
  // Palette tuned to the friendly-nigiri look.
  static const _salmon = Color(0xFFF3986A);
  static const _salmonStripe = Color(0xFFF9C4A3);
  static const _rice = Color(0xFFF8F7F4);
  static const _riceShadow = Color(0xFFE6E4DE);
  static const _nori = Color(0xFF243528);
  static const _faceDark = Color(0xFF3A2A22);
  static const _cheek = Color(0xFFF3A6A0);
  static const _mouth = Color(0xFF7A3A2E);
  static const _tongue = Color(0xFFE87A6B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // --- Rice body ---
    final riceRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.16, s * 0.40, s * 0.68, s * 0.50),
      Radius.circular(s * 0.20),
    );
    // Soft drop shadow under the rice.
    canvas.drawRRect(
      riceRect.shift(Offset(0, s * 0.02)),
      Paint()
        ..color = _riceShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(riceRect, Paint()..color = _rice);

    // --- Salmon topping (drapes over the top of the rice) ---
    final salmonRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(s * 0.12, s * 0.24, s * 0.76, s * 0.26),
      topLeft: Radius.circular(s * 0.16),
      topRight: Radius.circular(s * 0.16),
      bottomLeft: Radius.circular(s * 0.11),
      bottomRight: Radius.circular(s * 0.11),
    );
    canvas.drawRRect(salmonRect, Paint()..color = _salmon);

    // Salmon marbling stripes.
    canvas.save();
    canvas.clipRRect(salmonRect);
    final stripePaint = Paint()
      ..color = _salmonStripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.028
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = s * (0.30 + i * 0.055);
      final path = Path()
        ..moveTo(s * 0.13, y)
        ..quadraticBezierTo(s * 0.5, y - s * 0.03, s * 0.87, y);
      canvas.drawPath(path, stripePaint);
    }
    canvas.restore();

    // --- Nori band (vertical wrap, right of the face) ---
    final noriRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.55, s * 0.245, s * 0.16, s * 0.655),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(noriRect, Paint()..color = _nori);

    // --- Face on the rice (left of the nori) ---
    final eyePaint = Paint()
      ..color = _faceDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round;
    // Happy closed "smiling" eyes (bottom arcs).
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.30, s * 0.60), radius: s * 0.045),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      eyePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(s * 0.45, s * 0.60), radius: s * 0.045),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      eyePaint,
    );

    // Rosy cheeks.
    final cheekPaint = Paint()..color = _cheek;
    canvas.drawCircle(Offset(s * 0.245, s * 0.685), s * 0.028, cheekPaint);
    canvas.drawCircle(Offset(s * 0.505, s * 0.685), s * 0.028, cheekPaint);

    // Open happy mouth with a little tongue.
    final mouthRect = Rect.fromCircle(
      center: Offset(s * 0.375, s * 0.675),
      radius: s * 0.05,
    );
    final mouthPath = Path()
      ..addArc(mouthRect, 0, math.pi)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = _mouth);
    canvas.save();
    canvas.clipPath(mouthPath);
    canvas.drawCircle(
      Offset(s * 0.375, s * 0.715),
      s * 0.022,
      Paint()..color = _tongue,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OriginalSushiPainter oldDelegate) => false;
}
