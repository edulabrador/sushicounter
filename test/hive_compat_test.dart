import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';

/// Files in test/fixtures/hive2 were written by the original `hive` 2.2.3
/// package (see test/fixtures/hive2/README.md), so these tests prove the
/// storage engine still reads data saved by every released app version.
void main() {
  late Directory directory;
  final start = DateTime.utc(2026, 3, 14, 20);

  Future<HiveRepository> openFixture(String name) async {
    directory = await Directory.systemTemp.createTemp('sushiscore_compat_');
    for (final file in Directory('test/fixtures/hive2/$name').listSync()) {
      if (file is File && file.path.endsWith('.hive')) {
        await file.copy('${directory.path}/${file.uri.pathSegments.last}');
      }
    }
    final repository = HiveRepository();
    await repository.init(path: directory.path);
    return repository;
  }

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  void expectHistory(HiveRepository repository) {
    final sessions = repository.getAllSessions();
    expect(sessions.map((s) => s.id), ['s2', 's1']);
    final first = sessions.last;
    expect(first.startedAt.isAtSameMomentAs(start), isTrue);
    expect(
      first.endedAt.isAtSameMomentAs(start.add(const Duration(minutes: 40))),
      isTrue,
    );
    expect(first.count, 12);
    expect(first.durationSeconds, 2400);
    expect(first.contributionEpoch, 0);
    expect(first.priceCents, isNull);
    final global = repository.getGlobalState();
    expect(global.lifetimeTotalTaps, 30);
    expect(global.lifetimeTotalSessions, 2);
    expect(global.epoch, 0);
    expect(global.lastResetAt, isNull);
    expect(repository.getOngoingCount(), 4);
    expect(
      repository.getOngoingStartedAt()!.isAtSameMomentAs(
        start.add(const Duration(days: 30)),
      ),
      isTrue,
    );
  }

  test('reads data saved by v0.1 (no epochs, legacy ongoing keys)', () async {
    final repository = await openFixture('legacy_v01');
    expectHistory(repository);
    expect(repository.preferences.keepScreenOn, isTrue);
  });

  test('reads data saved by v0.3', () async {
    final repository = await openFixture('v03');
    expectHistory(repository);
    expect(repository.preferences.keepScreenOn, isFalse);
  });

  test('migrated data keeps working after a write and a reopen', () async {
    final repository = await openFixture('legacy_v01');
    final deleted = await repository.deleteSessionWithTotals('s1');
    expect(repository.getGlobalState().lifetimeTotalTaps, 18);
    await repository.restoreSessionWithTotals(deleted!);
    await repository.setSessionPrice('s2', 2595);
    await Hive.close();

    final reopened = HiveRepository();
    await reopened.init(path: directory.path);
    expect(reopened.getGlobalState().lifetimeTotalTaps, 30);
    expect(reopened.getAllSessions().first.priceCents, 2595);
  });
}
