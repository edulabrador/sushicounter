import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushiscore/features/counter/providers/counter_provider.dart';
import 'package:sushiscore/features/counter/widgets/sushi_button.dart';
import 'package:sushiscore/features/counter/widgets/session_timer.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/history/providers/session_provider.dart';
import 'package:sushiscore/features/settings/views/settings_view.dart';
import 'package:sushiscore/features/counter/widgets/table_section.dart';
import 'package:sushiscore/features/stats/achievements.dart';
import 'package:sushiscore/features/stats/widgets/achievements_grid.dart';
import 'package:sushiscore/features/stats/providers/records_provider.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';
import 'package:sushiscore/l10n/l10n.dart';

const counterCurrentCountKey = ValueKey<String>('current-count');
const counterSessionTotalKey = ValueKey<String>('session-total');
const counterLifetimeTotalKey = ValueKey<String>('lifetime-total');
const counterUndoButtonKey = ValueKey<String>('undo-button');
const counterEndSessionButtonKey = ValueKey<String>('end-session-button');
const counterDiscardButtonKey = ValueKey<String>('discard-session-button');

String counterErrorMessage(AppLocalizations l10n, CounterError error) =>
    switch (error) {
      CounterError.saveOngoing => l10n.errorSaveOngoing,
      CounterError.resetCurrent => l10n.errorResetCurrent,
      CounterError.completeSession => l10n.errorCompleteSession,
    };

class CounterView extends ConsumerWidget {
  const CounterView({super.key});

  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final before = computeAchievements(ref.read(sessionListProvider));
    try {
      await ref.read(counterProvider.notifier).endSession();
    } catch (_) {
      // The provider exposes the error and keeps the session for retry.
      return;
    }
    final unlocked = newlyUnlocked(
      before,
      computeAchievements(ref.read(sessionListProvider)),
    );
    if (unlocked.isEmpty) return;
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SushiArt(size: 32, mood: SushiMood.starry),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.achievementUnlocked(
                  unlocked.map((id) => id.title(l10n)).join(', '),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _discardSession(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardSessionTitle),
        content: Text(l10n.discardSessionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.discard,
              style: TextStyle(color: context.colors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final alreadySaved = await ref
          .read(counterProvider.notifier)
          .resetCurrent();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved ? l10n.sessionAlreadySaved : l10n.sessionDiscarded,
          ),
        ),
      );
    } catch (_) {
      // The provider exposes the error on screen.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final counterState = ref.watch(counterProvider.select(counterOnScreen));
    final lifetimeTaps = ref.watch(lifetimeTapsProvider);
    final startedAt = counterState.startedAt;
    final error = counterState.persistenceError;
    final best = ref.watch(lifetimeBestProvider);
    final beatingRecord = best > 0 && counterState.count > best;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.settingsTooltip,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SettingsView())),
        ),
        title: Text(l10n.appTitle),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sushiSize = (constraints.maxHeight * .23).clamp(96.0, 200.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${counterState.count}',
                            key: counterCurrentCountKey,
                            semanticsLabel: l10n.currentSessionSemantics(
                              counterState.count,
                            ),
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          counterState.count == 0
                              ? l10n.tapToStart
                              : l10n.tapHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        if (best > 0 && counterState.count > 0) ...[
                          const SizedBox(height: 16),
                          _RecordProgress(
                            count: counterState.count,
                            best: best,
                          ),
                        ],
                        const SizedBox(height: 24),
                        SushiButton(
                          mood: beatingRecord
                              ? SushiMood.starry
                              : SushiMood.happy,
                          onTap: () =>
                              ref.read(counterProvider.notifier).increment(),
                          onLongPress: () =>
                              ref.read(counterProvider.notifier).decrement(),
                          size: sushiSize,
                          enabled: counterState.canEdit,
                          count: counterState.count,
                          record: best,
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          key: counterUndoButtonKey,
                          onPressed:
                              counterState.count > 0 && counterState.canEdit
                              ? () => ref
                                    .read(counterProvider.notifier)
                                    .decrement()
                              : null,
                          icon: const Icon(Icons.undo, size: 18),
                          label: Text(l10n.undo),
                          style: TextButton.styleFrom(
                            foregroundColor: context.colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: counterEndSessionButtonKey,
                            onPressed:
                                counterState.count > 0 &&
                                    !counterState.isEnding &&
                                    !counterState.isPersisting
                                ? () => _endSession(context, ref)
                                : null,
                            icon: counterState.isEnding
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(l10n.endSession),
                          ),
                        ),
                        if (counterState.isCompletionPending)
                          TextButton.icon(
                            key: counterDiscardButtonKey,
                            onPressed: () => _discardSession(context, ref),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(l10n.discardSession),
                            style: TextButton.styleFrom(
                              foregroundColor: context.colors.danger,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        child: Column(
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _Metric(
                                      icon: Icons.restaurant,
                                      label: l10n.thisSession,
                                      value: '${counterState.count}',
                                      valueKey: counterSessionTotalKey,
                                    ),
                                  ),
                                  const VerticalDivider(width: 16),
                                  Expanded(
                                    child: _Metric(
                                      icon: Icons.all_inclusive,
                                      label: l10n.lifetimeTotal,
                                      value: '$lifetimeTaps',
                                      valueKey: counterLifetimeTotalKey,
                                    ),
                                  ),
                                  if (counterState.count > 0 &&
                                      startedAt != null) ...[
                                    const VerticalDivider(width: 16),
                                    Expanded(
                                      child: SessionElapsedTimer(
                                        startedAt: startedAt,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  counterErrorMessage(l10n, error),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.colors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TableSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueKey,
  });
  final IconData icon;
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 18, color: context.colors.accent),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.textMuted, fontSize: 13),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          key: valueKey,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

/// How close the session is to the best one of this lifetime.
class _RecordProgress extends StatelessWidget {
  const _RecordProgress({required this.count, required this.best});

  final int count;
  final int best;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final label = count > best
        ? l10n.newRecord(best)
        : count == best
        ? l10n.recordTied(best)
        : l10n.recordToBeat(best, best - count);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                count >= best ? Icons.emoji_events : Icons.flag_outlined,
                size: 16,
                color: colors.accent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: count >= best ? colors.accent : colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (count / best).clamp(0.0, 1.0),
              minHeight: 8,
              semanticsLabel: label,
            ),
          ),
        ],
      ),
    );
  }
}
