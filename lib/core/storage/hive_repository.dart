import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';
import '../models/global_state.dart';

class HiveRepository {
  static const String sessionBoxName = 'sessions';
  static const String globalStateBoxName = 'global_state';
  static const String appStateBoxName = 'app_state';

  late Box<Session> _sessionBox;
  late Box<GlobalState> _globalStateBox;
  late Box _appStateBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SessionAdapter());
    Hive.registerAdapter(GlobalStateAdapter());

    _sessionBox = await Hive.openBox<Session>(sessionBoxName);
    _globalStateBox = await Hive.openBox<GlobalState>(globalStateBoxName);
    _appStateBox = await Hive.openBox(appStateBoxName);

    // Initialize global state if it doesn't exist
    if (_globalStateBox.isEmpty) {
      await _globalStateBox.put(
        'state',
        GlobalState(lifetimeTotalTaps: 0, lifetimeTotalSessions: 0),
      );
    }
  }

  // Session Methods
  List<Session> getAllSessions() {
    return _sessionBox.values.toList()..sort((a, b) => b.endedAt.compareTo(a.endedAt));
  }

  Future<void> saveSession(Session session) async {
    await _sessionBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _sessionBox.delete(id);
  }

  // Global State Methods
  // Returns a fresh copy: Hive caches and returns the same object instance,
  // and Riverpod's identity check would otherwise never notify listeners.
  GlobalState getGlobalState() {
    final stored = _globalStateBox.get('state');
    return GlobalState(
      lifetimeTotalTaps: stored?.lifetimeTotalTaps ?? 0,
      lifetimeTotalSessions: stored?.lifetimeTotalSessions ?? 0,
    );
  }

  Future<void> updateGlobalState(int additionalTaps) async {
    await adjustGlobalState(tapsDelta: additionalTaps, sessionsDelta: 1);
  }

  // Applies signed deltas to the lifetime totals. Used both when a session ends
  // (+taps, +1 session) and when a session is deleted (-taps, -1 session).
  // Clamped at 0 so deleting a session after a global reset can't go negative.
  Future<void> adjustGlobalState({
    required int tapsDelta,
    required int sessionsDelta,
  }) async {
    final current = getGlobalState();
    final taps = current.lifetimeTotalTaps + tapsDelta;
    final sessions = current.lifetimeTotalSessions + sessionsDelta;
    await _globalStateBox.put(
      'state',
      GlobalState(
        lifetimeTotalTaps: taps < 0 ? 0 : taps,
        lifetimeTotalSessions: sessions < 0 ? 0 : sessions,
      ),
    );
  }

  // Overwrites the lifetime totals with exact values. Used to restore the global
  // state to a captured snapshot when an undo needs to be lossless (the clamp in
  // adjustGlobalState makes the inverse delta lossy, so undo restores instead).
  Future<void> setGlobalState(int taps, int sessions) async {
    await _globalStateBox.put(
      'state',
      GlobalState(
        lifetimeTotalTaps: taps < 0 ? 0 : taps,
        lifetimeTotalSessions: sessions < 0 ? 0 : sessions,
      ),
    );
  }

  Future<void> resetGlobalState() async {
    await _globalStateBox.put(
      'state',
      GlobalState(lifetimeTotalTaps: 0, lifetimeTotalSessions: 0),
    );
  }

  // Ongoing (unsaved) session persistence, so taps survive an app restart.
  int getOngoingCount() {
    return _appStateBox.get('ongoingCount', defaultValue: 0) as int;
  }

  DateTime? getOngoingStartedAt() {
    return _appStateBox.get('ongoingStartedAt') as DateTime?;
  }

  Future<void> saveOngoingSession(int count, DateTime? startedAt) async {
    await _appStateBox.put('ongoingCount', count);
    await _appStateBox.put('ongoingStartedAt', startedAt);
  }
}
