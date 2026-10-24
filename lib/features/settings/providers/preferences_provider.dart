import 'package:flutter_riverpod/flutter_riverpod.dart';

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
