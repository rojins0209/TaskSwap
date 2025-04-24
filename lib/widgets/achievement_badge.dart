import 'package:flutter/material.dart';
import 'package:taskswap/constants/gamification_constants.dart';
import 'package:taskswap/theme/app_theme.dart';

/// A badge that displays an achievement with visual styling
class AchievementBadge extends StatelessWidget {
  final String type;
  final String title;
  final String? description;
  final bool unlocked;
  final double size;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.type,
    required this.title,
    this.description,
    this.unlocked = true,
    this.size = 60.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = GamificationConstants.achievementIcons[type] ?? Icons.emoji_events;
    final Color color = unlocked
        ? GamificationConstants.achievementColors[type] ?? Colors.amber
        : Colors.grey;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size * 2,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (unlocked)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                border: Border.all(
                  color: unlocked ? color : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: unlocked ? color : Colors.grey.withOpacity(0.5),
                size: size * 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: unlocked ? AppTheme.textPrimaryColor : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: AppTheme.bodySmall.copyWith(
                  color: unlocked ? AppTheme.textSecondaryColor : Colors.grey.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
