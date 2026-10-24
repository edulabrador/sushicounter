import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../settings_dialogs.dart';

class AboutSettingsSection extends StatelessWidget {
  const AboutSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: const SettingsIcon(Icons.privacy_tip_outlined),
      title: Text(l10n.privacyTitle),
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.privacyTitle),
          content: SingleChildScrollView(child: Text(l10n.privacyBody)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }
}
