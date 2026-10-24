import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:sushiscore/core/models/global_state.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/storage/backup.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';

Session _session(String id, {int? price}) => Session(
  id: id,
  startedAt: DateTime.fromMillisecondsSinceEpoch(1000),
  endedAt: DateTime.fromMillisecondsSinceEpoch(2000),
  count: 5,
  durationSeconds: 1,
  priceCents: price,
);

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sushiscore_price_');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<HiveRepository> open() async {
    final repository = HiveRepository();
    await repository.init(path: directory.path);
    return repository;
  }

  test('price is stored, cleared and survives a restart', () async {
    final repository = await open();
    await repository.completeSession(_session('a'));
    expect(await repository.setSessionPrice('missing', 100), isNull);
    expect((await repository.setSessionPrice('a', 2490))!.priceCents, 2490);
    await Hive.close();

    final reopened = await open();
    expect(reopened.getAllSessions().single.priceCents, 2490);
    await reopened.setSessionPrice('a', null);
    expect(reopened.getAllSessions().single.priceCents, isNull);
  });

  test('a price set at completion is kept, and totals are untouched', () async {
    final repository = await open();
    await repository.completeSession(_session('a', price: 1500));
    await repository.setSessionPrice('a', 1600);
    expect(repository.getAllSessions().single.priceCents, 1600);
    expect(repository.getGlobalState().lifetimeTotalTaps, 5);
  });

  test('delete and undo keep the price', () async {
    final repository = await open();
    await repository.completeSession(_session('a', price: 999));
    final deleted = await repository.deleteSessionWithTotals('a');
    await repository.restoreSessionWithTotals(deleted!);
    expect(repository.getAllSessions().single.priceCents, 999);
  });

  test('backups carry prices and stay readable without them', () {
    final encoded = encodeBackup(
      BackupData(
        global: GlobalState(lifetimeTotalTaps: 10, lifetimeTotalSessions: 2),
        sessions: [_session('a', price: 2000), _session('b')],
      ),
    );
    final raw = jsonDecode(encoded) as Map<String, dynamic>;
    final sessions = raw['sessions'] as List;
    expect((sessions[0] as Map)['priceCents'], 2000);
    expect((sessions[1] as Map).containsKey('priceCents'), isFalse);
    final decoded = decodeBackup(encoded);
    expect(decoded.sessions.map((s) => s.priceCents), [2000, null]);
  });

  test('backups with an invalid price are rejected', () {
    final encoded = encodeBackup(
      BackupData(
        global: GlobalState(lifetimeTotalTaps: 5, lifetimeTotalSessions: 1),
        sessions: [_session('a', price: 1)],
      ),
    );
    for (final bad in [-1, 'ten', 1.5]) {
      final broken = encoded.replaceFirst(
        '"priceCents": 1',
        '"priceCents": ${jsonEncode(bad)}',
      );
      expect(() => decodeBackup(broken), throwsFormatException, reason: '$bad');
    }
  });

  test('an interrupted import is completed on restart', () async {
    final first = await open();
    await first.completeSession(_session('old'));
    await Hive.box('app_state').put('mutation_journal', {
      'kind': 'replace',
      'sessions': [
        {
          'id': 'new',
          'startedAt': 1,
          'endedAt': 2,
          'count': 8,
          'durationSeconds': 1,
          'epoch': 0,
          'priceCents': 1200,
        },
      ],
      'global': {'taps': 8, 'sessions': 1, 'epoch': 0},
      'ongoing': {'count': 0, 'startedAt': null},
    });
    await Hive.close();

    final recovered = await open();
    expect(recovered.getAllSessions().map((s) => s.id), ['new']);
    expect(recovered.getAllSessions().single.priceCents, 1200);
    expect(recovered.getGlobalState().lifetimeTotalTaps, 8);
  });
}
