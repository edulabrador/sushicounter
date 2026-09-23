import 'dart:async';

import 'package:flutter/material.dart';

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
  late Duration _elapsed;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    _elapsed = elapsedSince(widget.startedAt, now: widget.now());
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant SessionElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startedAt != oldWidget.startedAt) {
      _elapsed = elapsedSince(widget.startedAt, now: widget.now());
    }
  }

  void _startTimer() {
    if (!_isForeground || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      setState(() => _elapsed = elapsedSince(widget.startedAt, now: widget.now()));
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
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
      const Text('Elapsed', style: TextStyle(color: Colors.white54)),
      Text(
        formatSessionDuration(_elapsed),
        key: counterElapsedTimeKey,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
