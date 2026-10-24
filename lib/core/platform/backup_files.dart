import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SaveOutcome { saved, cancelled, unsupported }

/// What picking a file produced. [supported] is false where the platform has
/// no document picker; callers then fall back to the clipboard.
typedef OpenedFile = ({bool supported, String? text});

/// Saves and opens backup files through the Android document picker
/// (Storage Access Framework), which needs no storage permission.
class BackupFiles {
  const BackupFiles([
    this._channel = const MethodChannel('dev.edulabrador.sushiscore/files'),
  ]);

  final MethodChannel _channel;

  /// Throws [PlatformException] if the chosen file cannot be written.
  Future<SaveOutcome> save(String name, String content) async {
    try {
      final saved = await _channel.invokeMethod<bool>('exportFile', {
        'name': name,
        'content': content,
      });
      return saved == true ? SaveOutcome.saved : SaveOutcome.cancelled;
    } on MissingPluginException {
      return SaveOutcome.unsupported;
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') return SaveOutcome.unsupported;
      rethrow;
    }
  }

  /// Throws [PlatformException] if the chosen file cannot be read.
  Future<OpenedFile> open() async {
    try {
      final text = await _channel.invokeMethod<String>('importFile');
      return (supported: true, text: text);
    } on MissingPluginException {
      return (supported: false, text: null);
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') return (supported: false, text: null);
      rethrow;
    }
  }
}

final backupFilesProvider = Provider<BackupFiles>((ref) => const BackupFiles());
