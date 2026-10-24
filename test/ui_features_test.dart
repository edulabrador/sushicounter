import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/backup_files.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/backup.dart';
import 'package:sushiscore/features/counter/views/counter_view.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/settings/views/sections/data_section.dart';
import 'package:sushiscore/main.dart';

import 'fakes.dart';
import 'widget_test.dart' show FakeRepository;

Session _session(
  String id,
  int count, {
  required DateTime endedAt,
  int? priceCents,
  int durationSeconds = 1800,
}) => Session(
  id: id,
  startedAt: endedAt.subtract(Duration(seconds: durationSeconds)),
  endedAt: endedAt,
  count: count,
  durationSeconds: durationSeconds,
  priceCents: priceCents,
);

Widget _app(FakeRepository repo, {BackupFiles? files}) => ProviderScope(
  overrides: [
    storageProvider.overrideWithValue(repo),
    backupFilesProvider.overrideWithValue(files ?? FakeBackupFiles()),
    screenAwakeProvider.overrideWithValue((_) async {}),
  ],
  child: const SushiScoreApp(),
);

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

void _useRegion(WidgetTester tester, Locale locale) {
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.localeTestValue = locale;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
}

void main() {
  final recent = DateTime.now().subtract(const Duration(hours: 2));

  group('session price', () {
    testWidgets('can be added, edited and removed from the details', (
      tester,
    ) async {
      _useRegion(tester, const Locale('en', 'US'));
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 20, endedAt: recent));
      await tester.pumpWidget(_app(repo));
      await _openTab(tester, 'History');
      await tester.tap(find.text('Duration: 30:00'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add price'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an amount between 0 and 100,000.'), findsOne);

      await tester.enterText(find.byType(TextField), '24.90');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.sessions['a']!.priceCents, 2490);
      expect(find.text(r'Price: $24.90'), findsOneWidget);

      await tester.tap(find.text('Edit price'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '24.90',
      );
      await tester.tap(find.text('Remove price'));
      await tester.pumpAndSettle();
      expect(repo.sessions['a']!.priceCents, isNull);
      expect(find.textContaining('Price:'), findsNothing);
      expect(find.text('Add price'), findsOneWidget);
    });

    testWidgets('Spanish input and euro display', (tester) async {
      _useRegion(tester, const Locale('es', 'ES'));
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 20, endedAt: recent));
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await _openTab(tester, 'Historial');
      await tester.tap(find.text('Duración: 30:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Añadir precio'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '24,90');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Precio: 24,90 €'), findsOneWidget);
    });

    testWidgets('stats show cost per piece only for priced sessions', (
      tester,
    ) async {
      _useRegion(tester, const Locale('en', 'US'));
      final repo = FakeRepository();
      await repo.completeSession(_session('a', 20, endedAt: recent));
      await tester.pumpWidget(_app(repo));
      await _openTab(tester, 'Stats');
      expect(find.textContaining('Cost per piece'), findsNothing);

      await repo.setSessionPrice('a', 3000);
      await repo.completeSession(
        _session('b', 50, endedAt: recent.add(const Duration(minutes: 1))),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      );
      await _reloadAll(container);
      await tester.pumpAndSettle();
      expect(find.text('Cost per piece (All sessions)'), findsOneWidget);
      // 30.00 over the 20 pieces of the only priced session.
      expect(find.text(r'$1.50'), findsOneWidget);
    });
  });

  group('stats records and chart', () {
    testWidgets('records reflect the current lifetime', (tester) async {
      final repo = FakeRepository();
      final now = DateTime.now();
      await repo.completeSession(_session('a', 12, endedAt: recent));
      await repo.completeSession(
        _session('b', 30, endedAt: now.subtract(const Duration(days: 7))),
      );
      await tester.pumpWidget(_app(repo));
      await _openTab(tester, 'Stats');
      await tester.ensureVisible(find.text('Records'));
      expect(find.text('Best session'), findsOneWidget);
      expect(find.text('2 weeks'), findsOneWidget);
      expect(find.text('Sessions this month'), findsOneWidget);
    });

    testWidgets('chart places sessions on a date axis', (tester) async {
      final repo = FakeRepository();
      final start = DateTime(2026, 1, 1, 21);
      for (final (id, days) in [('a', 0), ('b', 1), ('c', 40)]) {
        await repo.completeSession(
          _session(id, 10 + days, endedAt: start.add(Duration(days: days))),
        );
      }
      await tester.pumpWidget(_app(repo));
      await _openTab(tester, 'Stats');
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final spots = chart.data.lineBarsData.single.spots;
      expect(spots.map((s) => s.x), [0, 1, 40]);
      expect(chart.data.minX, 0);
      expect(chart.data.maxX, 40);
      expect(tester.takeException(), isNull);
    });

    testWidgets('several sessions on one day still render a usable chart', (
      tester,
    ) async {
      final repo = FakeRepository();
      final day = DateTime(2026, 1, 1, 13);
      await repo.completeSession(_session('a', 5, endedAt: day));
      await repo.completeSession(
        _session('b', 9, endedAt: day.add(const Duration(hours: 6))),
      );
      await tester.pumpWidget(_app(repo));
      await _openTab(tester, 'Stats');
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.maxX - chart.data.minX, 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('backup files', () {
    testWidgets('export saves a dated, valid file', (tester) async {
      final files = FakeBackupFiles(supported: true);
      final repo = FakeRepository();
      await repo.completeSession(
        _session('a', 7, endedAt: recent, priceCents: 1999),
      );
      await tester.pumpWidget(_app(repo, files: files));
      await _openSettings(tester);
      await tester.tap(find.text('Export data'));
      await tester.pumpAndSettle();

      final saved = files.saved.single;
      expect(saved.name, backupFileName(DateTime.now()));
      expect(
        saved.name,
        matches(RegExp(r'^sushi-tracker-\d{4}-\d\d-\d\d\.json$')),
      );
      final backup = decodeBackup(saved.content);
      expect(backup.sessions.single.priceCents, 1999);
      expect(find.text('Backup of 1 session saved.'), findsOneWidget);
    });

    testWidgets('cancelling the save shows nothing', (tester) async {
      final files = FakeBackupFiles(supported: true, cancel: true);
      await tester.pumpWidget(_app(FakeRepository(), files: files));
      await _openSettings(tester);
      await tester.tap(find.text('Export data'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a failed save is reported', (tester) async {
      final files = FakeBackupFiles(supported: true, fail: true);
      await tester.pumpWidget(_app(FakeRepository(), files: files));
      await _openSettings(tester);
      await tester.tap(find.text('Export data'));
      await tester.pumpAndSettle();
      expect(find.text('Could not save the file.'), findsOneWidget);
    });

    testWidgets('import from a file asks before replacing everything', (
      tester,
    ) async {
      final source = FakeRepository();
      await source.completeSession(_session('backup', 9, endedAt: recent));
      final files = FakeBackupFiles(
        supported: true,
        openText: encodeBackup(source.exportBackup()),
      );
      final repo = FakeRepository();
      await repo.completeSession(_session('current', 3, endedAt: recent));
      await tester.pumpWidget(_app(repo, files: files));
      await _openSettings(tester);

      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();
      expect(find.textContaining('which has 1 session'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.sessions.keys, ['current']);

      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace data'));
      await tester.pumpAndSettle();
      expect(repo.sessions.keys, ['backup']);
      expect(repo.getGlobalState().lifetimeTotalTaps, 9);
      expect(find.text('Imported 1 session.'), findsOneWidget);
    });

    testWidgets('a file that is not a backup is rejected', (tester) async {
      final files = FakeBackupFiles(
        supported: true,
        openText: jsonEncode({'hello': 'world'}),
      );
      final repo = FakeRepository();
      await tester.pumpWidget(_app(repo, files: files));
      await _openSettings(tester);
      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();
      expect(
        find.text('This is not a valid Sushi Tracker backup.'),
        findsOneWidget,
      );
      expect(find.text('Replace all data?'), findsNothing);
    });

    testWidgets('an unreadable file is reported', (tester) async {
      final files = FakeBackupFiles(supported: true, fail: true);
      await tester.pumpWidget(_app(FakeRepository(), files: files));
      await _openSettings(tester);
      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();
      expect(find.text('Could not read the file.'), findsOneWidget);
    });

    testWidgets('import is unavailable during a session', (tester) async {
      final files = FakeBackupFiles(supported: true, openText: '{}');
      final repo = FakeRepository();
      await repo.saveOngoingSession(2, DateTime.now());
      await tester.pumpWidget(_app(repo, files: files));
      await _openSettings(tester);
      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();
      expect(files.opens, 0);
    });
  });

  testWidgets('discarding a session that recovery already saved says so', (
    tester,
  ) async {
    final repo = _SavedThenFailedRepository();
    await tester.pumpWidget(_app(repo));
    await tester.tap(find.byType(SushiButton));
    await tester.pump();
    await tester.tap(find.byKey(counterEndSessionButtonKey));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(counterDiscardButtonKey));
    await tester.tap(find.byKey(counterDiscardButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(
      find.text('This session had already been saved to history.'),
      findsOneWidget,
    );
    expect(repo.sessions, hasLength(1));
  });

  testWidgets('Spanish settings fit a small screen with large text', (
    tester,
  ) async {
    _useRegion(tester, const Locale('es', 'ES'));
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(_app(FakeRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    for (final label in [
      'Reiniciar sesión actual',
      'Mantener la pantalla encendida en una sesión',
      'Exportar datos',
      'Importar datos',
      'Política de privacidad',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 100);
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

/// Storage changed behind the app's back, so refresh like a reload would.
Future<void> _reloadAll(ProviderContainer container) async {
  container.read(globalStateProvider.notifier).reload();
  container.read(sessionListProvider.notifier).reload();
}

/// Mimics a completion whose journal was written before the failure, so
/// journal recovery finishes the save before the discard runs.
class _SavedThenFailedRepository extends FakeRepository {
  @override
  Future<Session> completeSession(Session session) async {
    await super.completeSession(session);
    throw StateError('journal cleanup failed');
  }
}
