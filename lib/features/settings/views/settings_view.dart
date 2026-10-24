import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/providers/storage_provider.dart';
import 'package:sushiscore/core/storage/backup.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/global/providers/global_provider.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/settings/providers/preferences_provider.dart';
import 'package:sushiscore/l10n/l10n.dart';

/// Whether [input] confirms the reset. Case and surrounding spaces are
/// forgiven; the word itself is still required.
bool matchesResetKeyword(String input, String keyword) =>
    input.trim().toUpperCase() == keyword.toUpperCase();

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _busy = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirm == true && mounted;
  }

  Future<void> _resetCurrentSession() async {
    final l10n = context.l10n;
    if (!await _confirm(
      title: l10n.resetCurrentDialogTitle,
      body: l10n.resetCurrentDialogBody,
      action: l10n.reset,
    )) {
      return;
    }
    try {
      await ref.read(counterProvider.notifier).resetCurrent();
      _showMessage(l10n.currentSessionReset);
    } catch (_) {
      _showMessage(l10n.errorResetCurrent);
    }
  }

  Future<void> _resetGlobalCounter() async {
    if (!ref.read(counterProvider).canResetLifetime) return;
    final l10n = context.l10n;
    final keyword = l10n.resetKeyword;
    final strongConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        String input = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final matches = matchesResetKeyword(input, keyword);
            return AlertDialog(
              title: Text(l10n.permanentReset),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.permanentResetBody(keyword),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (val) => setState(() => input = val),
                    onSubmitted: (_) {
                      if (matches) Navigator.pop(context, true);
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: keyword,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: matches
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: Text(l10n.confirmReset),
                ),
              ],
            );
          },
        );
      },
    );

    if (strongConfirm != true ||
        !mounted ||
        !ref.read(counterProvider).canResetLifetime) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(globalStateProvider.notifier).resetGlobal();
      _showMessage(l10n.lifetimeResetDone);
    } catch (_) {
      _showMessage(l10n.couldNotResetLifetime);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setKeepScreenOn(bool value) async {
    final failed = context.l10n.couldNotSaveSetting;
    try {
      await ref.read(keepScreenOnProvider.notifier).set(value);
    } catch (_) {
      _showMessage(failed);
    }
  }

  Future<void> _export() async {
    final l10n = context.l10n;
    final backup = ref.read(storageProvider).exportBackup();
    await Clipboard.setData(ClipboardData(text: encodeBackup(backup)));
    _showMessage(l10n.exportDone(backup.sessions.length));
  }

  Future<void> _import() async {
    final l10n = context.l10n;
    final source = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportDialog(),
    );
    if (source == null || !mounted) return;
    final BackupData backup;
    try {
      backup = decodeBackup(source);
    } on FormatException {
      _showMessage(l10n.importInvalid);
      return;
    }
    // Same guard as a lifetime reset: an active session would be lost.
    if (!ref.read(counterProvider).canResetLifetime) return;
    setState(() => _busy = true);
    try {
      await ref.read(storageProvider).importBackup(backup);
      if (!mounted) return;
      ref.read(globalStateProvider.notifier).reload();
      ref.read(sessionListProvider.notifier).reload();
      _showMessage(l10n.importDone(backup.sessions.length));
    } catch (_) {
      _showMessage(l10n.importFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final counterState = ref.watch(counterProvider);
    final idle = counterState.canResetLifetime && !_busy;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.resetCurrentTitle),
            subtitle: Text(l10n.resetCurrentSubtitle),
            onTap: _busy || !counterState.canDiscard
                ? null
                : _resetCurrentSession,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              l10n.resetLifetimeTitle,
              style: const TextStyle(color: Colors.red),
            ),
            subtitle: Text(
              counterState.canResetLifetime
                  ? l10n.resetLifetimeSubtitle
                  : l10n.finishSessionFirst,
            ),
            onTap: idle ? _resetGlobalCounter : null,
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.light_mode_outlined),
            title: Text(l10n.keepScreenOnTitle),
            subtitle: Text(l10n.keepScreenOnSubtitle),
            value: ref.watch(keepScreenOnProvider),
            onChanged: _setKeepScreenOn,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(l10n.exportTitle),
            subtitle: Text(l10n.exportSubtitle),
            onTap: _busy ? null : _export,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.importTitle),
            subtitle: Text(
              counterState.canResetLifetime
                  ? l10n.importSubtitle
                  : l10n.finishSessionFirst,
            ),
            onTap: idle ? _import : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
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
          ),
        ],
      ),
    );
  }
}

/// Owns its text controller so it outlives the dialog's closing animation.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && mounted) _controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.importDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.importDialogBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: l10n.importPaste,
                icon: const Icon(Icons.content_paste),
                onPressed: _paste,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(
            l10n.importConfirm,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
