import 'package:flutter/material.dart';

/// Constants for gamification elements throughout the app
class GamificationConstants {
  // Level thresholds
  static const int pointsPerLevel = 100;
  
  // Level titles
  static const Map<int, String> levelTitles = {
    1: 'Novice',
    2: 'Apprentice',
    3: 'Adept',
    4: 'Expert',
    5: 'Master',
    10: 'Grandmaster',
    20: 'Legend',
    50: 'Mythic',
  };
  
  // Level colors - colors get more vibrant with higher levels
  static const Map<int, Color> levelColors = {
    1: Color(0xFF64B5F6), // Light Blue
    2: Color(0xFF42A5F5), // Blue
    3: Color(0xFF2196F3), // Primary Blue
    4: Color(0xFF1E88E5), // Dark Blue
    5: Color(0xFF1976D2), // Darker Blue
    10: Color(0xFFFFB74D), // Orange
    20: Color(0xFFF06292), // Pink
    50: Color(0xFFAB47BC), // Purple
  };
  
  // Badge icons for different achievements
  static const Map<String, IconData> achievementIcons = {
    'streak': Icons.local_fire_department,
    'tasks': Icons.task_alt,
    'challenges': Icons.emoji_events,
    'aura': Icons.auto_awesome,
    'friend': Icons.people,
    'level': Icons.workspace_premium,
  };
  
  // Achievement colors
  static const Map<String, Color> achievementColors = {
    'streak': Color(0xFFFF7043), // Deep Orange
    'tasks': Color(0xFF66BB6A), // Green
    'challenges': Color(0xFFFFCA28), // Amber
    'aura': Color(0xFF42A5F5), // Blue
    'friend': Color(0xFF5C6BC0), // Indigo
    'level': Color(0xFFAB47BC), // Purple
  };
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 600);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);
  
  // Get level from points
  static int getLevelFromPoints(int points) {
    return (points / pointsPerLevel).floor() + 1;
  }
  
  // Get level title based on level
  static String getLevelTitle(int level) {
    // Find the highest threshold that is less than or equal to the level
    final thresholds = levelTitles.keys.toList()..sort();
    int highestThreshold = thresholds.first;
    
    for (final threshold in thresholds) {
      if (threshold <= level) {
        highestThreshold = threshold;
      } else {
        break;
      }
    }
    
    return levelTitles[highestThreshold] ?? 'Unknown';
  }
  
  // Get level color based on level
  static Color getLevelColor(int level) {
    // Find the highest threshold that is less than or equal to the level
    final thresholds = levelColors.keys.toList()..sort();
    int highestThreshold = thresholds.first;
    
    for (final threshold in thresholds) {
      if (threshold <= level) {
        highestThreshold = threshold;
      } else {
        break;
      }
    }
    
    return levelColors[highestThreshold] ?? Colors.blue;
  }
  
  // Get progress to next level (0.0 to 1.0)
  static double getProgressToNextLevel(int points) {
    final level = getLevelFromPoints(points);
    final pointsForCurrentLevel = (level - 1) * pointsPerLevel;
    return (points - pointsForCurrentLevel) / pointsPerLevel;
  }
}
