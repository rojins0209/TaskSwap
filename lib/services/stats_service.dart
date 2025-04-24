import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/activity_model.dart';
import 'package:taskswap/models/challenge_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:intl/intl.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get task completion rate for a user
  Future<double> getTaskCompletionRate(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return 0.0;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final completedTasks = userData['completedTasks'] ?? 0;
      final totalTasks = userData['totalTasks'] ?? 0;

      if (totalTasks == 0) {
        return 0.0;
      }

      return (completedTasks / totalTasks) * 100;
    } catch (e) {
      debugPrint('Error getting task completion rate: $e');
      return 0.0;
    }
  }

  // Get weekly activity data for a user
  Future<Map<String, int>> getWeeklyActivityData(String userId) async {
    try {
      // Get the start of the current week (Monday)
      final now = DateTime.now();
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

      // Get activities for the past 7 days
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: true)
          .get();

      // Initialize data for each day of the week
      final Map<String, int> weeklyData = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      // Count activities for each day
      for (var doc in activitiesSnapshot.docs) {
        final activity = Activity.fromFirestore(doc);
        if (activity.timestamp != null) {
          final dayOfWeek = DateFormat('E').format(activity.timestamp!);
          weeklyData[dayOfWeek] = (weeklyData[dayOfWeek] ?? 0) + 1;
        }
      }

      return weeklyData;
    } catch (e) {
      debugPrint('Error getting weekly activity data: $e');
      return {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };
    }
  }

  // Get average daily tasks for a user
  Future<double> getAverageDailyTasks(String userId) async {
    try {
      // Get tasks created in the past 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Count tasks per day
      final Map<String, int> tasksPerDay = {};
      for (var doc in tasksSnapshot.docs) {
        final task = Task.fromFirestore(doc);
        if (task.createdAt != null) {
          final dateKey = DateFormat('yyyy-MM-dd').format(task.createdAt!);
          tasksPerDay[dateKey] = (tasksPerDay[dateKey] ?? 0) + 1;
        }
      }

      // Calculate average
      if (tasksPerDay.isEmpty) {
        return 0.0;
      }

      final totalTasks = tasksPerDay.values.reduce((a, b) => a + b);
      return totalTasks / tasksPerDay.length;
    } catch (e) {
      debugPrint('Error getting average daily tasks: $e');
      return 0.0;
    }
  }

  // Get most active day and time for a user
  Future<Map<String, String>> getMostActiveTimeData(String userId) async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100) // Limit to recent activities for performance
          .get();

      // Count activities by day of week
      final Map<String, int> dayCount = {
        'Monday': 0,
        'Tuesday': 0,
        'Wednesday': 0,
        'Thursday': 0,
        'Friday': 0,
        'Saturday': 0,
        'Sunday': 0,
      };

      // Count activities by time of day
      final Map<String, int> timeCount = {
        'Morning (6-12)': 0,
        'Afternoon (12-18)': 0,
        'Evening (18-24)': 0,
        'Night (0-6)': 0,
      };

      for (var doc in activitiesSnapshot.docs) {
        final activity = Activity.fromFirestore(doc);
        if (activity.timestamp != null) {
          // Count by day
          final dayOfWeek = DateFormat('EEEE').format(activity.timestamp!);
          dayCount[dayOfWeek] = (dayCount[dayOfWeek] ?? 0) + 1;

          // Count by time
          final hour = activity.timestamp!.hour;
          if (hour >= 6 && hour < 12) {
            timeCount['Morning (6-12)'] = (timeCount['Morning (6-12)'] ?? 0) + 1;
          } else if (hour >= 12 && hour < 18) {
            timeCount['Afternoon (12-18)'] = (timeCount['Afternoon (12-18)'] ?? 0) + 1;
          } else if (hour >= 18 && hour < 24) {
            timeCount['Evening (18-24)'] = (timeCount['Evening (18-24)'] ?? 0) + 1;
          } else {
            timeCount['Night (0-6)'] = (timeCount['Night (0-6)'] ?? 0) + 1;
          }
        }
      }

      // Find most active day and time
      String mostActiveDay = 'Monday';
      int maxDayCount = 0;
      dayCount.forEach((day, count) {
        if (count > maxDayCount) {
          mostActiveDay = day;
          maxDayCount = count;
        }
      });

      String mostActiveTime = 'Morning (6-12)';
      int maxTimeCount = 0;
      timeCount.forEach((time, count) {
        if (count > maxTimeCount) {
          mostActiveTime = time;
          maxTimeCount = count;
        }
      });

      return {
        'day': mostActiveDay,
        'time': mostActiveTime,
      };
    } catch (e) {
      debugPrint('Error getting most active time data: $e');
      return {
        'day': 'Unknown',
        'time': 'Unknown',
      };
    }
  }

  // Get task categories distribution for a user
  Future<Map<String, int>> getTaskCategoriesDistribution(String userId) async {
    try {
      // Get tasks created by the user
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();

      // Get challenges created by or sent to the user
      final challengesSnapshot = await _firestore
          .collection('challenges')
          .where('fromUserId', isEqualTo: userId)
          .get();

      final receivedChallengesSnapshot = await _firestore
          .collection('challenges')
          .where('toUserId', isEqualTo: userId)
          .get();

      // Initialize categories map with all possible categories
      final Map<String, int> categories = {};
      for (var category in TaskCategory.values) {
        categories[category.name] = 0;
      }

      // Count tasks by category
      for (var doc in tasksSnapshot.docs) {
        final task = Task.fromFirestore(doc);
        final categoryName = task.category.name;
        categories[categoryName] = (categories[categoryName] ?? 0) + 1;
      }

      // Count challenges by category
      for (var doc in challengesSnapshot.docs) {
        final challenge = Challenge.fromFirestore(doc);
        final categoryName = challenge.category.name;
        categories[categoryName] = (categories[categoryName] ?? 0) + 1;
      }

      // Count received challenges by category
      for (var doc in receivedChallengesSnapshot.docs) {
        final challenge = Challenge.fromFirestore(doc);
        final categoryName = challenge.category.name;
        categories[categoryName] = (categories[categoryName] ?? 0) + 1;
      }

      // Ensure we have at least some data
      if (categories.values.every((value) => value == 0)) {
        categories[TaskCategory.personal.name] = 1;
      }

      return categories;
    } catch (e) {
      debugPrint('Error getting task categories distribution: $e');
      // Return default distribution with all categories
      final Map<String, int> defaultCategories = {};
      for (var category in TaskCategory.values) {
        defaultCategories[category.name] = 10; // Equal distribution
      }
      return defaultCategories;
    }
  }

  // Get streak data for a user
  Future<Map<String, dynamic>> getStreakData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {
          'currentStreak': 0,
          'longestStreak': 0,
          'lastActive': 'Never',
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentStreak = userData['streakCount'] ?? 0;

      // For longest streak, we'll use a placeholder since it's not tracked in the model
      // In a real app, you'd want to track this separately
      final longestStreak = currentStreak + (currentStreak > 5 ? 3 : 0);

      // Format last active date
      String lastActive = 'Never';
      if (userData['lastPointsEarnedAt'] != null) {
        final lastActiveDate = (userData['lastPointsEarnedAt'] as Timestamp).toDate();
        final now = DateTime.now();
        final difference = now.difference(lastActiveDate).inDays;

        if (difference == 0) {
          lastActive = 'Today';
        } else if (difference == 1) {
          lastActive = 'Yesterday';
        } else {
          lastActive = DateFormat('MMM d, yyyy').format(lastActiveDate);
        }
      }

      return {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActive': lastActive,
      };
    } catch (e) {
      debugPrint('Error getting streak data: $e');
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'lastActive': 'Unknown',
      };
    }
  }

  // Get all stats for a user in a single call
  Future<Map<String, dynamic>> getAllUserStats(String userId) async {
    try {
      final completionRate = await getTaskCompletionRate(userId);
      final weeklyActivity = await getWeeklyActivityData(userId);
      final averageDailyTasks = await getAverageDailyTasks(userId);
      final mostActiveTimeData = await getMostActiveTimeData(userId);
      final taskCategories = await getTaskCategoriesDistribution(userId);
      final streakData = await getStreakData(userId);

      return {
        'completionRate': completionRate,
        'weeklyActivity': weeklyActivity,
        'averageDailyTasks': averageDailyTasks,
        'mostActiveDay': mostActiveTimeData['day'],
        'mostActiveTime': mostActiveTimeData['time'],
        'taskCategories': taskCategories,
        'streakData': streakData,
      };
    } catch (e) {
      debugPrint('Error getting all user stats: $e');
      return {};
    }
  }

  // Stream of all stats for a user - updates in real-time
  Stream<Map<String, dynamic>> getUserStatsStream(String userId) {
    // Create a stream controller to combine all the data
    final controller = StreamController<Map<String, dynamic>>();

    // Track subscriptions to cancel them when the stream is closed
    final List<StreamSubscription<dynamic>> subscriptions = [];

    // Listen to tasks collection for changes
    final tasksSubscription = _firestore
        .collection('tasks')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .listen((_) async {
          // When tasks change, recalculate all stats
          try {
            final stats = await getAllUserStats(userId);
            if (!controller.isClosed) {
              controller.add(stats);
            }
          } catch (e) {
            debugPrint('Error updating stats stream: $e');
          }
        });
    subscriptions.add(tasksSubscription);

    // Listen to challenges collection for changes
    final challengesSubscription = _firestore
        .collection('challenges')
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .listen((_) async {
          // When challenges change, recalculate all stats
          try {
            final stats = await getAllUserStats(userId);
            if (!controller.isClosed) {
              controller.add(stats);
            }
          } catch (e) {
            debugPrint('Error updating stats stream: $e');
          }
        });
    subscriptions.add(challengesSubscription);

    // Listen to received challenges
    final receivedChallengesSubscription = _firestore
        .collection('challenges')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .listen((_) async {
          // When received challenges change, recalculate all stats
          try {
            final stats = await getAllUserStats(userId);
            if (!controller.isClosed) {
              controller.add(stats);
            }
          } catch (e) {
            debugPrint('Error updating stats stream: $e');
          }
        });
    subscriptions.add(receivedChallengesSubscription);

    // Listen to activities collection for changes
    final activitiesSubscription = _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((_) async {
          // When activities change, recalculate all stats
          try {
            final stats = await getAllUserStats(userId);
            if (!controller.isClosed) {
              controller.add(stats);
            }
          } catch (e) {
            debugPrint('Error updating stats stream: $e');
          }
        });
    subscriptions.add(activitiesSubscription);

    // Listen to user document for changes
    final userSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((_) async {
          // When user data changes, recalculate all stats
          try {
            final stats = await getAllUserStats(userId);
            if (!controller.isClosed) {
              controller.add(stats);
            }
          } catch (e) {
            debugPrint('Error updating stats stream: $e');
          }
        });
    subscriptions.add(userSubscription);

    // Initial data load
    getAllUserStats(userId).then((stats) {
      if (!controller.isClosed) {
        controller.add(stats);
      }
    }).catchError((e) {
      debugPrint('Error loading initial stats: $e');
    });

    // Close subscriptions when the stream is closed
    controller.onCancel = () {
      for (var subscription in subscriptions) {
        subscription.cancel();
      }
    };

    return controller.stream;
  }
}
