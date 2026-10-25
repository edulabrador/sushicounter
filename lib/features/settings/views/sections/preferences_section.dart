import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        ListTile(
          leading: const SettingsIcon(Icons.flag_outlined),
          title: Text(l10n.sessionGoalTitle),
          subtitle: Text(switch (ref.watch(sessionGoalProvider)) {
            null => l10n.sessionGoalOff,
            final goal => l10n.piecesCount(goal),
          }),
          onTap: () async {
            final result = await showDialog<({int? goal})>(
              context: context,
              builder: (_) =>
                  _GoalDialog(initial: ref.read(sessionGoalProvider)),
            );
            if (result == null || !context.mounted) return;
            await _save(
              context,
              () => ref.read(sessionGoalProvider.notifier).set(result.goal),
            );
          },
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

/// Null goal means "turn the goal off".
class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.initial});

  final int? initial;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final goal = int.tryParse(_controller.text.trim());
    if (goal == null || goal < 1 || goal > Preferences.maxSessionGoal) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop<({int? goal})>(context, (goal: goal));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.sessionGoalDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.flag_outlined),
          errorText: _invalid
              ? l10n.countInvalid(Preferences.maxSessionGoal)
              : null,
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () =>
                Navigator.pop<({int? goal})>(context, (goal: null)),
            child: Text(l10n.turnOff),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
