import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../counter/providers/counter_provider.dart';
import '../../../global/providers/global_provider.dart';
import '../settings_dialogs.dart';

/// Whether [input] confirms the reset. Case and surrounding spaces are
/// forgiven; the word itself is still required.
bool matchesResetKeyword(String input, String keyword) =>
    input.trim().toUpperCase() == keyword.toUpperCase();

/// Resetting the current session and the lifetime totals.
class SessionSettingsSection extends ConsumerStatefulWidget {
  const SessionSettingsSection({super.key});

  @override
  ConsumerState<SessionSettingsSection> createState() =>
      _SessionSettingsSectionState();
}

class _SessionSettingsSectionState
    extends ConsumerState<SessionSettingsSection> {
  bool _busy = false;

  Future<void> _resetCurrentSession() async {
    final l10n = context.l10n;
    if (!await confirmDestructive(
      context,
      title: l10n.resetCurrentDialogTitle,
      body: l10n.resetCurrentDialogBody,
      action: l10n.reset,
    )) {
      return;
    }
    try {
      final alreadySaved = await ref
          .read(counterProvider.notifier)
          .resetCurrent();
      if (!mounted) return;
      showSettingsMessage(
        context,
        alreadySaved ? l10n.sessionAlreadySaved : l10n.currentSessionReset,
      );
    } catch (_) {
      if (mounted) showSettingsMessage(context, l10n.errorResetCurrent);
    }
  }

  Future<void> _resetLifetime() async {
    if (!ref.read(counterProvider).canResetLifetime) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ResetLifetimeDialog(keyword: l10n.resetKeyword),
    );
    if (confirmed != true ||
        !mounted ||
        !ref.read(counterProvider).canResetLifetime) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(globalStateProvider.notifier).resetGlobal();
      if (mounted) showSettingsMessage(context, l10n.lifetimeResetDone);
    } catch (_) {
      if (mounted) showSettingsMessage(context, l10n.couldNotResetLifetime);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final danger = context.colors.danger;
    final counter = ref.watch(counterProvider);
    return Column(
      children: [
        ListTile(
          leading: const SettingsIcon(Icons.refresh),
          title: Text(l10n.resetCurrentTitle),
          subtitle: Text(l10n.resetCurrentSubtitle),
          onTap: _busy || !counter.canDiscard ? null : _resetCurrentSession,
        ),
        const Divider(height: 1, indent: 68),
        ListTile(
          leading: const SettingsIcon(Icons.delete_forever, danger: true),
          title: Text(l10n.resetLifetimeTitle, style: TextStyle(color: danger)),
          subtitle: Text(
            counter.canResetLifetime
                ? l10n.resetLifetimeSubtitle
                : l10n.finishSessionFirst,
          ),
          onTap: _busy || !counter.canResetLifetime ? null : _resetLifetime,
        ),
      ],
    );
  }
}

class _ResetLifetimeDialog extends StatefulWidget {
  const _ResetLifetimeDialog({required this.keyword});

  final String keyword;

  @override
  State<_ResetLifetimeDialog> createState() => _ResetLifetimeDialogState();
}

class _ResetLifetimeDialogState extends State<_ResetLifetimeDialog> {
  String _input = '';

  bool get _matches => matchesResetKeyword(_input, widget.keyword);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final danger = context.colors.danger;
    return AlertDialog(
      title: Text(l10n.permanentReset),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.permanentResetBody(widget.keyword),
            style: TextStyle(color: danger),
          ),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) => setState(() => _input = value),
            onSubmitted: (_) {
              if (_matches) Navigator.pop(context, true);
            },
            decoration: InputDecoration(hintText: widget.keyword),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: danger,
            foregroundColor: context.colors.onDanger,
          ),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: Text(l10n.confirmReset),
        ),
      ],
    );
  }
}
