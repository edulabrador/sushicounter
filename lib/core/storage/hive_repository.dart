import 'dart:async';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/global_state.dart';
import '../models/session.dart';
import 'backup.dart';
import 'preferences.dart';

/// Hive has no multi-box transaction. Related mutations are serialized and a
/// journal completes any interrupted mutation on startup or before the next write.
///
/// Reads (`getAllSessions`, `getGlobalState`, ...) are synchronous and do not
/// wait for the queue. Callers only read after awaiting the mutation they
/// depend on, so they never observe a half-applied journal in practice.
class HiveRepository {
  static const String sessionBoxName = 'sessions';
  static const String globalStateBoxName = 'global_state';
  static const String appStateBoxName = 'app_state';
  static const _globalKey = 'state';
  static const _journalKey = 'mutation_journal';
  static const _ongoingKey = 'ongoing_session';
  static const _epochMigrationKey = 'epoch_migration_v1';

  late Box<Session> _sessionBox;
  late Box<GlobalState> _globalStateBox;
  late Box _appStateBox;
  Future<void> _tail = Future<void>.value();

  /// In memory until [init] opens storage, so test doubles need no setup.
  Preferences preferences = InMemoryPreferences();

  Future<void> init({String? path}) async {
    if (path == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(path);
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GlobalStateAdapter());
    }
    _sessionBox = await Hive.openBox<Session>(sessionBoxName);
    _globalStateBox = await Hive.openBox<GlobalState>(globalStateBoxName);
    _appStateBox = await Hive.openBox(appStateBoxName);
    preferences = HivePreferences(_appStateBox);
    if (_globalStateBox.isEmpty) {
      await _globalStateBox.put(
        _globalKey,
        GlobalState(lifetimeTotalTaps: 0, lifetimeTotalSessions: 0),
      );
    }
    await _recoverJournal();
    await _migrateLegacyEpochs();
    await _migrateOngoingSession();
  }

  Future<T> _serial<T>(Future<T> Function() work) {
    final result = _tail.then((_) async {
      await _recoverJournal();
      return work();
    });
    // A failed write is returned to its caller, but cannot poison later work.
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  List<Session> getAllSessions() =>
      _sessionBox.values.toList()
        ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

  GlobalState getGlobalState() {
    final stored = _globalStateBox.get(_globalKey);
    return GlobalState(
      lifetimeTotalTaps: stored?.lifetimeTotalTaps ?? 0,
      lifetimeTotalSessions: stored?.lifetimeTotalSessions ?? 0,
      epoch: stored?.epoch ?? 0,
      lastResetAt: stored?.lastResetAt,
    );
  }

  Future<void> resetGlobalState() => _serial(() async {
    final current = getGlobalState();
    await _runJournal({
      'kind': 'global',
      'global': _globalMap(
        GlobalState(
          lifetimeTotalTaps: 0,
          lifetimeTotalSessions: 0,
          epoch: current.epoch + 1,
          lastResetAt: DateTime.now(),
        ),
      ),
    });
  });

  /// Stores the history record and its lifetime contribution together.
  Future<Session> completeSession(Session session) => _serial(() async {
    final existing = _sessionBox.get(session.id);
    if (existing != null) return existing;
    final current = getGlobalState();
    final recorded = session.copyWith(contributionEpoch: current.epoch);
    await _runJournal({
      'kind': 'complete',
      'session': _sessionMap(recorded),
      'global': _globalMap(_adjust(current, recorded.count, 1)),
      'ongoing': {'count': 0, 'startedAt': null},
    });
    return recorded;
  });

  /// Old history does not affect a later post-reset lifetime total.
  Future<DeletedSession?> deleteSessionWithTotals(String id) =>
      _serial(() async {
        final session = _sessionBox.get(id);
        if (session == null) return null;
        final current = getGlobalState();
        final target = session.contributionEpoch == current.epoch
            ? _adjust(current, -session.count, -1)
            : current;
        await _runJournal({
          'kind': 'delete',
          'session': _sessionMap(session),
          'global': _globalMap(target),
        });
        return DeletedSession(
          session,
          tapsRemoved: current.lifetimeTotalTaps - target.lifetimeTotalTaps,
          sessionsRemoved:
              current.lifetimeTotalSessions - target.lifetimeTotalSessions,
        );
      });

  /// Idempotent undo: put back exactly what the delete removed, and only if
  /// the totals still belong to the same lifetime.
  Future<void> restoreSessionWithTotals(DeletedSession deleted) =>
      _serial(() async {
        final session = deleted.session;
        if (_sessionBox.containsKey(session.id)) return;
        final current = getGlobalState();
        final target = session.contributionEpoch == current.epoch
            ? _adjust(current, deleted.tapsRemoved, deleted.sessionsRemoved)
            : current;
        await _runJournal({
          'kind': 'restore',
          'session': _sessionMap(session),
          'global': _globalMap(target),
        });
      });

  /// Records what a session cost, or clears it with null. A single put, so it
  /// needs no journal. Returns null if the session no longer exists.
  Future<Session?> setSessionPrice(String id, int? priceCents) =>
      _serial(() async {
        final session = _sessionBox.get(id);
        if (session == null) return null;
        final updated = session.copyWith(priceCents: priceCents);
        await _sessionBox.put(id, updated);
        return updated;
      });

  BackupData exportBackup() =>
      BackupData(global: getGlobalState(), sessions: getAllSessions());

  /// Replaces all saved history and totals with [backup].
  Future<void> importBackup(BackupData backup) => _serial(
    () => _runJournal({
      'kind': 'replace',
      'sessions': [for (final session in backup.sessions) _sessionMap(session)],
      'global': _globalMap(backup.global),
      'ongoing': {'count': 0, 'startedAt': null},
    }),
  );

  Future<void> _runJournal(Map<String, dynamic> record) async {
    await _appStateBox.put(_journalKey, record);
    await _applyJournal(record);
    await _appStateBox.delete(_journalKey);
  }

  Future<void> _recoverJournal() async {
    final raw = _appStateBox.get(_journalKey);
    if (raw is! Map) return;
    final record = Map<String, dynamic>.from(raw);
    await _applyJournal(record);
    await _appStateBox.delete(_journalKey);
  }

  /// Every step writes absolute values, so replaying a journal is idempotent.
  Future<void> _applyJournal(Map<String, dynamic> record) async {
    final global = _globalFromMap(
      Map<dynamic, dynamic>.from(record['global'] as Map),
    );
    final rawSession = record['session'];
    final session = rawSession is Map
        ? _sessionFromMap(Map<dynamic, dynamic>.from(rawSession))
        : null;
    switch (record['kind']) {
      case 'complete':
      case 'restore':
        if (session != null && !_sessionBox.containsKey(session.id)) {
          await _sessionBox.put(session.id, session);
        }
        break;
      case 'delete':
        if (session != null) await _sessionBox.delete(session.id);
        break;
      case 'replace':
        final sessions = [
          for (final raw in record['sessions'] as List)
            _sessionFromMap(Map<dynamic, dynamic>.from(raw as Map)),
        ];
        await _sessionBox.clear();
        await _sessionBox.putAll({
          for (final session in sessions) session.id: session,
        });
        break;
      case 'global':
        break;
      default:
        throw StateError('Unknown pending storage operation');
    }
    await _putGlobal(global);
    final ongoing = record['ongoing'];
    if (ongoing is Map) {
      await _appStateBox.put(_ongoingKey, Map<dynamic, dynamic>.from(ongoing));
    }
  }

  Future<void> _migrateLegacyEpochs() async {
    if (_appStateBox.get(_epochMigrationKey) == true) return;
    final current = getGlobalState();
    final sessions = _sessionBox.values.toList();
    final taps = sessions.fold<int>(0, (sum, session) => sum + session.count);
    // Old records had no epoch. Only attribute them when the old aggregate
    // exactly matches history; otherwise deletes preserve the stored total.
    if (sessions.isNotEmpty &&
        (taps != current.lifetimeTotalTaps ||
            sessions.length != current.lifetimeTotalSessions)) {
      for (final session in sessions) {
        await _sessionBox.put(
          session.id,
          session.copyWith(contributionEpoch: Session.unattributedEpoch),
        );
      }
    }
    await _appStateBox.put(_epochMigrationKey, true);
  }

  GlobalState _adjust(GlobalState state, int taps, int sessions) {
    final nextTaps = state.lifetimeTotalTaps + taps;
    final nextSessions = state.lifetimeTotalSessions + sessions;
    return GlobalState(
      lifetimeTotalTaps: nextTaps < 0 ? 0 : nextTaps,
      lifetimeTotalSessions: nextSessions < 0 ? 0 : nextSessions,
      epoch: state.epoch,
      lastResetAt: state.lastResetAt,
    );
  }

  Future<void> _putGlobal(GlobalState value) =>
      _globalStateBox.put(_globalKey, value);

  Map<String, dynamic> _globalMap(GlobalState value) => {
    'taps': value.lifetimeTotalTaps,
    'sessions': value.lifetimeTotalSessions,
    'epoch': value.epoch,
    'resetAt': value.lastResetAt?.millisecondsSinceEpoch,
  };
  GlobalState _globalFromMap(Map<dynamic, dynamic> value) {
    final resetAt = value['resetAt'] as int?;
    return GlobalState(
      lifetimeTotalTaps: value['taps'] as int,
      lifetimeTotalSessions: value['sessions'] as int,
      epoch: value['epoch'] as int? ?? 0,
      lastResetAt: resetAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(resetAt),
    );
  }

  Map<String, dynamic> _sessionMap(Session value) => {
    'id': value.id,
    'startedAt': value.startedAt.millisecondsSinceEpoch,
    'endedAt': value.endedAt.millisecondsSinceEpoch,
    'count': value.count,
    'durationSeconds': value.durationSeconds,
    'epoch': value.contributionEpoch,
    'priceCents': value.priceCents,
  };
  Session _sessionFromMap(Map<dynamic, dynamic> value) => Session(
    id: value['id'] as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(value['startedAt'] as int),
    endedAt: DateTime.fromMillisecondsSinceEpoch(value['endedAt'] as int),
    count: value['count'] as int,
    durationSeconds: value['durationSeconds'] as int,
    contributionEpoch: value['epoch'] as int? ?? 0,
    priceCents: value['priceCents'] as int?,
  );

  int getOngoingCount() => _ongoing()['count'] as int;
  DateTime? getOngoingStartedAt() {
    final startedAt = _ongoing()['startedAt'];
    return startedAt is int
        ? DateTime.fromMillisecondsSinceEpoch(startedAt)
        : null;
  }

  Map<dynamic, dynamic> _ongoing() {
    final value = _appStateBox.get(_ongoingKey);
    return value is Map
        ? Map<dynamic, dynamic>.from(value)
        : {'count': 0, 'startedAt': null};
  }

  Future<void> _migrateOngoingSession() async {
    if (_appStateBox.get(_ongoingKey) is Map) return;
    final count = _appStateBox.get('ongoingCount', defaultValue: 0) as int;
    final startedAt = _appStateBox.get('ongoingStartedAt') as DateTime?;
    await _appStateBox.put(_ongoingKey, {
      'count': count,
      // Legacy installs could hold a count without a start time.
      'startedAt': count > 0
          ? (startedAt ?? DateTime.now()).millisecondsSinceEpoch
          : null,
    });
  }

  Future<void> saveOngoingSession(int count, DateTime? startedAt) => _serial(
    () => _appStateBox.put(_ongoingKey, {
      'count': count,
      'startedAt': startedAt?.millisecondsSinceEpoch,
    }),
  );
}
