import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../global/providers/global_provider.dart';
import '../../history/providers/session_provider.dart';
import '../stats_logic.dart';

/// Best saved session of the current lifetime, or 0 before the first one.
final lifetimeBestProvider = Provider<int>((ref) {
  final epoch = ref.watch(globalStateProvider.select((g) => g.epoch));
  return lifetimeSessions(
    ref.watch(sessionListProvider),
    epoch,
  ).fold(0, (best, session) => math.max(best, session.count));
});
