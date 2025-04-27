import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/services/notification_service.dart';
import 'package:taskswap/services/analytics_service.dart';

/// A utility class for handling edge cases in the app
class EdgeCaseHandler {
  // Singleton instance
  static final EdgeCaseHandler _instance = EdgeCaseHandler._internal();
  factory EdgeCaseHandler() => _instance;
  EdgeCaseHandler._internal();

  // Get the singleton instance
  static EdgeCaseHandler get instance => _instance;

  // Services
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Handle expired challenges
  /// This should be called periodically to check for challenges that have expired
  Future<void> handleExpiredChallenges(String userId) async {
    try {
      final now = DateTime.now();

      // Use a simpler query and filter in memory
      // First, get all incomplete challenge tasks for this user
      final challengesSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .get();

      // Filter in memory to find expired challenges
      final expiredChallenges = challengesSnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .where((task) =>
              task.isChallenge &&
              task.dueDate != null &&
              task.dueDate!.isBefore(now))
          .toList();

      if (expiredChallenges.isEmpty) {
        return;
      }

      debugPrint('Found ${expiredChallenges.length} expired challenges');

      // Process each expired challenge
      for (final task in expiredChallenges) {
        if (task.id == null) continue;

        // Mark the challenge as expired in Firestore
        await _firestore.collection('tasks').doc(task.id).update({
          'isExpired': true,
        });

        // Create a notification for the expired challenge
        await _notificationService.createChallengeExpiredNotification(
          userId: userId,
          taskTitle: task.title,
        );

        // Log analytics event
        await AnalyticsService.instance.logEvent(
          name: 'challenge_expired',
          parameters: {
            'task_id': task.id ?? '',
            'task_title': task.title,
          },
        );
      }
    } catch (e) {
      debugPrint('Error handling expired challenges: $e');
    }
  }

  /// Handle orphaned tasks (tasks whose creator no longer exists)
  Future<void> handleOrphanedTasks(String userId) async {
    try {
      // Get all tasks created by this user
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        return;
      }

      // Check if the user still exists
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // User still exists, no orphaned tasks
        return;
      }

      debugPrint('Found ${tasksSnapshot.docs.length} orphaned tasks for deleted user $userId');

      // Process each orphaned task
      for (final doc in tasksSnapshot.docs) {
        // Delete the orphaned task
        await _firestore.collection('tasks').doc(doc.id).delete();

        // Log analytics event
        await AnalyticsService.instance.logEvent(
          name: 'orphaned_task_deleted',
          parameters: {
            'task_id': doc.id,
          },
        );
      }
    } catch (e) {
      debugPrint('Error handling orphaned tasks: $e');
    }
  }

  /// Handle data inconsistencies (e.g., tasks with missing fields)
  Future<void> handleDataInconsistencies(String userId) async {
    try {
      // Get all tasks created by this user
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();

      if (tasksSnapshot.docs.isEmpty) {
        return;
      }

      int fixedTasks = 0;

      // Process each task
      for (final doc in tasksSnapshot.docs) {
        final data = doc.data();
        bool needsUpdate = false;
        final updates = <String, dynamic>{};

        // Check for missing required fields
        if (!data.containsKey('title') || data['title'] == null) {
          updates['title'] = 'Untitled Task';
          needsUpdate = true;
        }

        if (!data.containsKey('createdAt') || data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
          needsUpdate = true;
        }

        if (!data.containsKey('isCompleted') || data['isCompleted'] == null) {
          updates['isCompleted'] = false;
          needsUpdate = true;
        }

        if (!data.containsKey('category') || data['category'] == null) {
          updates['category'] = 'personal';
          needsUpdate = true;
        }

        // Update the task if needed
        if (needsUpdate) {
          await _firestore.collection('tasks').doc(doc.id).update(updates);
          fixedTasks++;
        }
      }

      if (fixedTasks > 0) {
        debugPrint('Fixed $fixedTasks tasks with data inconsistencies');
      }
    } catch (e) {
      debugPrint('Error handling data inconsistencies: $e');
    }
  }

  /// Run all edge case handlers
  Future<void> runAllEdgeCaseHandlers(String userId) async {
    await handleExpiredChallenges(userId);
    await handleOrphanedTasks(userId);
    await handleDataInconsistencies(userId);
  }
}
