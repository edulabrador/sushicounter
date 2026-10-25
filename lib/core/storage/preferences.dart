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
}

class InMemoryPreferences implements Preferences {
  InMemoryPreferences({
    this.keepScreenOn = true,
    this.appearance = Appearance.dark,
  });

  @override
  bool keepScreenOn;

  @override
  Appearance appearance;

  @override
  Future<void> setKeepScreenOn(bool value) async => keepScreenOn = value;

  @override
  Future<void> setAppearance(Appearance value) async => appearance = value;
}

/// Stored in the app-state box, where 0.3.0 already saved the setting.
class HivePreferences implements Preferences {
  HivePreferences(this._box);

  static const _keepScreenOnKey = 'keep_screen_on';
  static const _appearanceKey = 'appearance';
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
}
