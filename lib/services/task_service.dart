import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/services/activity_service.dart';
import 'package:taskswap/services/notification_service.dart';
import 'package:taskswap/services/cache_service.dart';
import 'package:taskswap/services/analytics_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'tasks';
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final NotificationService _notificationService = NotificationService();

  // Create a new task
  Future<String> createTask(Task task) async {
    try {
      // Add the task to Firestore
      DocumentReference docRef = await _firestore.collection(_collectionPath).add(task.toMap());

      // Increment the user's total tasks count
      await _userService.incrementTotalTasks(task.createdBy);

      // Log analytics event
      await AnalyticsService.instance.logTaskCreated(
        taskId: docRef.id,
        taskTitle: task.title,
        isChallenge: task.isChallenge,
        category: task.category.toString().split('.').last,
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  // Get all tasks for a specific user with optimized performance
  Stream<List<Task>> getUserTasks(String userId) {
    // Use a cache reference to avoid unnecessary rebuilds
    List<Task> cachedTasks = [];
    DateTime lastFetchTime = DateTime.now();
    bool isFetching = false;

    return _firestore
        .collection(_collectionPath)
        .where('createdBy', isEqualTo: userId)
        // Add a limit to improve initial load time
        .limit(100)
        .snapshots()
        .map((snapshot) {
          // If we're already processing a fetch, return the cached data
          if (isFetching) {
            return cachedTasks;
          }

          isFetching = true;

          try {
            // Check if the snapshot has changes
            final now = DateTime.now();
            final hasChanges = snapshot.docChanges.isNotEmpty;
            final timeSinceLastFetch = now.difference(lastFetchTime);

            // If no changes and less than 5 seconds since last fetch, return cached data
            if (!hasChanges && timeSinceLastFetch.inSeconds < 5 && cachedTasks.isNotEmpty) {
              return cachedTasks;
            }

            // Process the snapshot
            var tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

            // Sort tasks by createdAt locally instead of in the query
            tasks.sort((a, b) {
              if (a.createdAt == null) return 1;
              if (b.createdAt == null) return -1;
              return b.createdAt!.compareTo(a.createdAt!);
            });

            // Update cache and timestamp
            cachedTasks = tasks;
            lastFetchTime = now;

            // Add haptic feedback when tasks are updated
            if (hasChanges) {
              HapticFeedback.selectionClick();
            }

            return tasks;
          } finally {
            isFetching = false;
          }
        });
  }

  // Get a specific task by ID with caching
  Future<Task?> getTaskById(String taskId) async {
    try {
      // Check cache first
      final cacheKey = 'task_$taskId';
      final cachedData = await CacheService.getFromCache(cacheKey);

      if (cachedData != null) {
        debugPrint('Retrieved task $taskId from cache');
        return Task(
          id: taskId,
          title: cachedData['title'] ?? '',
          description: cachedData['description'] ?? '',
          createdBy: cachedData['createdBy'] ?? '',
          isCompleted: cachedData['isCompleted'] ?? false,
          points: cachedData['points'] ?? 0,
          category: TaskCategoryHelper.fromString(cachedData['category']),
          isChallenge: cachedData['isChallenge'] ?? false,
          // Handle dates
          dueDate: cachedData['dueDate'] != null ?
            DateTime.fromMillisecondsSinceEpoch(cachedData['dueDate']) : null,
          createdAt: cachedData['createdAt'] != null ?
            DateTime.fromMillisecondsSinceEpoch(cachedData['createdAt']) : null,
        );
      }

      // If not in cache, get from Firestore
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(taskId).get();
      if (doc.exists) {
        final task = Task.fromFirestore(doc);

        // Save to cache for 30 minutes
        await CacheService.saveToCache(
          cacheKey,
          {
            'title': task.title,
            'description': task.description,
            'createdBy': task.createdBy,
            'isCompleted': task.isCompleted,
            'points': task.points,
            'category': task.category.toString().split('.').last,
            'isChallenge': task.isChallenge,
            'dueDate': task.dueDate?.millisecondsSinceEpoch,
            'createdAt': task.createdAt?.millisecondsSinceEpoch,
          },
          expiry: const Duration(minutes: 30)
        );

        return task;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting task: $e');
      rethrow;
    }
  }

  // Update an existing task
  Future<void> updateTask(String taskId, Task task) async {
    try {
      await _firestore.collection(_collectionPath).doc(taskId).update(task.toMap());

      // Clear the cache for this task
      await CacheService.clearCache('task_$taskId');

      // Log analytics event
      await AnalyticsService.instance.logEvent(
        name: 'task_updated',
        parameters: {
          'task_id': taskId,
          'task_title': task.title,
          'is_challenge': task.isChallenge,
          'category': task.category.toString().split('.').last,
        },
      );
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      // Get the task before deleting it for analytics
      final task = await getTaskById(taskId);

      // Delete from Firestore
      await _firestore.collection(_collectionPath).doc(taskId).delete();

      // Clear the cache for this task
      await CacheService.clearCache('task_$taskId');

      // Log analytics event
      if (task != null) {
        await AnalyticsService.instance.logEvent(
          name: 'task_deleted',
          parameters: {
            'task_id': taskId,
            'task_title': task.title,
            'is_challenge': task.isChallenge,
            'category': task.category.toString().split('.').last,
          },
        );
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // Get user task count statistics with caching
  Future<Map<String, dynamic>> getUserTaskCount(String userId) async {
    try {
      // Check cache first
      final cacheKey = 'user_task_count_$userId';
      final cachedData = await CacheService.getFromCache(cacheKey);

      if (cachedData != null) {
        debugPrint('Retrieved user task count from cache for $userId');
        return {
          'totalTasks': cachedData['totalTasks'] ?? 0,
          'completedTasks': cachedData['completedTasks'] ?? 0,
        };
      }

      // If not in cache, get from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'totalTasks': 0, 'completedTasks': 0};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final result = {
        'totalTasks': userData['totalTasks'] ?? 0,
        'completedTasks': userData['completedTasks'] ?? 0,
      };

      // Save to cache for 5 minutes
      await CacheService.saveToCache(
        cacheKey,
        result,
        expiry: const Duration(minutes: 5)
      );

      return result;
    } catch (e) {
      debugPrint('Error getting user task count: $e');
      return {'totalTasks': 0, 'completedTasks': 0};
    }
  }

  // Mark a task as completed
  // Returns a map with reward details if successful
  Future<Map<String, dynamic>> markTaskAsCompleted(String taskId) async {
    try {
      // Use a lock to prevent concurrent calls for the same task
      final taskRef = _firestore.collection(_collectionPath).doc(taskId);
      String? userId; // Declare userId at this scope so it's available after the transaction

      // Use a transaction for the entire operation
      await _firestore.runTransaction((transaction) async {
        // Get the task to check if it's already completed and get the points
        DocumentSnapshot taskDoc = await transaction.get(taskRef);

        if (!taskDoc.exists) {
          throw Exception('Task not found');
        }

        Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

        // Check if task is already completed
        if (taskData['isCompleted'] == true) {
          // Task already completed, no need to update
          // Return early from the transaction
          return;
        }

        // Get task points and user ID
        int taskPoints = taskData['points'] ?? 10; // Default to 10 if not specified
        userId = taskData['createdBy']; // Assign to the outer scope variable

        // Mark task as completed
        transaction.update(taskRef, {
          'isCompleted': true,
        });

        // Get a reference to the user document
        final userRef = _firestore.collection('users').doc(userId);

        // Get the current user data
        DocumentSnapshot userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          // If user doesn't exist, create it with initial values
          String email = '';
          try {
            final authUser = FirebaseAuth.instance.currentUser;
            if (authUser != null && authUser.uid == userId) {
              email = authUser.email ?? '';
            }
          } catch (authError) {
            debugPrint('Error getting user email: $authError');
          }

          // Create the user document with initial values
          transaction.set(userRef, {
            'email': email,
            'auraPoints': taskPoints, // Start with the points from this task
            'completedTasks': 1,      // This is the first completed task
            'totalTasks': 1,          // Assume this is also the first task
            'createdAt': FieldValue.serverTimestamp(),
            'lastPointsEarnedAt': FieldValue.serverTimestamp(), // Track when points were earned
            'friends': [],
            'friendRequests': [],
            'achievements': [],
          });

          // Since we've set the initial values, we can return early
          return;
        }

        // Get current aura points and completed tasks count
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        int completedTasks = userData['completedTasks'] ?? 0;

        // Check if this is a challenge task (which should award points)
        bool isChallengeTask = taskData['isChallenge'] == true;

        // Only award points for challenge tasks or milestone achievements
        // Regular tasks don't award points directly - they need to be recognized by friends
        if (isChallengeTask) {
          int currentPoints = userData['auraPoints'] ?? 0;
          transaction.update(userRef, {
            'auraPoints': currentPoints + taskPoints,
            'completedTasks': completedTasks + 1,
            'lastPointsEarnedAt': FieldValue.serverTimestamp(), // Update the timestamp when points were earned
          });
        } else {
          // For regular tasks, just increment the completed tasks count
          transaction.update(userRef, {
            'completedTasks': completedTasks + 1,
          });
        }
      });

      // Get the task details for the activity record
      final task = await getTaskById(taskId);

      // Provide haptic feedback for task completion
      HapticFeedback.mediumImpact();

      // Clear the cache for this task
      await CacheService.clearCache('task_$taskId');

      // Log analytics event
      if (task != null) {
        await AnalyticsService.instance.logTaskCompleted(
          taskId: taskId,
          taskTitle: task.title,
          isChallenge: task.isChallenge,
          category: task.category.toString().split('.').last,
        );
      }

      // Prepare reward details to return
      bool isChallengeTask = task?.isChallenge ?? false;

      Map<String, dynamic> rewardDetails = {
        'pointsEarned': isChallengeTask ? (task?.points ?? 0) : 0,
        'bonusPoints': 0,
        'taskTitle': task?.title ?? 'Task',
        'taskDescription': task?.description ?? '',
        'isChallenge': isChallengeTask,
        'showAuraMessage': !isChallengeTask,
      };

      // Update the user's streak after the transaction completes
      if (userId != null) {
        // Check for streak milestones
        final streakMilestone = await _userService.updateUserStreak(userId);

        // If a streak milestone was reached, add it to the reward details
        if (streakMilestone != null) {
          rewardDetails['streakMilestone'] = streakMilestone;
          rewardDetails['bonusPoints'] += streakMilestone['bonusPoints'] as int;
        }

        // Create an activity record for the completed task
        if (task != null) {
          // Use the null assertion operator (!) to tell Dart that userId is not null
          await _activityService.createTaskCompletedActivity(
            userId: userId!, // Using ! operator to assert userId is not null
            taskTitle: task.title,
            points: task.points,
            taskId: task.id ?? taskId,
          );

          // Get the user's completed tasks count
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final completedTasks = userData['completedTasks'] ?? 0;
            int taskMilestoneBonusPoints = 0;
            String? taskMilestoneName;

            // Check for task completion milestones
            if (completedTasks == 1) {
              // First task completed
              taskMilestoneName = 'First Task Completed';
              taskMilestoneBonusPoints = 5;

              await _notificationService.createMilestoneNotification(
                userId: userId!, // Using ! operator to assert userId is not null
                milestone: taskMilestoneName,
                points: taskMilestoneBonusPoints,
              );

              // Award bonus points
              await _firestore.collection('users').doc(userId).update({
                'auraPoints': FieldValue.increment(taskMilestoneBonusPoints),
              });
            } else if (completedTasks == 10) {
              // 10 tasks completed
              taskMilestoneName = '10 Tasks Completed';
              taskMilestoneBonusPoints = 10;

              await _notificationService.createMilestoneNotification(
                userId: userId!, // Using ! operator to assert userId is not null
                milestone: taskMilestoneName,
                points: taskMilestoneBonusPoints,
              );

              // Award bonus points
              await _firestore.collection('users').doc(userId).update({
                'auraPoints': FieldValue.increment(taskMilestoneBonusPoints),
              });
            } else if (completedTasks == 25) {
              // 25 tasks completed
              taskMilestoneName = '25 Tasks Completed';
              taskMilestoneBonusPoints = 25;

              await _notificationService.createMilestoneNotification(
                userId: userId!, // Using ! operator to assert userId is not null
                milestone: taskMilestoneName,
                points: taskMilestoneBonusPoints,
              );

              // Award bonus points
              await _firestore.collection('users').doc(userId).update({
                'auraPoints': FieldValue.increment(taskMilestoneBonusPoints),
              });
            } else if (completedTasks == 50) {
              // 50 tasks completed
              taskMilestoneName = '50 Tasks Completed';
              taskMilestoneBonusPoints = 50;

              await _notificationService.createMilestoneNotification(
                userId: userId!, // Using ! operator to assert userId is not null
                milestone: taskMilestoneName,
                points: taskMilestoneBonusPoints,
              );

              // Award bonus points
              await _firestore.collection('users').doc(userId).update({
                'auraPoints': FieldValue.increment(taskMilestoneBonusPoints),
              });
            } else if (completedTasks == 100) {
              // 100 tasks completed
              taskMilestoneName = '100 Tasks Completed';
              taskMilestoneBonusPoints = 100;

              await _notificationService.createMilestoneNotification(
                userId: userId!, // Using ! operator to assert userId is not null
                milestone: taskMilestoneName,
                points: taskMilestoneBonusPoints,
              );

              // Award bonus points
              await _firestore.collection('users').doc(userId).update({
                'auraPoints': FieldValue.increment(taskMilestoneBonusPoints),
              });
            }

            // If a task milestone was reached, add it to the reward details
            if (taskMilestoneName != null) {
              rewardDetails['taskMilestone'] = {
                'type': 'task',
                'name': taskMilestoneName,
                'bonusPoints': taskMilestoneBonusPoints,
                'completedTasks': completedTasks,
              };
              rewardDetails['bonusPoints'] += taskMilestoneBonusPoints;
            }
          }
        }
      }

      return rewardDetails;
    } catch (e) {
      debugPrint('Error marking task as completed: $e');
      // Return empty reward details in case of error
      return {
        'pointsEarned': 0,
        'bonusPoints': 0,
        'taskTitle': 'Task',
        'taskDescription': '',
        'error': e.toString(),
      };
    }
  }
}
