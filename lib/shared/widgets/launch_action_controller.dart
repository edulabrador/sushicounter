import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/counter/providers/counter_provider.dart';

const launchChannel = MethodChannel('dev.edulabrador.sushiscore/launch');

/// Runs actions requested from outside the app, such as the launcher's
/// "Add one sushi" shortcut. Android queues them; this drains the queue on
/// start and whenever Android reports a new one.
class LaunchActionController extends ConsumerStatefulWidget {
  const LaunchActionController({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LaunchActionController> createState() =>
      _LaunchActionControllerState();
}

class _LaunchActionControllerState
    extends ConsumerState<LaunchActionController> {
  @override
  void initState() {
    super.initState();
    launchChannel.setMethodCallHandler((call) async {
      if (call.method == 'actionAvailable') await _drain();
    });
    _drain();
  }

  @override
  void dispose() {
    launchChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _drain() async {
    final List<String>? actions;
    try {
      actions = await launchChannel.invokeListMethod<String>(
        'takePendingActions',
      );
    } on MissingPluginException {
      return; // No launcher integration on this platform.
    } on PlatformException {
      return;
    }
    if (!mounted || actions == null) return;
    final before = ref.read(counterProvider).count;
    for (final action in actions) {
      // Ignored while a session is being saved, like a tap on the sushi.
      if (action == 'addSushi') ref.read(counterProvider.notifier).increment();
    }
    if (ref.read(counterProvider).count != before) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
