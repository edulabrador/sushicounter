import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _resetting = false;

  void _resetCurrentSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Current Session?'),
        content: const Text(
          'This will clear your ongoing taps without saving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(counterProvider.notifier).resetCurrent();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Current session reset.')));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reset the current session.')),
        );
      }
    }
  }

  void _resetGlobalCounter() async {
    if (!ref.read(counterProvider).canResetLifetime) return;
    final strongConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        String input = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('PERMANENT RESET'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This action permanently wipes your lifetime stats. Session history remains intact but totals return to 0.\n\nType "RESET" to confirm.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => setState(() => input = val),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: input == 'RESET'
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text('CONFIRM RESET'),
                ),
              ],
            );
          },
        );
      },
    );

    if (strongConfirm == true && mounted &&
        ref.read(counterProvider).canResetLifetime) {
      setState(() => _resetting = true);
      try {
        await ref.read(globalStateProvider.notifier).resetGlobal();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Global lifetime stats reset.')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not reset lifetime stats. Please try again.',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _resetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final counterState = ref.watch(counterProvider);
    final canResetLifetime = counterState.canResetLifetime;
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Current Session'),
            subtitle: const Text('Clear active taps without saving'),
            onTap: _resetting || !counterState.canEdit
                ? null
                : _resetCurrentSession,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Reset Lifetime Global',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: Text(
              canResetLifetime
                  ? 'Permanently reset all-time taps and sessions to 0'
                  : 'End or reset the current session first.',
            ),
            onTap: _resetting || !canResetLifetime
                ? null
                : _resetGlobalCounter,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Privacy Policy'),
                content: const SingleChildScrollView(
                  child: Text(
                    'Sushi Tracker does not collect, transmit, or share personal data. '
                    'It has no accounts, analytics, ads, or network services.\n\n'
                    'Your counts, session history, and lifetime totals stay on this device. '
                    'Clearing the app data or uninstalling the app removes them.\n\n'
                    'The app requests no special device permissions.\n\n'
                    'For questions, contact labradorsantoseduardo@gmail.com.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
