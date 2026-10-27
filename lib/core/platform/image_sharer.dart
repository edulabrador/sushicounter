import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Android share sheet with a PNG. The image is served read-only
/// by the app's own content provider; no permission is involved.
class ImageSharer {
  const ImageSharer([
    this._channel = const MethodChannel('dev.edulabrador.sushiscore/share'),
  ]);

  final MethodChannel _channel;

  /// Returns false where the platform cannot share images; callers then
  /// fall back to copying [text]. Throws [PlatformException] on I/O errors.
  Future<bool> share({
    required Uint8List png,
    required String name,
    required String text,
    required String title,
  }) async {
    try {
      final shared = await _channel.invokeMethod<bool>('shareImage', {
        'bytes': png,
        'name': name,
        'text': text,
        'title': title,
      });
      return shared == true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') return false;
      rethrow;
    }
  }
}

final imageSharerProvider = Provider<ImageSharer>((ref) => const ImageSharer());
