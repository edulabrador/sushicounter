import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';
import '../models/global_state.dart';

class HiveRepository {
  static const String sessionBoxName = 'sessions';
  static const String globalStateBoxName = 'global_state';

  late Box<Session> _sessionBox;
  late Box<GlobalState> _globalStateBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SessionAdapter());
    Hive.registerAdapter(GlobalStateAdapter());

    _sessionBox = await Hive.openBox<Session>(sessionBoxName);
    _globalStateBox = await Hive.openBox<GlobalState>(globalStateBoxName);

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
  GlobalState getGlobalState() {
    return _globalStateBox.get('state')!;
  }

  Future<void> updateGlobalState(int additionalTaps) async {
    final state = getGlobalState();
    state.lifetimeTotalTaps += additionalTaps;
    state.lifetimeTotalSessions += 1;
    await state.save();
  }

  Future<void> resetGlobalState() async {
    final state = getGlobalState();
    state.lifetimeTotalTaps = 0;
    state.lifetimeTotalSessions = 0;
    await state.save();
  }
}
