import 'package:flutter/material.dart';
import 'package:sushiscore/core/theme/app_colors.dart';
import 'package:sushiscore/features/stats/achievements.dart';
import 'package:sushiscore/l10n/l10n.dart';
import 'package:sushiscore/shared/art/sushi_art.dart';

extension AchievementText on AchievementId {
  String title(AppLocalizations l10n) => switch (this) {
    AchievementId.firstSession => l10n.achFirstSession,
    AchievementId.tenSessions => l10n.achTenSessions,
    AchievementId.fiftySessions => l10n.achFiftySessions,
    AchievementId.bigAppetite => l10n.achBigAppetite,
    AchievementId.sushiMaster => l10n.achSushiMaster,
    AchievementId.hundredPieces => l10n.achHundredPieces,
    AchievementId.thousandPieces => l10n.achThousandPieces,
    AchievementId.regular => l10n.achRegular,
    AchievementId.priceWatcher => l10n.achPriceWatcher,
    AchievementId.explorer => l10n.achExplorer,
  };

  String description(AppLocalizations l10n) => switch (this) {
    AchievementId.firstSession => l10n.achFirstSessionDesc,
    AchievementId.tenSessions => l10n.achTenSessionsDesc,
    AchievementId.fiftySessions => l10n.achFiftySessionsDesc,
    AchievementId.bigAppetite => l10n.achBigAppetiteDesc,
    AchievementId.sushiMaster => l10n.achSushiMasterDesc,
    AchievementId.hundredPieces => l10n.achHundredPiecesDesc,
    AchievementId.thousandPieces => l10n.achThousandPiecesDesc,
    AchievementId.regular => l10n.achRegularDesc,
    AchievementId.priceWatcher => l10n.achPriceWatcherDesc,
    AchievementId.explorer => l10n.achExplorerDesc,
  };
}

/// Earned achievements wear the starry nigiri; locked ones sleep and show
/// how far along they are.
class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({
    super.key,
    required this.achievements,
    required this.width,
  });

  final List<Achievement> achievements;
  final double width;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    final columns = width >= 600 ? 3 : 2;
    final tileWidth = (width - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final achievement in achievements)
          SizedBox(
            width: tileWidth,
            child: _AchievementTile(achievement: achievement),
          ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final unlocked = achievement.unlocked;
    final title = achievement.id.title(l10n);
    final description = achievement.id.description(l10n);
    final progress = l10n.achievementProgress(
      achievement.shownProgress,
      achievement.target,
    );
    return Semantics(
      label: '$title. $description. $progress',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Opacity(
                    opacity: unlocked ? 1 : 0.45,
                    child: SushiArt(
                      size: 36,
                      mood: unlocked ? SushiMood.starry : SushiMood.sleepy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: unlocked
                          ? Icon(
                              Icons.check_circle,
                              color: colors.accent,
                              size: 20,
                            )
                          // Shrinks rather than overflowing narrow tiles.
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                progress,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: unlocked ? colors.text : colors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              if (!unlocked) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.shownProgress / achievement.target,
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
