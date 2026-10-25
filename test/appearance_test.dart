import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/core/storage/preferences.dart';
import 'package:sushiscore/core/theme/app_theme.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

void main() {
  group('stored appearance', () {
    late Directory directory;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('sushiscore_look_');
    });
    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('defaults to dark, persists, and ignores unknown values', () async {
      var repo = HiveRepository();
      await repo.init(path: directory.path);
      expect(repo.preferences.appearance, Appearance.dark);
      await repo.preferences.setAppearance(Appearance.system);
      await Hive.close();

      repo = HiveRepository();
      await repo.init(path: directory.path);
      expect(repo.preferences.appearance, Appearance.system);
      await Hive.box('app_state').put('appearance', 'neon');
      expect(repo.preferences.appearance, Appearance.dark);
    });
  });

  testWidgets('choosing Light in settings recolors the app', (tester) async {
    final repo = FakeRepository();
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
    MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.dark);
    Color background() => Theme.of(
      tester.element(find.byType(Scaffold).first),
    ).scaffoldBackgroundColor;
    expect(background(), AppColors.dark.background);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(repo.preferences.appearance, Appearance.light);
    expect(app().themeMode, ThemeMode.light);
    expect(background(), AppColors.light.background);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(app().themeMode, ThemeMode.system);
  });
}
