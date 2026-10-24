import 'package:hive_ce/hive.dart';

/// User settings, kept apart from history so tests and features that only
/// need settings do not depend on the session storage.
abstract class Preferences {
  bool get keepScreenOn;
  Future<void> setKeepScreenOn(bool value);
}

class InMemoryPreferences implements Preferences {
  InMemoryPreferences({this.keepScreenOn = true});

  @override
  bool keepScreenOn;

  @override
  Future<void> setKeepScreenOn(bool value) async => keepScreenOn = value;
}

/// Stored in the app-state box, where 0.3.0 already saved the setting.
class HivePreferences implements Preferences {
  HivePreferences(this._box);

  static const _keepScreenOnKey = 'keep_screen_on';
  final Box _box;

  @override
  bool get keepScreenOn =>
      _box.get(_keepScreenOnKey, defaultValue: true) as bool;

  @override
  Future<void> setKeepScreenOn(bool value) => _box.put(_keepScreenOnKey, value);
}
