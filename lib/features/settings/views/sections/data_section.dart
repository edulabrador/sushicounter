import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/platform/backup_files.dart';
import '../../../../core/providers/storage_provider.dart';
import '../../../../core/storage/backup.dart';
import '../../../../l10n/l10n.dart';
import '../../../counter/providers/counter_provider.dart';
import '../../../global/providers/global_provider.dart';
import '../../../history/providers/session_provider.dart';
import '../settings_dialogs.dart';

/// File name offered when saving, e.g. sushi-tracker-2026-10-24.json.
String backupFileName(DateTime now) =>
    'sushi-tracker-${DateFormat('yyyy-MM-dd').format(now)}.json';

/// Export and import of all data. Uses the Android document picker, and the
/// clipboard where there is none (web, desktop).
class DataSettingsSection extends ConsumerStatefulWidget {
  const DataSettingsSection({super.key});

  @override
  ConsumerState<DataSettingsSection> createState() =>
      _DataSettingsSectionState();
}

class _DataSettingsSectionState extends ConsumerState<DataSettingsSection> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final l10n = context.l10n;
    final backup = ref.read(storageProvider).exportBackup();
    final content = encodeBackup(backup);
    final count = backup.sessions.length;
    final SaveOutcome outcome;
    try {
      outcome = await ref
          .read(backupFilesProvider)
          .save(backupFileName(DateTime.now()), content);
    } on PlatformException {
      if (mounted) showSettingsMessage(context, l10n.couldNotSaveFile);
      return;
    }
    if (!mounted) return;
    switch (outcome) {
      case SaveOutcome.saved:
        showSettingsMessage(context, l10n.exportSaved(count));
      case SaveOutcome.cancelled:
        break;
      case SaveOutcome.unsupported:
        await Clipboard.setData(ClipboardData(text: content));
        if (mounted) showSettingsMessage(context, l10n.exportDone(count));
    }
  });

  Future<void> _import() => _run(() async {
    final l10n = context.l10n;
    if (!ref.read(counterProvider).canResetLifetime) return;
    String? source;
    try {
      final opened = await ref.read(backupFilesProvider).open();
      if (!mounted) return;
      source = opened.supported
          ? opened.text
          : await showDialog<String>(
              context: context,
              builder: (_) => const _PasteBackupDialog(),
            );
    } on PlatformException {
      if (mounted) showSettingsMessage(context, l10n.couldNotReadFile);
      return;
    }
    if (source == null || !mounted) return;

    final BackupData backup;
    try {
      backup = decodeBackup(source);
    } on FormatException {
      showSettingsMessage(context, l10n.importInvalid);
      return;
    }
    if (!await confirmDestructive(
      context,
      title: l10n.importConfirmTitle,
      body: l10n.importConfirmBody(backup.sessions.length),
      action: l10n.importConfirm,
    )) {
      return;
    }
    // Checked again: a session may have started while the dialogs were open.
    if (!ref.read(counterProvider).canResetLifetime) return;
    try {
      await ref.read(storageProvider).importBackup(backup);
      if (!mounted) return;
      ref.read(globalStateProvider.notifier).reload();
      ref.read(sessionListProvider.notifier).reload();
      showSettingsMessage(context, l10n.importDone(backup.sessions.length));
    } catch (_) {
      if (mounted) showSettingsMessage(context, l10n.importFailed);
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final idle = ref.watch(counterProvider).canResetLifetime;
    return Column(
      children: [
        ListTile(
          leading: const SettingsIcon(Icons.upload_outlined),
          title: Text(l10n.exportTitle),
          subtitle: Text(l10n.exportSubtitle),
          onTap: _busy ? null : _export,
        ),
        const Divider(height: 1, indent: 68),
        ListTile(
          leading: const SettingsIcon(Icons.download_outlined),
          title: Text(l10n.importTitle),
          subtitle: Text(idle ? l10n.importSubtitle : l10n.finishSessionFirst),
          onTap: _busy || !idle ? null : _import,
        ),
      ],
    );
  }
}

/// Fallback where there is no document picker. Owns its controller so it
/// outlives the dialog's closing animation.
class _PasteBackupDialog extends StatefulWidget {
  const _PasteBackupDialog();

  @override
  State<_PasteBackupDialog> createState() => _PasteBackupDialogState();
}

class _PasteBackupDialogState extends State<_PasteBackupDialog> {
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
          child: Text(l10n.importNext),
        ),
      ],
    );
  }
}
