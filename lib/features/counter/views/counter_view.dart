import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/counter/widgets/session_timer.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/settings/views/settings_view.dart';

const counterCurrentCountKey = ValueKey<String>('current-count');
const counterSessionTotalKey = ValueKey<String>('session-total');
const counterLifetimeTotalKey = ValueKey<String>('lifetime-total');
const counterUndoButtonKey = ValueKey<String>('undo-button');
const counterEndSessionButtonKey = ValueKey<String>('end-session-button');

class CounterView extends ConsumerWidget {
  const CounterView({super.key});

  Future<void> _endSession(WidgetRef ref) async {
    try {
      await ref.read(counterProvider.notifier).endSession();
    } catch (_) {
      // The provider exposes the error and keeps the session for retry.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterState = ref.watch(counterProvider);
    final globalState = ref.watch(globalStateProvider);
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
            final sushiSize = (constraints.maxHeight * .23).clamp(96.0, 200.0);
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
                            key: counterCurrentCountKey,
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
                        const SizedBox(height: 24),
                        SushiButton(
                          onTap: () =>
                              ref.read(counterProvider.notifier).increment(),
                          onLongPress: () =>
                              ref.read(counterProvider.notifier).decrement(),
                          size: sushiSize,
                          enabled: counterState.canEdit,
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          key: counterUndoButtonKey,
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
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: counterEndSessionButtonKey,
                            onPressed:
                                counterState.count > 0 &&
                                    !counterState.isEnding &&
                                    !counterState.isPersisting
                                ? () => _endSession(ref)
                                : null,
                            icon: counterState.isEnding
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: const Text('End Session'),
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
                              valueKey: counterSessionTotalKey,
                            ),
                            _Metric(
                              label: 'Lifetime total',
                              value:
                                  '${globalState.lifetimeTotalTaps + counterState.count}',
                              valueKey: counterLifetimeTotalKey,
                            ),
                            if (counterState.count > 0)
                              SessionElapsedTimer(
                                startedAt: counterState.startedAt!,
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueKey});
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54)),
      Text(
        value,
        key: valueKey,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
