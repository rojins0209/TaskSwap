import 'package:flutter/material.dart';
import 'package:taskswap/constants/gamification_constants.dart';

/// A badge that displays the user's level with visual styling
class LevelBadge extends StatelessWidget {
  final int level;
  final double size;
  final bool showTitle;
  final bool showGlow;
  final VoidCallback? onTap;

  const LevelBadge({
    super.key,
    required this.level,
    this.size = 40.0,
    this.showTitle = false,
    this.showGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = GamificationConstants.getLevelColor(level);
    final title = GamificationConstants.getLevelTitle(level);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(40),
              border: Border.all(
                color: color,
                width: 2,
              ),
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: color.withAlpha(102),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (showTitle) ...[
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
