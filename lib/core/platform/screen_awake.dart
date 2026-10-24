import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _channel = MethodChannel('dev.edulabrador.sushiscore/screen');

/// Keeps the display on while counting. Only Android implements the channel;
/// elsewhere this is a silent no-op.
Future<void> setKeepScreenOn(bool value) async {
  try {
    await _channel.invokeMethod<void>('setKeepScreenOn', value);
  } on MissingPluginException {
    // Platform without an implementation (web, desktop, tests).
  } on PlatformException {
    // The screen simply follows the system timeout.
  }
}

/// Overridable so tests can observe requests without a platform channel.
final screenAwakeProvider = Provider<Future<void> Function(bool)>(
  (ref) => setKeepScreenOn,
);
