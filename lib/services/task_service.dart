import 'dart:async';
import 'dart:io';
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
import 'package:taskswap/services/gamification_service.dart';
import 'package:taskswap/services/widget_service.dart';
import 'package:taskswap/utils/error_handler.dart';
import 'package:taskswap/utils/input_validator.dart';
import 'package:taskswap/utils/transaction_manager.dart';
import 'package:taskswap/utils/offline_manager.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'tasks';
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final NotificationService _notificationService = NotificationService();
  final GamificationService _gamificationService = GamificationService();
  final WidgetService _widgetService = WidgetService();
  final ErrorHandler _errorHandler = ErrorHandler.instance;
  final TransactionManager _transactionManager = TransactionManager.instance;
  final OfflineManager _offlineManager = OfflineManager.instance;

  // Helper method to check if an error is network-related
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('socket') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('offline') ||
           error is SocketException ||
           error is TimeoutException;
  }

  // Get pending operations that need to be retried
  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    try {
      final data = await CacheService.getFromCache('pending_operations');
      if (data != null && data is List) {
        return List<Map<String, dynamic>>.from(data.map((item) =>
          item is Map<String, dynamic> ? item : <String, dynamic>{}
        ));
      }
      return [];
    } catch (e) {
      debugPrint('Error getting pending operations: $e');
      return [];
    }
  }

  // Save pending operations for later retry
  Future<void> _savePendingOperations(List<Map<String, dynamic>> operations) async {
    try {
      await CacheService.saveToCache(
        'pending_operations',
        operations,
        expiry: const Duration(days: 7), // Keep for a week
      );
    } catch (e) {
      debugPrint('Error saving pending operations: $e');
    }
  }

  // Save a task completion operation for later retry with improved error handling
  Future<bool> _savePendingTaskCompletion(String taskId) async {
    try {
      // Use the offline manager to queue the operation
      if (_offlineManager.isConnected) {
        // If we're online, don't queue the operation
        return false;
      }

      final pendingOperations = await _getPendingOperations();

      // Check if this task is already pending
      final alreadyPending = pendingOperations.any((op) =>
        op['type'] == 'mark_task_completed' && op['taskId'] == taskId);

      if (!alreadyPending) {
        pendingOperations.add({
          'type': 'mark_task_completed',
          'taskId': taskId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'retryCount': 0,
          'maxRetries': 5,
        });
        await _savePendingOperations(pendingOperations);
        debugPrint('Saved task completion for offline retry: $taskId');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error saving pending task completion: $e');
      final errorMessage = _errorHandler.handleError(e, fallbackMessage: 'Failed to save task for offline completion.');
      debugPrint(errorMessage);
      return false;
    }
  }

  // Process any pending operations with improved error handling
  // Call this when the app starts or regains connectivity
  Future<Map<String, dynamic>> processPendingOperations() async {
    try {
      // Use the offline manager to process pending operations
      if (_offlineManager.isConnected) {
        final operations = await _getPendingOperations();
        if (operations.isEmpty) {
          return {
            'success': true,
            'message': 'No pending operations',
            'processed': 0,
            'failed': 0,
            'remaining': 0,
          };
        }

        debugPrint('Processing ${operations.length} pending operations');

        final successfulOps = <Map<String, dynamic>>[];
        final failedOps = <Map<String, dynamic>>[];
        final remainingOps = <Map<String, dynamic>>[];

        // Sort operations by timestamp (oldest first)
        operations.sort((a, b) {
          final aTimestamp = a['timestamp'] as int? ?? 0;
          final bTimestamp = b['timestamp'] as int? ?? 0;
          return aTimestamp.compareTo(bTimestamp);
        });

        for (final op in operations) {
          final type = op['type'] as String?;
          final timestamp = op['timestamp'] as int? ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          final age = now - timestamp;

          // Skip operations that are too old (more than 3 days)
          if (age > const Duration(days: 3).inMilliseconds) {
            debugPrint('Skipping operation that is too old: ${op['type']} (${age ~/ 86400000} days old)');
            successfulOps.add(op); // Mark as "successful" to remove it
            continue;
          }

          if (type == 'mark_task_completed') {
            final taskId = op['taskId'] as String?;
            if (taskId != null) {
              try {
                // Check if this operation was already completed
                if (_transactionManager.wasRecentlyCompleted(
                  'mark_task_completed',
                  taskId,
                  window: const Duration(minutes: 30),
                )) {
                  debugPrint('Skipping already completed operation: mark_task_completed for $taskId');
                  successfulOps.add(op);
                  continue;
                }

                // Try to execute the operation
                final result = await markTaskAsCompleted(taskId);
                if (result['error'] == null || result['isDuplicate'] == true) {
                  successfulOps.add(op);
                  debugPrint('Successfully processed offline operation: mark_task_completed for $taskId');
                } else {
                  // If it's a network error, keep for retry
                  if (_isNetworkError(result['error'])) {
                    remainingOps.add(op);
                    debugPrint('Network error processing operation, will retry: mark_task_completed for $taskId');
                  } else {
                    // Other errors, mark as failed
                    failedOps.add(op);
                    debugPrint('Failed to process operation: mark_task_completed for $taskId - ${result['error']}');
                  }
                }
              } catch (e) {
                // If it's a network error, keep for retry
                if (_isNetworkError(e)) {
                  remainingOps.add(op);
                  debugPrint('Network error processing operation, will retry: mark_task_completed for $taskId');
                } else {
                  // Other errors, mark as failed
                  failedOps.add(op);
                  debugPrint('Error processing operation: mark_task_completed for $taskId - $e');
                }
              }
            }
          } else if (type == 'create_task') {
            // Handle create_task operations if needed
            // This is a placeholder for future implementation
            debugPrint('Unsupported operation type: $type');
            failedOps.add(op);
          } else if (type == 'update_task') {
            // Handle update_task operations if needed
            // This is a placeholder for future implementation
            debugPrint('Unsupported operation type: $type');
            failedOps.add(op);
          } else if (type == 'delete_task') {
            // Handle delete_task operations if needed
            // This is a placeholder for future implementation
            debugPrint('Unsupported operation type: $type');
            failedOps.add(op);
          } else {
            // Unknown operation type
            debugPrint('Unknown operation type: $type');
            failedOps.add(op);
          }
        }

        // Save the remaining operations
        await _savePendingOperations(remainingOps);

        debugPrint('Processed ${successfulOps.length} operations, ${failedOps.length} failed, ${remainingOps.length} remaining');

        return {
          'success': true,
          'message': 'Processed ${successfulOps.length} operations',
          'processed': successfulOps.length,
          'failed': failedOps.length,
          'remaining': remainingOps.length,
        };
      } else {
        // Device is offline, can't process operations
        return {
          'success': false,
          'message': 'Device is offline',
          'processed': 0,
          'failed': 0,
          'remaining': 0,
        };
      }
    } catch (e) {
      debugPrint('Error processing pending operations: $e');
      final errorMessage = _errorHandler.handleError(e, fallbackMessage: 'Failed to process pending operations.');
      return {
        'success': false,
        'message': errorMessage,
        'processed': 0,
        'failed': 0,
        'remaining': 0,
      };
    }
  }

  // Create a new task with improved error handling and duplicate submission prevention
  Future<String?> createTask(Task task) async {
    try {
      // Validate task data
      final titleValidation = InputValidator.validateTaskTitle(task.title);
      if (titleValidation != null) {
        throw ArgumentError(titleValidation);
      }

      final descriptionValidation = InputValidator.validateTaskDescription(task.description);
      if (descriptionValidation != null) {
        throw ArgumentError(descriptionValidation);
      }

      // Check for duplicate submission
      if (_transactionManager.wasRecentlyCompleted(
        'create_task',
        task.title + task.createdBy,
        window: const Duration(seconds: 10),
      )) {
        debugPrint('Duplicate task creation detected: ${task.title}');
        return null;
      }

      // Execute the transaction
      return await _transactionManager.executeTransaction(
        operationType: 'create_task',
        entityId: task.title + task.createdBy,
        operation: () async {
          // Add the task to Firestore
          DocumentReference docRef = await _firestore.collection(_collectionPath).add(task.toMap());

          // Get the task ID
          final taskId = docRef.id;

          // Increment the user's total tasks count
          await _userService.incrementTotalTasks(task.createdBy);

          // Schedule a reminder if the task has a due date
          await _scheduleTaskReminder(taskId, task);

          // Log analytics event
          await AnalyticsService.instance.logTaskCreated(
            taskId: taskId,
            taskTitle: task.title,
            isChallenge: task.isChallenge,
            category: task.category.toString().split('.').last,
          );

          // If this is a challenge task, create an activity
          if (task.isChallenge) {
            // Create a task completed activity instead since there's no specific challenge created activity
            await _activityService.createTaskCompletedActivity(
              userId: task.createdBy,
              taskTitle: task.title,
              points: task.points,
              taskId: taskId,
            );
          }

          return taskId;
        },
      );
    } catch (e) {
      debugPrint('Error creating task: $e');
      final errorMessage = _errorHandler.handleError(e, fallbackMessage: 'Failed to create task. Please try again.');
      throw Exception(errorMessage);
    }
  }

  // Schedule a reminder for a task
  Future<void> _scheduleTaskReminder(String taskId, Task task) async {
    try {
      // Only schedule if the task has a due date and is not completed
      if (task.dueDate != null && !task.isCompleted) {
        // Get user's notification settings
        final userDoc = await _firestore.collection('users').doc(task.createdBy).get();
        if (!userDoc.exists) return;

        final userData = userDoc.data() as Map<String, dynamic>;
        final notificationSettings = userData['notificationSettings'] as Map<String, dynamic>? ?? {};

        // Check if task reminders are enabled
        final taskReminderEnabled = notificationSettings['taskReminderEnabled'] ?? true;
        final pushEnabled = notificationSettings['pushEnabled'] ?? true;

        if (taskReminderEnabled && pushEnabled) {
          // Get reminder minutes before from settings
          final reminderMinutesBefore = notificationSettings['reminderMinutesBefore'] ?? 60;

          // Schedule the reminder
          await _notificationService.scheduleTaskReminder(
            taskId: taskId,
            taskTitle: task.title,
            dueDate: task.dueDate!,
            reminderMinutesBefore: reminderMinutesBefore,
          );

          debugPrint('Scheduled reminder for task: ${task.title}');
        }
      }
    } catch (e) {
      debugPrint('Error scheduling task reminder: $e');
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

            // Add gentle haptic feedback when tasks are updated
            if (hasChanges) {
              // Use the lightest possible feedback
              HapticFeedback.selectionClick();

              // Update widget data
              _widgetService.updateTasksWidget(tasks);
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

  // Update an existing task with improved error handling and duplicate submission prevention
  Future<bool> updateTask(String taskId, Task task) async {
    try {
      // Validate task data
      final titleValidation = InputValidator.validateTaskTitle(task.title);
      if (titleValidation != null) {
        throw ArgumentError(titleValidation);
      }

      final descriptionValidation = InputValidator.validateTaskDescription(task.description);
      if (descriptionValidation != null) {
        throw ArgumentError(descriptionValidation);
      }

      // Check for duplicate submission
      if (_transactionManager.wasRecentlyCompleted(
        'update_task',
        taskId,
        window: const Duration(seconds: 5),
      )) {
        debugPrint('Duplicate task update detected: $taskId');
        return false;
      }

      // Execute the transaction
      return await _transactionManager.executeTransaction(
        operationType: 'update_task',
        entityId: taskId,
        operation: () async {
          // Get the current task to check if due date changed or task was completed
          final currentTaskDoc = await _firestore.collection(_collectionPath).doc(taskId).get();
          final Task? currentTask = currentTaskDoc.exists ? Task.fromFirestore(currentTaskDoc) : null;

          // Update the task in Firestore
          await _firestore.collection(_collectionPath).doc(taskId).update(task.toMap());

          // Clear the cache for this task
          await CacheService.clearCache('task_$taskId');

          // Handle task reminder updates
          if (currentTask != null) {
            // If task was completed, cancel any existing reminder
            if (task.isCompleted && !currentTask.isCompleted) {
              await _notificationService.cancelTaskReminder(taskId);
              debugPrint('Cancelled reminder for completed task: ${task.title}');

              // If this is a challenge task and it was just completed, award points
              if (task.isChallenge) {
                await _gamificationService.awardTaskCompletionPoints(
                  userId: task.createdBy,
                  taskId: taskId,
                  taskTitle: task.title,
                  isChallenge: true,
                  taskPoints: task.points,
                );

                // Create activity for task completion
                await _activityService.createTaskCompletedActivity(
                  userId: task.createdBy,
                  taskTitle: task.title,
                  points: task.points,
                  taskId: taskId,
                );
              }
            }
            // If due date changed or task was uncompleted, update the reminder
            else if ((task.dueDate != currentTask.dueDate) ||
                    (!task.isCompleted && currentTask.isCompleted)) {
              // Cancel any existing reminder
              await _notificationService.cancelTaskReminder(taskId);

              // Schedule a new reminder if needed
              await _scheduleTaskReminder(taskId, task);
            }
          } else {
            // If we couldn't get the current task, just try to schedule a reminder
            await _scheduleTaskReminder(taskId, task);
          }

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

          return true;
        },
      ) ?? false;
    } catch (e) {
      debugPrint('Error updating task: $e');
      final errorMessage = _errorHandler.handleError(e, fallbackMessage: 'Failed to update task. Please try again.');
      throw Exception(errorMessage);
    }
  }

  // Delete a task with improved error handling and duplicate submission prevention
  Future<bool> deleteTask(String taskId) async {
    try {
      // Check for duplicate submission
      if (_transactionManager.wasRecentlyCompleted(
        'delete_task',
        taskId,
        window: const Duration(seconds: 5),
      )) {
        debugPrint('Duplicate task deletion detected: $taskId');
        return false;
      }

      // Execute the transaction
      return await _transactionManager.executeTransaction(
        operationType: 'delete_task',
        entityId: taskId,
        operation: () async {
          // Get the task before deleting it for analytics
          final task = await getTaskById(taskId);

          // Delete from Firestore
          await _firestore.collection(_collectionPath).doc(taskId).delete();

          // Clear the cache for this task
          await CacheService.clearCache('task_$taskId');

          // Cancel any scheduled reminders for this task
          await _notificationService.cancelTaskReminder(taskId);

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

          return true;
        },
      ) ?? false;
    } catch (e) {
      debugPrint('Error deleting task: $e');
      final errorMessage = _errorHandler.handleError(e, fallbackMessage: 'Failed to delete task. Please try again.');
      throw Exception(errorMessage);
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

  // Get upcoming tasks for widgets
  Future<List<Task>> getUpcomingTasks(String userId, {int limit = 5}) async {
    try {
      final now = DateTime.now();

      // Get tasks that are not completed and have a due date in the future
      final tasksSnapshot = await _firestore
          .collection(_collectionPath)
          .where('createdBy', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('dueDate', descending: false)
          .limit(limit)
          .get();

      return tasksSnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting upcoming tasks: $e');
      return [];
    }
  }

  // Get active challenges for widgets
  Future<List<Task>> getActiveChallenges(String userId) async {
    try {
      // Get challenge tasks that are not completed
      final tasksSnapshot = await _firestore
          .collection(_collectionPath)
          .where('createdBy', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .where('isChallenge', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return tasksSnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting active challenges: $e');
      return [];
    }
  }

  // Get completed tasks count for widgets
  Future<int> getCompletedTasksCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['completedTasks'] ?? 0;
    } catch (e) {
      debugPrint('Error getting completed tasks count: $e');
      return 0;
    }
  }

  // Get total tasks count for widgets
  Future<int> getTotalTasksCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['totalTasks'] ?? 0;
    } catch (e) {
      debugPrint('Error getting total tasks count: $e');
      return 0;
    }
  }

  // Get task category statistics for a user
  Future<Map<TaskCategory, int>> getTaskCategoryStats(String userId) async {
    try {
      // Check cache first
      final cacheKey = 'user_category_stats_$userId';
      final cachedData = await CacheService.getFromCache(cacheKey);

      if (cachedData != null) {
        debugPrint('Retrieved category stats from cache for $userId');
        Map<TaskCategory, int> result = {};
        cachedData.forEach((key, value) {
          result[TaskCategoryHelper.fromString(key)] = value as int;
        });
        return result;
      }

      // If not in cache, calculate from tasks
      final tasksSnapshot = await _firestore
          .collection(_collectionPath)
          .where('createdBy', isEqualTo: userId)
          .get();

      Map<TaskCategory, int> categoryStats = {};

      // Initialize all categories with 0
      for (var category in TaskCategory.values) {
        categoryStats[category] = 0;
      }

      // Count tasks by category
      for (var doc in tasksSnapshot.docs) {
        final task = Task.fromFirestore(doc);
        categoryStats[task.category] = (categoryStats[task.category] ?? 0) + 1;
      }

      // Save to cache for 10 minutes
      Map<String, int> cacheData = {};
      categoryStats.forEach((key, value) {
        cacheData[key.toString().split('.').last] = value;
      });

      await CacheService.saveToCache(
        cacheKey,
        cacheData,
        expiry: const Duration(minutes: 10)
      );

      return categoryStats;
    } catch (e) {
      debugPrint('Error getting category stats: $e');
      // Return empty map with all categories initialized to 0
      Map<TaskCategory, int> emptyStats = {};
      for (var category in TaskCategory.values) {
        emptyStats[category] = 0;
      }
      return emptyStats;
    }
  }

  // Mark a task as completed with improved error handling and duplicate submission prevention
  // Returns a map with reward details if successful
  Future<Map<String, dynamic>> markTaskAsCompleted(String taskId) async {
    try {
      // Check for duplicate submission
      if (_transactionManager.wasRecentlyCompleted(
        'mark_task_completed',
        taskId,
        window: const Duration(seconds: 10),
      )) {
        debugPrint('Duplicate task completion detected: $taskId');
        return {
          'pointsEarned': 0,
          'bonusPoints': 0,
          'taskTitle': 'Task',
          'taskDescription': '',
          'error': 'This task was already marked as completed.',
          'isDuplicate': true,
        };
      }

      // Check if we have a pending operation for this task
      final pendingOperations = await _getPendingOperations();
      final isPending = pendingOperations.any((op) =>
        op['type'] == 'mark_task_completed' && op['taskId'] == taskId);

      if (isPending) {
        debugPrint('Task $taskId is already pending completion');
      }

      // Execute the transaction
      return await _transactionManager.executeTransaction(
        operationType: 'mark_task_completed',
        entityId: taskId,
        operation: () async {
          // Use a lock to prevent concurrent calls for the same task
          final taskRef = _firestore.collection(_collectionPath).doc(taskId);
          String? userId; // Declare userId at this scope so it's available after the transaction

          // First, check if the task exists and get its data
          DocumentSnapshot taskDoc;
          try {
            taskDoc = await taskRef.get();
          } catch (e) {
            debugPrint('Error fetching task: $e');

            // Save for offline retry if it's a network error
            if (_isNetworkError(e)) {
              await _savePendingTaskCompletion(taskId);
            }

            return {
              'pointsEarned': 0,
              'bonusPoints': 0,
              'taskTitle': 'Task',
              'taskDescription': '',
              'error': e.toString(),
              'pendingSave': _isNetworkError(e),
            };
          }

          if (!taskDoc.exists) {
            debugPrint('Task not found: $taskId');
            return {
              'pointsEarned': 0,
              'bonusPoints': 0,
              'taskTitle': 'Task',
              'taskDescription': '',
              'error': 'Task not found',
            };
          }

          Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;

          // Check if task is already completed
          if (taskData['isCompleted'] == true) {
            // Task already completed, return early with empty reward details
            return {
              'pointsEarned': 0,
              'bonusPoints': 0,
              'taskTitle': taskData['title'] ?? 'Task',
              'taskDescription': taskData['description'] ?? '',
              'isChallenge': taskData['isChallenge'] ?? false,
              'showAuraMessage': false,
            };
          }

          // Get task points and user ID
          int taskPoints = taskData['points'] ?? 10; // Default to 10 if not specified
          userId = taskData['createdBy']; // Assign to the outer scope variable

          // Use a transaction for the update operation
          await _firestore.runTransaction((transaction) async {
            // Get a reference to the user document
            final userRef = _firestore.collection('users').doc(userId);

            // IMPORTANT: Perform ALL reads before ANY writes
            // Get the current user data
            DocumentSnapshot userDoc = await transaction.get(userRef);

            // Check if this is a challenge task (which should award points)
            bool isChallengeTask = taskData['isChallenge'] == true;

            // Now perform all writes
            // Mark task as completed
            transaction.update(taskRef, {
              'isCompleted': true,
            });

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
            } else {
              // Get current aura points and completed tasks count
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
              int completedTasks = userData['completedTasks'] ?? 0;

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
            }
          });

          // Get the task details for the activity record
          final task = await getTaskById(taskId);

          // Provide gentle haptic feedback for task completion
          HapticFeedback.selectionClick();

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

            // Create a task completed notification
            await _notificationService.createTaskCompletedNotification(
              userId: userId ?? task.createdBy,
              taskTitle: task.title,
              isChallenge: task.isChallenge,
              points: task.isChallenge ? task.points : 0,
              taskId: taskId,
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
            // If this is a challenge task, use the gamification service to award points
            if (isChallengeTask && task != null) {
              await _gamificationService.awardTaskCompletionPoints(
                userId: userId,
                taskId: taskId,
                taskTitle: task.title,
                isChallenge: true,
                taskPoints: task.points,
              );
            } else {
              // For regular tasks, just update the streak
              final streakMilestone = await _userService.updateUserStreak(userId);

              // If a streak milestone was reached, add it to the reward details
              if (streakMilestone != null) {
                rewardDetails['streakMilestone'] = streakMilestone;
                rewardDetails['bonusPoints'] += streakMilestone['bonusPoints'] as int;
              }
            }

            // Create an activity record for the completed task
            if (task != null) {
              // We know userId is not null at this point
              await _activityService.createTaskCompletedActivity(
                userId: userId, // userId is guaranteed to be non-null here
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
                    userId: userId, // userId is guaranteed to be non-null here
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
                    userId: userId, // userId is guaranteed to be non-null here
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
                    userId: userId, // userId is guaranteed to be non-null here
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
                    userId: userId, // userId is guaranteed to be non-null here
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
                    userId: userId, // userId is guaranteed to be non-null here
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
        },
      ) ?? {
        'pointsEarned': 0,
        'bonusPoints': 0,
        'taskTitle': 'Task',
        'taskDescription': '',
        'error': 'Failed to complete task. Please try again.',
      };
    } catch (e) {
      debugPrint('Error marking task as completed: $e');
      // Return empty reward details in case of error
      final errorMessage = _errorHandler.handleError(e, fallbackMessage: 'Failed to complete task. Please try again.');
      return {
        'pointsEarned': 0,
        'bonusPoints': 0,
        'taskTitle': 'Task',
        'taskDescription': '',
        'error': errorMessage,
      };
    }
  }
}
