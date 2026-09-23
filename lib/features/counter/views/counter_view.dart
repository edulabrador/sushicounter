import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/settings/views/settings_view.dart';

class CounterView extends ConsumerStatefulWidget {
  const CounterView({super.key});

  @override
  ConsumerState<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends ConsumerState<CounterView> {
  Timer? _timer;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  void _syncTimer(int count, DateTime? startedAt) {
    if (count == 0 || startedAt == null) {
      _timer?.cancel();
      _timer = null;
      _startedAt = null;
      _elapsed = Duration.zero;
    } else if (_timer == null || _startedAt != startedAt) {
      _timer?.cancel();
      _startedAt = startedAt;
      _elapsed = _elapsedSince(startedAt);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _startedAt == null) return;
        setState(() => _elapsed = _elapsedSince(_startedAt!));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _endSession(WidgetRef ref) async {
    try {
      await ref.read(counterProvider.notifier).endSession();
    } catch (_) {
      // The provider exposes the error and keeps the session for retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    final counterState = ref.watch(counterProvider);
    final globalState = ref.watch(globalStateProvider);
    _syncTimer(counterState.count, counterState.startedAt);
    final elapsed = _formatDuration(_elapsed);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SettingsView())),
        ),
        title: const Text('Sushi Tracker'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sushiSize = (constraints.maxHeight * .30).clamp(96.0, 200.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${counterState.count}',
                            semanticsLabel:
                                'Current session: ${counterState.count} sushi',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          counterState.count == 0
                              ? 'Tap the sushi to start'
                              : 'Tap to add · Long press or Undo to remove',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        SushiButton(
                          onTap: () =>
                              ref.read(counterProvider.notifier).increment(),
                          onLongPress: () =>
                              ref.read(counterProvider.notifier).decrement(),
                          size: sushiSize,
                          enabled: counterState.canEdit,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed:
                              counterState.count > 0 && counterState.canEdit
                              ? () => ref
                                    .read(counterProvider.notifier)
                                    .decrement()
                              : null,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Undo'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 20,
                          runSpacing: 12,
                          children: [
                            _Metric(
                              label: 'This session',
                              value: '${counterState.count}',
                            ),
                            _Metric(
                              label: 'Lifetime total',
                              value:
                                  '${globalState.lifetimeTotalTaps + counterState.count}',
                            ),
                            if (counterState.count > 0)
                              _Metric(label: 'Elapsed', value: elapsed),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white12,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  counterState.count > 0 &&
                                      !counterState.isEnding &&
                                      !counterState.isPersisting
                                  ? () => _endSession(ref)
                                  : null,
                              child: counterState.isEnding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('End Session'),
                            ),
                            if (counterState.persistenceError != null)
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  counterState.persistenceError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:$minutes:$seconds'
      : '${duration.inMinutes.toString().padLeft(2, '0')}:$seconds';
}

Duration _elapsedSince(DateTime startedAt) {
  final elapsed = DateTime.now().difference(startedAt);
  return elapsed.isNegative ? Duration.zero : elapsed;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54)),
      Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
