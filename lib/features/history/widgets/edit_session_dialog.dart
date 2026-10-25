import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/l10n/l10n.dart';

typedef SessionEdit = ({int count, DateTime startedAt});

/// Corrects a saved session: its pieces and when it started. The duration
/// stays, so the end moves with the start.
class EditSessionDialog extends StatefulWidget {
  const EditSessionDialog({super.key, required this.session});

  final Session session;

  @override
  State<EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<EditSessionDialog> {
  late final TextEditingController _count = TextEditingController(
    text: '${widget.session.count}',
  );
  late DateTime _startedAt = widget.session.startedAt;
  String? _error;

  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  Duration get _duration => Duration(seconds: widget.session.durationSeconds);

  Future<void> _pickStart() async {
    final now = clock.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startedAt.isAfter(now) ? now : _startedAt,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  void _save() {
    final l10n = context.l10n;
    final count = int.tryParse(_count.text.trim());
    if (count == null || count < 1 || count > Session.maxCount) {
      setState(() => _error = l10n.countInvalid(Session.maxCount));
      return;
    }
    if (_startedAt.add(_duration).isAfter(clock.now())) {
      setState(() => _error = l10n.sessionInFuture);
      return;
    }
    Navigator.pop<SessionEdit>(context, (count: count, startedAt: _startedAt));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = context.localeName;
    final start = DateFormat.yMMMd(locale).add_Hm().format(_startedAt);
    return AlertDialog(
      title: Text(l10n.editSession),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _count,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.detailPieces,
              prefixIcon: const Icon(Icons.restaurant),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: colors.background,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Icon(Icons.event_outlined, color: colors.accent),
              title: Text(l10n.sessionStart),
              subtitle: Text(start),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickStart,
            ),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(error, style: TextStyle(color: colors.danger)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
