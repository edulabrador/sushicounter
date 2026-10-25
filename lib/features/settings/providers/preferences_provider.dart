import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences.dart';

import '../../../core/providers/storage_provider.dart';

class KeepScreenOnNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(storageProvider).preferences.keepScreenOn;

  Future<void> set(bool value) async {
    final previous = state;
    state = value;
    try {
      await ref.read(storageProvider).preferences.setKeepScreenOn(value);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}

final keepScreenOnProvider = NotifierProvider<KeepScreenOnNotifier, bool>(
  KeepScreenOnNotifier.new,
);

class AppearanceNotifier extends Notifier<Appearance> {
  @override
  Appearance build() => ref.watch(storageProvider).preferences.appearance;

  Future<void> set(Appearance value) async {
    final previous = state;
    state = value;
    try {
      await ref.read(storageProvider).preferences.setAppearance(value);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(
  AppearanceNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => switch (ref.watch(appearanceProvider)) {
    Appearance.dark => ThemeMode.dark,
    Appearance.light => ThemeMode.light,
    Appearance.system => ThemeMode.system,
  },
);
