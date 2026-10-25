import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sushiscore/core/format/money.dart';
import 'package:sushiscore/core/models/session.dart';
import 'package:sushiscore/core/platform/image_sharer.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/history/history_entries.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

enum ShareResult { shared, copied, failed }

/// Width of the card in logical pixels; it is captured at 1080 px wide.
const shareCardWidth = 320.0;
const _imageWidth = 1080.0;

/// The words that go with the image, and the clipboard text where images
/// cannot be shared.
String shareSummary(BuildContext context, Session session) {
  final l10n = context.l10n;
  final pieces = l10n.piecesCount(session.count);
  final date = DateFormat.yMMMd(context.localeName).format(session.endedAt);
  final place = session.restaurant;
  return place == null
      ? l10n.shareText(pieces, date)
      : l10n.shareTextAt(pieces, place, date);
}

/// File name for the shared image, from when the session ended.
String shareFileName(Session session) =>
    'sushi-session-${DateFormat('yyyyMMdd-HHmm').format(session.endedAt)}.png';

/// Previews the session card and shares it as an image.
class ShareSessionDialog extends ConsumerStatefulWidget {
  const ShareSessionDialog({
    super.key,
    required this.session,
    required this.isRecord,
  });

  final Session session;
  final bool isRecord;

  @override
  ConsumerState<ShareSessionDialog> createState() => _ShareSessionDialogState();
}

class _ShareSessionDialogState extends ConsumerState<ShareSessionDialog> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<Uint8List> _capture() async {
    final boundary =
        _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: _imageWidth / shareCardWidth,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    final text = shareSummary(context, widget.session);
    var result = ShareResult.failed;
    try {
      final shared = await ref
          .read(imageSharerProvider)
          .share(
            png: await _capture(),
            name: shareFileName(widget.session),
            text: text,
            title: l10n.shareSession,
          );
      if (!shared) await Clipboard.setData(ClipboardData(text: text));
      result = shared ? ShareResult.shared : ShareResult.copied;
    } catch (_) {
      result = ShareResult.failed;
    }
    if (mounted) Navigator.pop<ShareResult>(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.shareSession),
      content: SingleChildScrollView(
        child: Center(
          child: FittedBox(
            child: RepaintBoundary(
              key: _card,
              child: SessionShareCard(
                session: widget.session,
                isRecord: widget.isRecord,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.share),
        ),
      ],
    );
  }
}

/// The shareable card: always the dark palette, at a fixed size and text
/// scale, so every shared image looks the same.
class SessionShareCard extends StatelessWidget {
  const SessionShareCard({
    super.key,
    required this.session,
    required this.isRecord,
  });

  final Session session;
  final bool isRecord;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeName;
    const colors = AppColors.dark;
    final pace = session.tapsPerMinute;
    final price = session.priceCents;
    final details = [
      (Icons.timer_outlined, formatSessionSeconds(session.durationSeconds)),
      if (pace != null)
        (Icons.speed, l10n.paceValue(NumberFormat('0.0', locale).format(pace))),
      if (price != null) (Icons.payments_outlined, formatMoney(context, price)),
    ];
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: shareCardWidth,
        height: shareCardWidth * 5 / 4,
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 0.9,
            colors: [Color(0xFF1E2A47), Color(0xFF0F172A)],
          ),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sushi Tracker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd(locale).format(session.endedAt),
                    style: const TextStyle(
                      color: Color(0xFFA6B0C0),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: SushiArt(
                  size: 116,
                  mood: isRecord ? SushiMood.starry : SushiMood.happy,
                ),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${session.count}',
                      style: const TextStyle(
                        color: Color(0xFFF7A072),
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.piecesLabel(session.count),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.restaurant case final place?) ...[
                const SizedBox(height: 6),
                Text(
                  place,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA6B0C0),
                    fontSize: 15,
                  ),
                ),
              ],
              if (isRecord) ...[
                const SizedBox(height: 10),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 15,
                            color: colors.onAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.recordBadge,
                            style: TextStyle(
                              color: colors.onAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (icon, value) in details)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 15, color: colors.accent),
                            const SizedBox(width: 5),
                            Text(value, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
