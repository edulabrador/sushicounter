import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _channel = MethodChannel('dev.edulabrador.sushiscore/widget');

/// Shows [count] on the Android home screen widget. Elsewhere, and when no
/// widget is placed, this is a silent no-op.
Future<void> updateHomeWidget(int count) async {
  try {
    await _channel.invokeMethod<void>('update', {'count': count});
  } on MissingPluginException {
    // No widget support on this platform (web, desktop, tests).
  } on PlatformException {
    // The widget keeps its last count until the next update.
  }
}

/// Overridable so tests can observe updates without a platform channel.
final homeWidgetProvider = Provider<Future<void> Function(int)>(
  (ref) => updateHomeWidget,
);
