import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/art/sushi_art.dart';
import 'sections/about_section.dart';
import 'sections/data_section.dart';
import 'sections/preferences_section.dart';
import 'sections/session_section.dart';

export 'sections/session_section.dart' show matchesResetKeyword;

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        // Clear of the system bars and any display cutout, edge to edge.
        padding:
            MediaQuery.paddingOf(context).copyWith(top: 0) +
            const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SushiArt(size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        l10n.settingsTagline,
                        style: TextStyle(color: context.colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SettingsGroup(
            title: l10n.settingsSectionSession,
            child: const SessionSettingsSection(),
          ),
          _SettingsGroup(
            title: l10n.settingsSectionPreferences,
            child: const PreferencesSettingsSection(),
          ),
          _SettingsGroup(
            title: l10n.settingsSectionData,
            child: const DataSettingsSection(),
          ),
          _SettingsGroup(
            title: l10n.settingsSectionAbout,
            child: const AboutSettingsSection(),
          ),
        ],
      ),
    );
  }
}

/// A titled card that groups related settings.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: child,
          ),
        ),
      ],
    ),
  );
}
