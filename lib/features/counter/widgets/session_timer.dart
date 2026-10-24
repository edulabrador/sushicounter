import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../views/counter_timer.dart';

const counterElapsedTimeKey = ValueKey<String>('elapsed-time');

class SessionElapsedTimer extends StatefulWidget {
  const SessionElapsedTimer({
    required this.startedAt,
    DateTime Function()? now,
    super.key,
  }) : now = now ?? DateTime.now;

  final DateTime startedAt;
  final DateTime Function() now;

  @override
  State<SessionElapsedTimer> createState() => _SessionElapsedTimerState();
}

class _SessionElapsedTimerState extends State<SessionElapsedTimer>
    with WidgetsBindingObserver {
  Timer? _timer;

  /// Elapsed time when the current timer started; ticks are added to it.
  late Duration _base;
  late Duration _elapsed;
  late bool _isForeground;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isForeground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  @override
  void didUpdateWidget(covariant SessionElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startedAt != oldWidget.startedAt) _restart();
  }

  /// Re-anchors to the real start time and restarts the ticker.
  void _restart() {
    _timer?.cancel();
    _timer = null;
    _base = elapsedSince(widget.startedAt, now: widget.now());
    _elapsed = _base;
    if (!_isForeground) return;
    // Timer.tick counts every elapsed period, including ones skipped while
    // the UI thread was busy, so the display cannot fall behind.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsed = _base + Duration(seconds: timer.tick));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    if (isForeground == _isForeground) return;
    _isForeground = isForeground;
    setState(_restart);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.elapsed,
        style: TextStyle(color: context.colors.textMuted),
      ),
      Text(
        formatSessionDuration(_elapsed),
        key: counterElapsedTimeKey,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
