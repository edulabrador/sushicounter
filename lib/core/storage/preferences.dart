import 'package:hive_ce/hive.dart';

/// User settings, kept apart from history so tests and features that only
/// need settings do not depend on the session storage.
/// How the app picks light or dark colors.
enum Appearance { dark, light, system }

abstract class Preferences {
  bool get keepScreenOn;
  Future<void> setKeepScreenOn(bool value);

  /// Dark unless the user chose otherwise, so updates never change the look.
  Appearance get appearance;
  Future<void> setAppearance(Appearance value);

  /// Pieces to aim for in each session, or null when off.
  int? get sessionGoal;
  Future<void> setSessionGoal(int? value);

  /// Largest goal the settings accept.
  static const maxSessionGoal = 999;
}

class InMemoryPreferences implements Preferences {
  InMemoryPreferences({
    this.keepScreenOn = true,
    this.appearance = Appearance.dark,
    this.sessionGoal,
  });

  @override
  bool keepScreenOn;

  @override
  Appearance appearance;

  @override
  Future<void> setKeepScreenOn(bool value) async => keepScreenOn = value;

  @override
  Future<void> setAppearance(Appearance value) async => appearance = value;

  @override
  int? sessionGoal;

  @override
  Future<void> setSessionGoal(int? value) async => sessionGoal = value;
}

/// Stored in the app-state box, where 0.3.0 already saved the setting.
class HivePreferences implements Preferences {
  HivePreferences(this._box);

  static const _keepScreenOnKey = 'keep_screen_on';
  static const _appearanceKey = 'appearance';
  static const _sessionGoalKey = 'session_goal';
  final Box _box;

  @override
  bool get keepScreenOn =>
      _box.get(_keepScreenOnKey, defaultValue: true) as bool;

  @override
  Future<void> setKeepScreenOn(bool value) => _box.put(_keepScreenOnKey, value);

  @override
  Appearance get appearance => Appearance.values.firstWhere(
    (value) => value.name == _box.get(_appearanceKey),
    orElse: () => Appearance.dark,
  );

  @override
  Future<void> setAppearance(Appearance value) =>
      _box.put(_appearanceKey, value.name);

  @override
  int? get sessionGoal {
    final value = _box.get(_sessionGoalKey);
    return value is int && value > 0 && value <= Preferences.maxSessionGoal
        ? value
        : null;
  }

  @override
  Future<void> setSessionGoal(int? value) => value == null
      ? _box.delete(_sessionGoalKey)
      : _box.put(_sessionGoalKey, value);
}
