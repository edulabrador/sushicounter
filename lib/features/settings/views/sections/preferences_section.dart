import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n.dart';
import '../../providers/preferences_provider.dart';
import '../settings_dialogs.dart';

class PreferencesSettingsSection extends ConsumerWidget {
  const PreferencesSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      secondary: const Icon(Icons.light_mode_outlined),
      title: Text(l10n.keepScreenOnTitle),
      subtitle: Text(l10n.keepScreenOnSubtitle),
      value: ref.watch(keepScreenOnProvider),
      onChanged: (value) async {
        try {
          await ref.read(keepScreenOnProvider.notifier).set(value);
        } catch (_) {
          if (context.mounted) {
            showSettingsMessage(context, l10n.couldNotSaveSetting);
          }
        }
      },
    );
  }
}
