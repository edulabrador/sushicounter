import 'dart:async';

// Local design preview: the real app UI over in-memory sample data.
// Build: flutter build web -t tool/design_preview.dart --no-web-resources-cdn
// Query: count=N, goal=N, table=1, appearance=light, empty=1,
// startup=loading|error.
// Store screenshots: tool/store/render_screenshots.js.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/models/global_state.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/screen_awake.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/backup.dart';
import 'package:sushiscore/core/storage/hive_repository.dart';
import 'package:sushiscore/core/storage/preferences.dart';
import 'package:sushiscore/main.dart';

class PreviewRepository extends HiveRepository {
  PreviewRepository(this.sessions, {this.ongoing = 0});
  final Map<String, Session> sessions;
  int ongoing;
  DateTime? started;

  @override
  List<Session> getAllSessions() =>
      sessions.values.toList()..sort((a, b) => b.endedAt.compareTo(a.endedAt));

  @override
  GlobalState getGlobalState() => GlobalState(
    lifetimeTotalTaps: sessions.values.fold(0, (s, e) => s + e.count),
    lifetimeTotalSessions: sessions.length,
  );

  @override
  Future<Session> completeSession(Session session) async =>
      sessions[session.id] = session;
  @override
  Future<DeletedSession?> deleteSessionWithTotals(String id) async {
    final s = sessions.remove(id);
    return s == null
        ? null
        : DeletedSession(s, tapsRemoved: s.count, sessionsRemoved: 1);
  }

  @override
  Future<void> restoreSessionWithTotals(DeletedSession d) async =>
      sessions[d.session.id] = d.session;
  @override
  Future<Session?> setSessionPrice(String id, int? cents) async =>
      sessions[id] = sessions[id]!.copyWith(priceCents: cents);
  @override
  Future<void> importBackup(BackupData backup) async {}
  @override
  int getOngoingCount() => ongoing;
  @override
  DateTime? getOngoingStartedAt() => started;
  @override
  Future<void> saveOngoingSession(
    int count,
    DateTime? startedAt, {
    List<Companion> companions = const [],
  }) async {
    ongoing = count;
    started = startedAt;
    table = companions;
  }

  List<Companion> table = const [];
  @override
  List<Companion> getOngoingCompanions() => table;
}

class _StartupRepository extends HiveRepository {
  _StartupRepository({required this.fail});
  final bool fail;
  @override
  Future<void> init({String? path}) => fail
      ? Future<void>.error(StateError('preview failure'))
      : Completer<void>().future;
}

void main() {
  final query = Uri.base.queryParameters;
  final startup = query['startup'];
  if (startup != null) {
    runApp(
      StartupApp(
        createRepository: () => _StartupRepository(fail: startup == 'error'),
      ),
    );
    return;
  }
  final empty = query['empty'] == '1';
  final now = DateTime.now();
  final counts = [14, 22, 18, 31, 26, 19, 35, 28, 24, 40, 33, 29, 37, 45];
  final days = [96, 82, 75, 61, 54, 47, 40, 33, 26, 19, 12, 8, 4, 1];
  final sessions = <String, Session>{
    if (!empty)
      for (var i = 0; i < counts.length; i++)
        'p$i': Session(
          id: 'p$i',
          startedAt: now.subtract(Duration(days: days[i], minutes: 70)),
          endedAt: now.subtract(Duration(days: days[i])),
          count: counts[i],
          durationSeconds: 3600 + i * 120,
          priceCents: i.isEven ? 2490 : null,
        ),
  };
  final restaurants = ['Sushi Zen', 'Koi', 'Umi Buffet'];
  for (final (i, id) in sessions.keys.toList().indexed) {
    sessions[id] = sessions[id]!.copyWith(restaurant: restaurants[i % 3]);
  }
  final repo = PreviewRepository(sessions)
    ..ongoing = int.tryParse(query['count'] ?? '') ?? 0
    ..started = now.subtract(const Duration(minutes: 23, seconds: 41))
    ..table = query['table'] == '1'
        ? const [
            Companion(name: 'Ana', count: 12),
            Companion(name: 'Leo', count: 9),
          ]
        : const []
    ..preferences = InMemoryPreferences(
      appearance: query['appearance'] == 'light'
          ? Appearance.light
          : Appearance.dark,
      sessionGoal: int.tryParse(query['goal'] ?? ''),
    );
  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(repo),
        screenAwakeProvider.overrideWithValue((_) async {}),
      ],
      child: const SushiScoreApp(),
    ),
  );
}
