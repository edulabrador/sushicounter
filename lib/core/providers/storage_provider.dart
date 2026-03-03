import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/hive_repository.dart';

final storageProvider = Provider<HiveRepository>((ref) {
  throw UnimplementedError('Storage provider not initialized');
});
