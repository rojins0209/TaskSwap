import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/challenge_model.dart';
import 'package:taskswap/models/user_model.dart';

/// Service for updating home screen widgets with the latest data
class WidgetService {
  static const String _userStatsKey = 'flutter.widget_user_stats';
  static const String _tasksKey = 'flutter.widget_tasks';
  static const String _challengesKey = 'flutter.widget_challenges';

  /// Update the user stats widget data
  Future<bool> updateUserStatsWidget(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a simplified map with just the data needed for the widget
      final widgetData = {
        'auraPoints': userData['auraPoints'] ?? 0,
        'streakCount': userData['streakCount'] ?? 0,
        'completedTasks': userData['completedTasks'] ?? 0,
        'totalTasks': userData['totalTasks'] ?? 0,
      };

      // Save to SharedPreferences
      final result = await prefs.setString(_userStatsKey, jsonEncode(widgetData));

      debugPrint('Updated user stats widget data: $widgetData');
      return result;
    } catch (e) {
      debugPrint('Error updating user stats widget: $e');
      return false;
    }
  }

  /// Update the tasks widget data
  Future<bool> updateTasksWidget(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Filter to only include incomplete tasks and limit to 5
      final incompleteTasks = tasks
          .where((task) => !task.isCompleted)
          .take(5)
          .toList();

      // Create a simplified list with just the data needed for the widget
      final widgetData = incompleteTasks.map((task) => {
        'title': task.title,
        'dueDate': task.dueDate?.millisecondsSinceEpoch,
      }).toList();

      // Save to SharedPreferences
      final result = await prefs.setString(_tasksKey, jsonEncode(widgetData));

      debugPrint('Updated tasks widget data with ${widgetData.length} tasks');
      return result;
    } catch (e) {
      debugPrint('Error updating tasks widget: $e');
      return false;
    }
  }

  /// Update the challenges widget data
  Future<bool> updateChallengesWidget(List<Challenge> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Filter to only include active challenges and limit to 5
      final activeChallenges = challenges
          .where((challenge) => challenge.status != ChallengeStatus.completed &&
                               challenge.status != ChallengeStatus.rejected)
          .take(5)
          .toList();

      // Create a simplified list with just the data needed for the widget
      final widgetData = activeChallenges.map((challenge) => {
        'taskDescription': challenge.taskDescription,
        'fromUserName': 'From a friend', // We don't have fromUserName in the model
      }).toList();

      // Save to SharedPreferences
      final result = await prefs.setString(_challengesKey, jsonEncode(widgetData));

      debugPrint('Updated challenges widget data with ${widgetData.length} challenges');
      return result;
    } catch (e) {
      debugPrint('Error updating challenges widget: $e');
      return false;
    }
  }

  /// Update all widgets with the latest data
  Future<bool> updateAllWidgets({
    UserModel? user,
    List<Task>? tasks,
    List<Challenge>? challenges,
  }) async {
    try {
      bool success = true;

      if (user != null) {
        // Convert UserModel to Map before passing to updateUserStatsWidget
        final userStatsMap = {
          'auraPoints': user.auraPoints,
          'streakCount': user.streakCount,
          'completedTasks': user.completedTasks,
          'totalTasks': user.totalTasks,
        };
        final userResult = await updateUserStatsWidget(userStatsMap);
        success = success && userResult;
      }

      if (tasks != null) {
        final tasksResult = await updateTasksWidget(tasks);
        success = success && tasksResult;
      }

      if (challenges != null) {
        final challengesResult = await updateChallengesWidget(challenges);
        success = success && challengesResult;
      }

      return success;
    } catch (e) {
      debugPrint('Error updating all widgets: $e');
      return false;
    }
  }
}
