import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/settings/views/settings_view.dart';

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
        title: const Text('SUSHI SCORE'),
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
                        const Text(
                          'Tap the sushi to begin!',
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
                              label: 'Session',
                              value: '${counterState.count}',
                            ),
                            _Metric(
                              label: 'Global',
                              value: '${globalState.lifetimeTotalTaps}',
                            ),
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
