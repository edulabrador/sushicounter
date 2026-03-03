import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/counter_provider.dart';
import '../../global/providers/global_provider.dart';
import '../../settings/views/settings_view.dart';

class CounterView extends ConsumerWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterState = ref.watch(counterProvider);
    final globalState = ref.watch(globalStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsView()),
            );
          },
        ),
        title: const Text('SUSHI SCORE'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Giant Counter Number
            Text(
              '${counterState.count}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap the sushi to begin!',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 48),

            // Sushi Button
            GestureDetector(
              onTap: () {
                ref.read(counterProvider.notifier).increment();
              },
              onLongPress: () {
                ref.read(counterProvider.notifier).decrement();
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent, // Invisible hit area expanded
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Nori
                      Container(
                        width: 140,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      // Rice
                      Container(
                        width: 120,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      // Salmon / Orange center
                      Container(
                        width: 100,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Eyes
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                            const SizedBox(width: 24),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Bottom Rounded Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Session', style: TextStyle(color: Colors.white54)),
                          Text('${counterState.count}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Global', style: TextStyle(color: Colors.white54)),
                          Text('${globalState.lifetimeTotalTaps}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: counterState.count > 0
                            ? () {
                                ref.read(counterProvider.notifier).endSession();
                              }
                            : null,
                        child: const Text('End Session'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
