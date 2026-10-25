import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/preferences.dart';
import '../../../../l10n/l10n.dart';
import '../../providers/preferences_provider.dart';
import '../settings_dialogs.dart';

class PreferencesSettingsSection extends ConsumerWidget {
  const PreferencesSettingsSection({super.key});

  Future<void> _save(
    BuildContext context,
    Future<void> Function() write,
  ) async {
    final failed = context.l10n.couldNotSaveSetting;
    try {
      await write();
    } catch (_) {
      if (context.mounted) showSettingsMessage(context, failed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    return Column(
      children: [
        ListTile(
          leading: const SettingsIcon(Icons.palette_outlined),
          title: Text(l10n.appearanceTitle),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<Appearance>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: Appearance.dark,
                    label: Text(l10n.appearanceDark),
                  ),
                  ButtonSegment(
                    value: Appearance.light,
                    label: Text(l10n.appearanceLight),
                  ),
                  ButtonSegment(
                    value: Appearance.system,
                    label: Text(l10n.appearanceSystem),
                  ),
                ],
                selected: {appearance},
                onSelectionChanged: (selection) => _save(
                  context,
                  () => ref
                      .read(appearanceProvider.notifier)
                      .set(selection.first),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1, indent: 68),
        SwitchListTile(
          secondary: const SettingsIcon(Icons.wb_sunny_outlined),
          title: Text(l10n.keepScreenOnTitle),
          subtitle: Text(l10n.keepScreenOnSubtitle),
          value: ref.watch(keepScreenOnProvider),
          onChanged: (value) => _save(
            context,
            () => ref.read(keepScreenOnProvider.notifier).set(value),
          ),
        ),
      ],
    );
  }
}
