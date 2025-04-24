import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/activity_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/user_service.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionPath = 'activities';
  final UserService _userService = UserService();

  // Create a task completed activity
  Future<void> createTaskCompletedActivity({
    required String userId,
    required String taskTitle,
    required int points,
    String? taskId,
  }) async {
    try {
      final activity = Activity(
        userId: userId,
        type: ActivityType.taskCompleted,
        title: 'Completed a task',
        description: taskTitle,
        points: points,
        relatedTaskId: taskId,
      );

      await _firestore.collection(_collectionPath).add(activity.toMap());
    } catch (e) {
      debugPrint('Error creating task completed activity: $e');
      // Don't rethrow - activity creation should not block task completion
    }
  }

  // Create a challenge completed activity
  Future<void> createChallengeCompletedActivity({
    required String userId,
    required String challengerId,
    required String description,
    required int points,
    String? challengeId,
  }) async {
    try {
      final activity = Activity(
        userId: userId,
        type: ActivityType.challengeCompleted,
        title: 'Completed a challenge',
        description: description,
        points: points,
        relatedUserId: challengerId,
        relatedChallengeId: challengeId,
      );

      await _firestore.collection(_collectionPath).add(activity.toMap());
    } catch (e) {
      debugPrint('Error creating challenge completed activity: $e');
      // Don't rethrow - activity creation should not block challenge completion
    }
  }

  // Create an aura given activity
  Future<void> createAuraGivenActivity({
    required String giverId,
    required String receiverId,
    required int points,
    String? message,
    String? taskTitle,
    String? auraGiftId,
  }) async {
    try {
      // Get receiver's name
      final receiver = await _userService.getUserById(receiverId);
      final receiverName = receiver?.displayName ?? 'a friend';

      final activity = Activity(
        userId: giverId,
        type: ActivityType.auraGiven,
        title: 'Gave Aura Points',
        description: message ?? 'Gave $points aura points to $receiverName${taskTitle != null ? ' for "$taskTitle"' : ''}',
        points: points,
        relatedUserId: receiverId,
        relatedAuraGiftId: auraGiftId,
      );

      await _firestore.collection(_collectionPath).add(activity.toMap());
    } catch (e) {
      debugPrint('Error creating aura given activity: $e');
      // Don't rethrow - activity creation should not block aura giving
    }
  }

  // Create an aura received activity
  Future<void> createAuraReceivedActivity({
    required String giverId,
    required String receiverId,
    required int points,
    String? message,
    String? taskTitle,
    String? auraGiftId,
  }) async {
    try {
      // Get giver's name
      final giver = await _userService.getUserById(giverId);
      final giverName = giver?.displayName ?? 'a friend';

      final activity = Activity(
        userId: receiverId,
        type: ActivityType.auraReceived,
        title: 'Received Aura Points',
        description: message ?? 'Received $points aura points from $giverName${taskTitle != null ? ' for "$taskTitle"' : ''}',
        points: points,
        relatedUserId: giverId,
        relatedAuraGiftId: auraGiftId,
      );

      await _firestore.collection(_collectionPath).add(activity.toMap());
    } catch (e) {
      debugPrint('Error creating aura received activity: $e');
      // Don't rethrow - activity creation should not block aura giving
    }
  }

  // Create an achievement earned activity
  Future<void> createAchievementEarnedActivity({
    required String userId,
    required String achievementName,
  }) async {
    try {
      final activity = Activity(
        userId: userId,
        type: ActivityType.achievementEarned,
        title: 'Earned an Achievement',
        description: achievementName,
      );

      await _firestore.collection(_collectionPath).add(activity.toMap());
    } catch (e) {
      debugPrint('Error creating achievement earned activity: $e');
      // Don't rethrow - activity creation should not block achievement earning
    }
  }

  // Create a friend added activity
  Future<void> createFriendAddedActivity({
    required String userId,
    required String friendId,
  }) async {
    try {
      // Get friend's name
      final friend = await _userService.getUserById(friendId);
      final friendName = friend?.displayName ?? 'a new friend';

      final activity = Activity(
        userId: userId,
        type: ActivityType.friendAdded,
        title: 'Added a Friend',
        description: 'Connected with $friendName',
        relatedUserId: friendId,
      );

      await _firestore.collection(_collectionPath).add(activity.toMap());
    } catch (e) {
      debugPrint('Error creating friend added activity: $e');
      // Don't rethrow - activity creation should not block friend adding
    }
  }

  // Create a task shared activity (for aura recognition)
  Future<void> createTaskSharedActivity({
    required String userId,
    required String friendId,
    required String taskId,
    required String taskTitle,
  }) async {
    try {
      // Get friend's name
      final friend = await _userService.getUserById(friendId);
      final friendName = friend?.displayName ?? 'a friend';

      final activity = Activity(
        userId: userId,
        type: ActivityType.taskCompleted,
        title: 'Shared Task Completion',
        description: 'Shared "$taskTitle" with $friendName',
        relatedUserId: friendId,
        relatedTaskId: taskId,
      );

      await _firestore.collection(_collectionPath).add(activity.toMap());
    } catch (e) {
      debugPrint('Error creating task shared activity: $e');
      // Don't rethrow - activity creation should not block task sharing
    }
  }

  // Get activities for the current user's feed (from friends only)
  Stream<List<Activity>> getFeedActivities() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Get the current user's friends
    return _userService.getUserById(currentUser.uid).asStream().asyncMap((user) async {
      try {
        if (user == null) {
          return [];
        }

        // Get the user's friends list
        final friendIds = user.friends;

        // Add current user to the list
        final userIds = List<String>.from(friendIds);
        userIds.add(currentUser.uid);

        // Get the user's hidden activities
        debugPrint('Fetching hidden activities for user ${currentUser.uid}');
        final hiddenActivitiesSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('hiddenActivities')
            .get();

        final hiddenActivityIds = hiddenActivitiesSnapshot.docs.map((doc) => doc.id).toSet();
        debugPrint('Found ${hiddenActivityIds.length} hidden activities: ${hiddenActivityIds.join(', ')}');

        // If no friends, return only the user's activities
        if (userIds.length <= 1) {
          final snapshot = await _firestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

          // Filter out hidden activities
          return snapshot.docs
              .map((doc) => Activity.fromFirestore(doc))
              .where((activity) => !hiddenActivityIds.contains(activity.id))
              .toList();
        }

        // Get activities from friends and current user
        try {
          final snapshot = await _firestore
              .collection(_collectionPath)
              .where('userId', whereIn: userIds)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

          // Filter out hidden activities
          return snapshot.docs
              .map((doc) => Activity.fromFirestore(doc))
              .where((activity) => !hiddenActivityIds.contains(activity.id))
              .toList();
        } catch (e) {
          // If the index isn't ready yet, fall back to getting activities without ordering
          debugPrint('Error getting feed with ordering: $e');
          debugPrint('Falling back to unordered feed. Please create the required index in Firebase console.');

          // Fallback: Get activities without ordering
          List<Activity> allActivities = [];

          // Get activities for each user separately
          for (final userId in userIds) {
            final userSnapshot = await _firestore
                .collection(_collectionPath)
                .where('userId', isEqualTo: userId)
                .limit(10)
                .get();

            allActivities.addAll(userSnapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList());
          }

          // Sort manually
          allActivities.sort((a, b) {
            if (a.timestamp == null) return 1;
            if (b.timestamp == null) return -1;
            return b.timestamp!.compareTo(a.timestamp!);
          });

          // Filter out hidden activities
          allActivities = allActivities
              .where((activity) => !hiddenActivityIds.contains(activity.id))
              .toList();

          // Limit to 50
          if (allActivities.length > 50) {
            allActivities = allActivities.sublist(0, 50);
          }

          return allActivities;
        }
      } catch (e) {
        debugPrint('Error in getFeedActivities: $e');
        return [];
      }
    });
  }

  // Get activities for a specific user
  Stream<List<Activity>> getUserActivities(String userId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Create a StreamController to manage the stream
    final controller = StreamController<List<Activity>>();

    // Process asynchronously
    Future<void> process() async {
      try {
        // Check if the current user can see the target user's activities
        final canSee = await _userService.canSeeUserAura(currentUser.uid, userId);

        // If viewing own profile or has permission
        if (currentUser.uid == userId || canSee) {
          // Set up a stream subscription to the Firestore query
          final subscription = _firestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .limit(20)
              .snapshots()
              .map((snapshot) =>
                  snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList())
              .listen(
                (activities) => controller.add(activities),
                onError: (error) {
                  debugPrint('Error getting user activities: $error');
                  controller.add([]);
                },
              );

          // Close the controller when the stream is done
          controller.onCancel = () {
            subscription.cancel();
          };
        } else {
          // No permission to view activities
          controller.add([]);
          await controller.close();
        }
      } catch (e) {
        debugPrint('Error in getUserActivities: $e');
        controller.add([]);
        await controller.close();
      }
    }

    // Start the processing
    process();

    // Return the stream from the controller
    return controller.stream;
  }

  // Like an activity
  Future<void> likeActivity(String activityId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection(_collectionPath).doc(activityId).update({
        'likedBy': FieldValue.arrayUnion([currentUser.uid]),
      });
    } catch (e) {
      debugPrint('Error liking activity: $e');
      rethrow;
    }
  }

  // Unlike an activity
  Future<void> unlikeActivity(String activityId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection(_collectionPath).doc(activityId).update({
        'likedBy': FieldValue.arrayRemove([currentUser.uid]),
      });
    } catch (e) {
      debugPrint('Error unliking activity: $e');
      rethrow;
    }
  }

  // Add a reaction to an activity
  Future<void> addReaction(String activityId, String emoji) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the current reactions
      final doc = await _firestore.collection(_collectionPath).doc(activityId).get();
      final data = doc.data() as Map<String, dynamic>?;

      Map<String, dynamic> reactions = {};
      if (data != null && data['reactions'] != null) {
        reactions = Map<String, dynamic>.from(data['reactions']);
      }

      // Add or update the reaction
      reactions[currentUser.uid] = emoji;

      await _firestore.collection(_collectionPath).doc(activityId).update({
        'reactions': reactions,
      });
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      rethrow;
    }
  }

  // Remove a reaction from an activity
  Future<void> removeReaction(String activityId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the current reactions
      final doc = await _firestore.collection(_collectionPath).doc(activityId).get();
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null || data['reactions'] == null) {
        return;
      }

      Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions']);

      // Remove the reaction
      reactions.remove(currentUser.uid);

      await _firestore.collection(_collectionPath).doc(activityId).update({
        'reactions': reactions,
      });
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      rethrow;
    }
  }

  // Edit an activity (only the owner can edit)
  Future<void> editActivity(String activityId, {String? title, String? description}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the activity to check ownership
      final doc = await _firestore.collection(_collectionPath).doc(activityId).get();
      if (!doc.exists) {
        throw Exception('Activity not found');
      }

      final activity = Activity.fromFirestore(doc);

      // Check if the current user is the owner
      if (activity.userId != currentUser.uid) {
        throw Exception('You can only edit your own activities');
      }

      // Prepare updates
      final updates = <String, dynamic>{};

      if (title != null) {
        updates['title'] = title;
      }

      if (description != null) {
        updates['description'] = description;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection(_collectionPath).doc(activityId).update(updates);
      }
    } catch (e) {
      debugPrint('Error editing activity: $e');
      rethrow;
    }
  }

  // Hide an activity from the current user's feed (doesn't delete it)
  Future<void> hideActivityFromFeed(String activityId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Starting to hide activity $activityId for user ${currentUser.uid}');

      // Add the activity to the user's hidden activities collection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('hiddenActivities')
          .doc(activityId)
          .set({
        'hiddenAt': FieldValue.serverTimestamp(),
        'activityId': activityId,
      });

      debugPrint('Activity $activityId successfully hidden from feed');

      // Verify the activity was hidden
      final hiddenDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('hiddenActivities')
          .doc(activityId)
          .get();

      if (hiddenDoc.exists) {
        debugPrint('Verified: Activity $activityId is now in hidden collection');
      } else {
        debugPrint('Warning: Activity $activityId was not found in hidden collection after hiding');
      }
    } catch (e) {
      debugPrint('Error hiding activity: $e');
      rethrow;
    }
  }

  // Get activities for a specific user as a Future (non-stream version)
  Future<List<Activity>> getUserActivitiesFuture(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    try {
      // Check if the current user can see the target user's activities
      final canSee = await _userService.canSeeUserAura(currentUser.uid, userId);

      // If viewing own profile or has permission
      if (currentUser.uid == userId || canSee) {
        final snapshot = await _firestore
            .collection(_collectionPath)
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        return snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
      } else {
        // No permission to view activities
        return [];
      }
    } catch (e) {
      debugPrint('Error in getUserActivitiesFuture: $e');
      return [];
    }
  }

  // Delete an activity (only the owner can delete)
  Future<void> deleteActivity(String activityId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Starting to delete activity $activityId');

      // Get the activity to check ownership
      final doc = await _firestore.collection(_collectionPath).doc(activityId).get();
      if (!doc.exists) {
        throw Exception('Activity not found');
      }

      final activity = Activity.fromFirestore(doc);

      // Check if the current user is the owner
      if (activity.userId != currentUser.uid) {
        throw Exception('You can only delete your own activities');
      }

      // Delete the activity
      await _firestore.collection(_collectionPath).doc(activityId).delete();
      debugPrint('Activity $activityId successfully deleted');

      // Verify the activity was deleted
      final verifyDoc = await _firestore.collection(_collectionPath).doc(activityId).get();
      if (!verifyDoc.exists) {
        debugPrint('Verified: Activity $activityId no longer exists in the database');
      } else {
        debugPrint('Warning: Activity $activityId still exists after deletion attempt');
      }

      // Also hide the activity from the current user's feed (in case it's a shared activity)
      try {
        await hideActivityFromFeed(activityId);
        debugPrint('Also hidden activity $activityId from feed as a precaution');
      } catch (hideError) {
        debugPrint('Note: Could not hide activity after deletion: $hideError');
      }
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      rethrow;
    }
  }
}
