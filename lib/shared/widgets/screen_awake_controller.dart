import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/screen_awake.dart';
import '../../features/counter/providers/counter_provider.dart';
import '../../features/settings/providers/preferences_provider.dart';

/// True while a session is active and the user allows keeping the screen on.
final shouldKeepScreenOnProvider = Provider<bool>(
  (ref) =>
      ref.watch(keepScreenOnProvider) &&
      ref.watch(counterProvider.select((state) => state.count > 0)),
);

/// Applies [shouldKeepScreenOnProvider] to the platform window.
class ScreenAwakeController extends ConsumerStatefulWidget {
  const ScreenAwakeController({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ScreenAwakeController> createState() =>
      _ScreenAwakeControllerState();
}

class _ScreenAwakeControllerState extends ConsumerState<ScreenAwakeController> {
  late final Future<void> Function(bool) _setKeepScreenOn;
  late final ProviderSubscription<bool> _subscription;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _setKeepScreenOn = ref.read(screenAwakeProvider);
    _subscription = ref.listenManual<bool>(shouldKeepScreenOnProvider, (
      _,
      next,
    ) {
      if (next == _requested) return;
      _requested = next;
      _setKeepScreenOn(next);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _subscription.close();
    if (_requested) _setKeepScreenOn(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
