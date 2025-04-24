import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/aura_gift_model.dart';
import 'package:taskswap/models/notification_model.dart';
import 'package:taskswap/services/activity_service.dart';
import 'package:taskswap/services/notification_service.dart';
import 'package:taskswap/services/user_service.dart';

class AuraGiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionPath = 'auraGifts';
  final ActivityService _activityService = ActivityService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // Give aura points to another user
  Future<void> giveAura({
    required String receiverId,
    required int points,
    String? message,
    String? taskId,
    String? taskTitle,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate points
      if (points <= 0) {
        throw Exception('Points must be greater than 0');
      }

      // Check if the current user can give aura to the receiver
      final canGiveAura = await _userService.canGiveAuraTo(currentUser.uid, receiverId);
      if (!canGiveAura) {
        throw Exception('You cannot give aura to this user due to privacy settings');
      }

      // Create the aura gift
      final auraGift = AuraGift(
        giverId: currentUser.uid,
        receiverId: receiverId,
        pointsGiven: points,
        message: message,
        taskId: taskId,
        taskTitle: taskTitle,
      );

      // Add the aura gift to Firestore
      final docRef = await _firestore.collection(_collectionPath).add(auraGift.toMap());

      // Update the receiver's aura points
      await _firestore.collection('users').doc(receiverId).update({
        'auraPoints': FieldValue.increment(points),
        'lastPointsEarnedAt': FieldValue.serverTimestamp(),
      });

      // Create activity records for both giver and receiver
      await _activityService.createAuraGivenActivity(
        giverId: currentUser.uid,
        receiverId: receiverId,
        points: points,
        message: message,
        taskTitle: taskTitle,
        auraGiftId: docRef.id,
      );

      await _activityService.createAuraReceivedActivity(
        giverId: currentUser.uid,
        receiverId: receiverId,
        points: points,
        message: message,
        taskTitle: taskTitle,
        auraGiftId: docRef.id,
      );

      // Create a notification for the receiver
      await _notificationService.createAuraReceivedNotification(
        receiverId: receiverId,
        giverId: currentUser.uid,
        points: points,
        message: message,
        taskTitle: taskTitle,
        auraGiftId: docRef.id,
      );

    } catch (e) {
      debugPrint('Error giving aura: $e');
      rethrow;
    }
  }

  // Get aura gifts given by the current user
  Stream<List<AuraGift>> getGivenAura() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .where('giverId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuraGift.fromFirestore(doc)).toList());
  }

  // Get aura gifts received by the current user
  Stream<List<AuraGift>> getReceivedAura() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .where('receiverId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuraGift.fromFirestore(doc)).toList());
  }

  // Get aura gifts given to a specific user
  Stream<List<AuraGift>> getAuraGiftsForUser(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuraGift.fromFirestore(doc)).toList());
  }

  // Get aura gifts between the current user and another user
  Stream<List<AuraGift>> getAuraGiftsBetweenUsers(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Check if the current user can see the other user's aura
    return Stream.fromFuture(_userService.canSeeUserAura(currentUser.uid, otherUserId))
        .asyncMap((canSee) async {
          if (!canSee) {
            return <AuraGift>[];
          }

          // We can't combine the queries with OR in Firestore easily, so we'll do two separate queries and combine the results
          // Get gifts given by current user to other user
          final givenSnapshot = await _firestore
              .collection(_collectionPath)
              .where('giverId', isEqualTo: currentUser.uid)
              .where('receiverId', isEqualTo: otherUserId)
              .get();

          // Get gifts received by current user from other user
          final receivedSnapshot = await _firestore
              .collection(_collectionPath)
              .where('giverId', isEqualTo: otherUserId)
              .where('receiverId', isEqualTo: currentUser.uid)
              .get();

          // Combine and convert the results
          final List<AuraGift> gifts = [
            ...givenSnapshot.docs.map((doc) => AuraGift.fromFirestore(doc)),
            ...receivedSnapshot.docs.map((doc) => AuraGift.fromFirestore(doc)),
          ];

          // Sort by timestamp
          gifts.sort((a, b) {
            if (a.timestamp == null) return 1;
            if (b.timestamp == null) return -1;
            return b.timestamp!.compareTo(a.timestamp!);
          });

          return gifts;
        })
        .asyncExpand((gifts) => Stream.periodic(const Duration(seconds: 5), (_) => gifts));
  }

  // Notify a friend about a completed task (so they can give aura points)
  Future<void> notifyFriendOfTaskCompletion({
    required String friendId,
    required String taskId,
    required String taskTitle,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the current user's name
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final displayName = userData?['displayName'] ?? 'A friend';

      // Create a notification for the friend
      await _notificationService.createNotification(
        userId: friendId,
        type: NotificationType.taskCompleted,
        message: '$displayName completed "$taskTitle" - Give them aura!',
        fromUserId: currentUser.uid,
        relatedTaskId: taskId,
        data: {
          'taskTitle': taskTitle,
          'completedBy': currentUser.uid,
          'completedByName': displayName,
        },
      );

      // Create an activity record
      await _activityService.createTaskSharedActivity(
        userId: currentUser.uid,
        friendId: friendId,
        taskId: taskId,
        taskTitle: taskTitle,
      );

    } catch (e) {
      debugPrint('Error notifying friend of task completion: $e');
      rethrow;
    }
  }
}
