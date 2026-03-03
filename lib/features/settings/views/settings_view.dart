import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../counter/providers/counter_provider.dart';
import '../../global/providers/global_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  void _resetCurrentSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Current Session?'),
        content: const Text('This will clear your ongoing taps without saving.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(counterProvider.notifier).resetCurrent();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current session reset.')));
    }
  }

  void _resetGlobalCounter() async {
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
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: input == 'RESET' ? () => Navigator.pop(context, true) : null,
                  child: const Text('CONFIRM RESET'),
                ),
              ],
            );
          },
        );
      },
    );

    if (strongConfirm == true) {
      await ref.read(globalStateProvider.notifier).resetGlobal();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Global lifetime stats reset.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Current Session'),
            subtitle: const Text('Clear active taps without saving'),
            onTap: _resetCurrentSession,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset Lifetime Global', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently reset all-time taps and sessions to 0'),
            onTap: _resetGlobalCounter,
          ),
        ],
      ),
    );
  }
}
