import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import 'sections/about_section.dart';
import 'sections/data_section.dart';
import 'sections/preferences_section.dart';
import 'sections/session_section.dart';

export 'sections/session_section.dart' show matchesResetKeyword;

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.settingsTitle)),
    body: ListView(
      children: const [
        SessionSettingsSection(),
        Divider(),
        PreferencesSettingsSection(),
        Divider(),
        DataSettingsSection(),
        Divider(),
        AboutSettingsSection(),
      ],
    ),
  );
}
