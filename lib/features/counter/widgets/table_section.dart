import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/l10n/l10n.dart';

/// Counters for the others at the table, under your own.
class TableSection extends ConsumerWidget {
  const TableSection({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(counterProvider.notifier);
    await showDialog<void>(
      context: context,
      builder: (_) => _AddCompanionDialog(onAdd: notifier.addCompanion),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    int index,
    Companion companion,
  ) async {
    final l10n = context.l10n;
    if (companion.count > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
            l10n.companionRemoveConfirm(
              companion.name,
              l10n.piecesCount(companion.count),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.remove),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    ref.read(counterProvider.notifier).removeCompanion(index);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (companions, canEdit, total) = ref.watch(
      counterProvider.select((s) => (s.companions, s.canEdit, s.tableTotal)),
    );
    final canAdd = canEdit && companions.length < Companion.maxPerTable;
    if (companions.isEmpty) {
      return TextButton.icon(
        onPressed: canAdd ? () => _add(context, ref) : null,
        icon: const Icon(Icons.group_add_outlined),
        label: Text(l10n.addCompanion),
        style: TextButton.styleFrom(foregroundColor: colors.accent),
      );
    }
    final notifier = ref.read(counterProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_outlined, size: 20, color: colors.accent),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tableTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Text(
                  l10n.tableTotal(l10n.piecesCount(total)),
                  style: TextStyle(color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final (index, companion) in companions.indexed)
              _CompanionRow(
                companion: companion,
                enabled: canEdit,
                onAdd: () {
                  HapticFeedback.lightImpact();
                  notifier.incrementCompanion(index);
                },
                onTakeOne: () {
                  HapticFeedback.lightImpact();
                  notifier.decrementCompanion(index);
                },
                onRemove: () => _remove(context, ref, index, companion),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: canAdd ? () => _add(context, ref) : null,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(l10n.addCompanionShort),
                style: TextButton.styleFrom(foregroundColor: colors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionRow extends StatelessWidget {
  const _CompanionRow({
    required this.companion,
    required this.enabled,
    required this.onAdd,
    required this.onTakeOne,
    required this.onRemove,
  });

  final Companion companion;
  final bool enabled;
  final VoidCallback onAdd;
  final VoidCallback onTakeOne;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final name = companion.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colors.accent,
              foregroundColor: colors.onAccent,
              child: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: l10n.companionCountSemantics(
                name,
                l10n.piecesCount(companion.count),
              ),
              excludeSemantics: true,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            onPressed: enabled && companion.count > 0 ? onTakeOne : null,
            tooltip: l10n.companionTakeOne(name),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32),
            child: ExcludeSemantics(
              child: Text(
                '${companion.count}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: enabled ? onAdd : null,
            tooltip: l10n.companionAddOne(name),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: enabled ? onRemove : null,
            tooltip: l10n.companionRemove(name),
            icon: Icon(Icons.close, size: 20, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AddCompanionDialog extends StatefulWidget {
  const _AddCompanionDialog({required this.onAdd});

  /// Returns false when the name is blank, repeated or the table is full.
  final bool Function(String name) onAdd;

  @override
  State<_AddCompanionDialog> createState() => _AddCompanionDialogState();
}

class _AddCompanionDialogState extends State<_AddCompanionDialog> {
  final _controller = TextEditingController();
  bool _rejected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (Companion.normalizeName(_controller.text) == null) return;
    if (widget.onAdd(_controller.text)) {
      Navigator.pop(context);
    } else {
      setState(() => _rejected = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.companionDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: Companion.maxNameLength,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _save(),
        onChanged: (_) {
          if (_rejected) setState(() => _rejected = false);
        },
        decoration: InputDecoration(
          hintText: l10n.companionNameHint,
          errorText: _rejected ? l10n.companionDuplicate : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.add)),
      ],
    );
  }
}
