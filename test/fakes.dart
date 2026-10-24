import 'package:flutter/services.dart';
import 'package:sushiscore/core/platform/backup_files.dart';

/// Deterministic stand-in for the Android document picker. By default it
/// behaves like a platform without one, so screens fall back to the clipboard.
class FakeBackupFiles extends BackupFiles {
  FakeBackupFiles({
    this.supported = false,
    this.openText,
    this.cancel = false,
    this.fail = false,
  });

  final bool supported;
  final String? openText;
  final bool cancel;
  final bool fail;
  final saved = <({String name, String content})>[];
  int opens = 0;

  @override
  Future<SaveOutcome> save(String name, String content) async {
    if (!supported) return SaveOutcome.unsupported;
    if (fail) throw PlatformException(code: 'io', message: 'disk full');
    if (cancel) return SaveOutcome.cancelled;
    saved.add((name: name, content: content));
    return SaveOutcome.saved;
  }

  @override
  Future<OpenedFile> open() async {
    opens++;
    if (!supported) return (supported: false, text: null);
    if (fail) throw PlatformException(code: 'io', message: 'unreadable');
    return (supported: true, text: cancel ? null : openText);
  }
}
