// Pixel snapshots of the main screens in both themes. Text renders in the
// test font (boxes), so these catch layout, color and drawing changes.
// After an intended visual change, regenerate them with:
//   flutter test --update-goldens test/goldens_test.dart
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/preferences.dart';
import 'package:sushiscore/features/history/widgets/share_session_dialog.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'test_app.dart';
import 'widget_test.dart' show FakeRepository;

final _now = DateTime(2026, 10, 24, 21, 30);

Future<FakeRepository> _sampleRepository(Appearance appearance) async {
  final repo = FakeRepository()
    ..preferences = InMemoryPreferences(appearance: appearance);
  const counts = [18, 24, 12, 31, 22, 27, 16, 35, 20, 26];
  const places = ['Sakura', 'Koi', 'Sakura', 'Umi', 'Koi'];
  for (var i = 0; i < counts.length; i++) {
    final endedAt = _now.subtract(Duration(days: i * 5 + 1, hours: i % 3));
    await repo.completeSession(
      Session(
        id: 's$i',
        startedAt: endedAt.subtract(const Duration(minutes: 50)),
        endedAt: endedAt,
        count: counts[i],
        durationSeconds: 3000,
        priceCents: i.isEven ? 2490 + i * 50 : null,
        restaurant: places[i % places.length],
      ),
    );
  }
  await repo.saveOngoingSession(9, _now.subtract(const Duration(minutes: 23)));
  return repo;
}

Future<void> _pumpApp(WidgetTester tester, FakeRepository repo) async {
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

void main() {
  for (final appearance in [Appearance.dark, Appearance.light]) {
    final name = appearance.name;

    testWidgets('main screens look right in the $name theme', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await withClock(Clock.fixed(_now), () async {
        await _pumpApp(tester, await _sampleRepository(appearance));
        await expectLater(
          find.byType(SushiScoreApp),
          matchesGoldenFile('goldens/counter_$name.png'),
        );

        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(SushiScoreApp),
          matchesGoldenFile('goldens/history_$name.png'),
        );

        await tester.tap(find.byIcon(Icons.bar_chart));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(SushiScoreApp),
          matchesGoldenFile('goldens/stats_$name.png'),
        );

        await tester.tap(find.byIcon(Icons.touch_app));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(SushiScoreApp),
          matchesGoldenFile('goldens/settings_$name.png'),
        );
      });
    });
  }

  testWidgets('the shared session card', (tester) async {
    final ended = DateTime(2026, 10, 24, 21, 30);
    await tester.pumpWidget(
      localizedTestApp(
        Center(
          child: RepaintBoundary(
            child: SessionShareCard(
              session: Session(
                id: 'a',
                startedAt: ended.subtract(const Duration(minutes: 52)),
                endedAt: ended,
                count: 41,
                durationSeconds: 3120,
                priceCents: 2490,
                restaurant: 'Sakura',
              ),
              isRecord: true,
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(SessionShareCard),
      matchesGoldenFile('goldens/share_card.png'),
    );
  });
}
