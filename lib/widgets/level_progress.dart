import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/constants/gamification_constants.dart';
import 'package:taskswap/widgets/level_badge.dart';
import 'package:taskswap/widgets/pulsing_progress_indicator.dart';

/// A widget that displays the user's level progress with visual styling
class LevelProgress extends StatelessWidget {
  final int auraPoints;
  final bool animate;
  final bool showNextLevel;
  final VoidCallback? onTap;

  const LevelProgress({
    super.key,
    required this.auraPoints,
    this.animate = true,
    this.showNextLevel = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate level based on aura points
    final int level = GamificationConstants.getLevelFromPoints(auraPoints);
    final int nextLevel = level + 1;
    // Calculate points needed for next level
    final int pointsForNextLevel = level * GamificationConstants.pointsPerLevel;
    final double progress = GamificationConstants.getProgressToNextLevel(auraPoints);

    // Get level title and color
    final String levelTitle = GamificationConstants.getLevelTitle(level);
    final Color levelColor = GamificationConstants.getLevelColor(level);

    Widget content = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? Colors.grey.withAlpha(40),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level header
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: levelColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Level Progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Level badges and progress
            Row(
              children: [
                // Current level badge
                LevelBadge(
                  level: level,
                  showTitle: true,
                  showGlow: true,
                  size: 60,
                ),

                // Progress arrow
                Expanded(
                  child: Column(
                    children: [
                      // Progress bar
                      PulsingProgressIndicator(
                        value: progress,
                        backgroundColor: levelColor.withAlpha(51),
                        valueColor: levelColor,
                        height: 10,
                        animate: animate,
                      ),
                      const SizedBox(height: 8),

                      // Points text
                      Text(
                        '$auraPoints / $pointsForNextLevel Aura Points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Next level badge (if enabled)
                if (showNextLevel)
                  LevelBadge(
                    level: nextLevel,
                    showTitle: true,
                    showGlow: false,
                    size: 50,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Level title and description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerLow
                    : levelColor.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerTheme.color ?? Colors.grey.withAlpha(40),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: levelColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are a $levelTitle',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: levelColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLevelDescription(level, levelTitle),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Apply animations if enabled
    if (animate) {
      content = content.animate()
        .fadeIn(duration: const Duration(milliseconds: 600))
        .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 600));
    }

    return content;
  }

  String _getLevelDescription(int level, String title) {
    if (level >= 20) {
      return 'You\'ve achieved legendary status! Your dedication is truly inspiring.';
    } else if (level >= 10) {
      return 'You\'ve mastered the art of productivity and consistency!';
    } else if (level >= 5) {
      return 'You\'re making excellent progress on your productivity journey!';
    } else if (level >= 3) {
      return 'You\'re building good habits and making steady progress!';
    } else {
      return 'Complete more tasks to increase your level and earn rewards!';
    }
  }
}
