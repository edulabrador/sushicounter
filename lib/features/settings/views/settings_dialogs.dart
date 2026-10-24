import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';

/// Replaces any visible snackbar, so quick actions never queue stale messages.
void showSettingsMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// A cancel / destructive-action dialog. True only if the user confirmed and
/// [context] is still mounted.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final l10n = context.l10n;
  final danger = context.colors.danger;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(action, style: TextStyle(color: danger)),
        ),
      ],
    ),
  );
  return confirm == true && context.mounted;
}

/// Leading icon for settings rows, boxed like the Stats tiles.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, {super.key, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.colors.danger : context.colors.accent;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
