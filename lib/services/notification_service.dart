import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/notification_model.dart';

// Simplified notification service for testing
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final String _collectionPath = 'notifications';

  // Initialize notification channels and request permissions
  Future<void> initNotifications() async {
    // Request permission for iOS
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notifications temporarily disabled for testing');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
  }

  // Get FCM token for the current user
  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  // Save FCM token to user document
  Future<void> saveFCMToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot save FCM token: No authenticated user');
        return;
      }

      // Check if user document exists first
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        debugPrint('User document does not exist yet, skipping FCM token update');
        return;
      }

      final token = await getFCMToken();
      if (token == null) {
        debugPrint('Cannot save FCM token: Failed to get token');
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      debugPrint('FCM token saved successfully');
    } catch (e) {
      // Just log the error but don't rethrow to prevent login failures
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Remove FCM token when user logs out
  Future<void> removeFCMToken() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot remove FCM token: No authenticated user');
        return;
      }

      // Check if user document exists first
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        debugPrint('User document does not exist, skipping FCM token removal');
        return;
      }

      final token = await getFCMToken();
      if (token == null) {
        debugPrint('Cannot remove FCM token: Failed to get token');
        return;
      }

      await _firestore.collection('users').doc(currentUser.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
      debugPrint('FCM token removed successfully');
    } catch (e) {
      // Just log the error but don't rethrow to prevent logout failures
      debugPrint('Error removing FCM token: $e');
    }
  }

  // Create a notification
  Future<String?> createNotification({
    required String userId,
    required NotificationType type,
    required String message,
    String? fromUserId,
    String? relatedTaskId,
    String? relatedChallengeId,
    String? relatedAuraGiftId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if the user exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Create the notification
      final notification = NotificationModel(
        userId: userId,
        type: type,
        message: message,
        fromUserId: fromUserId,
        relatedTaskId: relatedTaskId,
        relatedChallengeId: relatedChallengeId,
        relatedAuraGiftId: relatedAuraGiftId,
        data: data,
      );

      // Add the notification to Firestore
      final docRef = await _firestore.collection(_collectionPath).add(notification.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return null;
    }
  }

  // Get notifications for the current user
  Stream<List<NotificationModel>> getUserNotifications({bool unreadOnly = false}) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true);

    if (unreadOnly) {
      query = query.where('read', isEqualTo: false);
    }

    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  // Get unread notifications count for the current user
  Stream<int> getUnreadNotificationsCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collectionPath).doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read for the current user
  Future<void> markAllNotificationsAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all unread notifications for the current user
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      // Create a batch to update all notifications at once
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collectionPath).doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  // Delete all notifications for the current user
  Future<void> deleteAllNotifications() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all notifications for the current user
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Create a batch to delete all notifications at once
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }

  // Create a notification for aura received
  Future<String?> createAuraReceivedNotification({
    required String receiverId,
    required String giverId,
    required int points,
    String? message,
    String? taskTitle,
    String? auraGiftId,
  }) async {
    try {
      // Get giver's name
      final giverDoc = await _firestore.collection('users').doc(giverId).get();
      final giverData = giverDoc.data();
      final giverName = giverData?['displayName'] ?? 'Someone';

      // Create notification message
      String notificationMessage;
      if (message != null && message.isNotEmpty) {
        notificationMessage = '$giverName gave you $points aura points: "$message"';
      } else if (taskTitle != null && taskTitle.isNotEmpty) {
        notificationMessage = '$giverName gave you $points aura points for "$taskTitle"';
      } else {
        notificationMessage = '$giverName gave you $points aura points';
      }

      // Create the notification
      return await createNotification(
        userId: receiverId,
        type: NotificationType.auraReceived,
        message: notificationMessage,
        fromUserId: giverId,
        relatedAuraGiftId: auraGiftId,
        data: {
          'points': points,
          'taskTitle': taskTitle,
        },
      );
    } catch (e) {
      debugPrint('Error creating aura received notification: $e');
      return null;
    }
  }

  // Create a notification for challenge completed
  Future<String?> createChallengeCompletedNotification({
    required String challengerId,
    required String completerId,
    required String challengeDescription,
    required int points,
    String? challengeId,
  }) async {
    try {
      // Get completer's name
      final completerDoc = await _firestore.collection('users').doc(completerId).get();
      final completerData = completerDoc.data();
      final completerName = completerData?['displayName'] ?? 'Someone';

      // Create notification message
      final notificationMessage = '$completerName completed your challenge: "$challengeDescription" and earned $points points';

      // Create the notification
      return await createNotification(
        userId: challengerId,
        type: NotificationType.challengeCompleted,
        message: notificationMessage,
        fromUserId: completerId,
        relatedChallengeId: challengeId,
        data: {
          'points': points,
          'description': challengeDescription,
        },
      );
    } catch (e) {
      debugPrint('Error creating challenge completed notification: $e');
      return null;
    }
  }

  // Create a notification for friend request
  Future<String?> createFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
  }) async {
    try {
      // Get sender's name
      final senderDoc = await _firestore.collection('users').doc(fromUserId).get();
      final senderData = senderDoc.data();
      final senderName = senderData?['displayName'] ?? 'Someone';

      // Create notification message
      final notificationMessage = '$senderName sent you a friend request';

      // Create the notification
      return await createNotification(
        userId: toUserId,
        type: NotificationType.friendRequest,
        message: notificationMessage,
        fromUserId: fromUserId,
      );
    } catch (e) {
      debugPrint('Error creating friend request notification: $e');
      return null;
    }
  }

  // Create a notification for friend request accepted
  Future<String?> createFriendAcceptedNotification({
    required String toUserId,
    required String fromUserId,
  }) async {
    try {
      // Get accepter's name
      final accepterDoc = await _firestore.collection('users').doc(fromUserId).get();
      final accepterData = accepterDoc.data();
      final accepterName = accepterData?['displayName'] ?? 'Someone';

      // Create notification message
      final notificationMessage = '$accepterName accepted your friend request';

      // Create the notification
      return await createNotification(
        userId: toUserId,
        type: NotificationType.friendAccepted,
        message: notificationMessage,
        fromUserId: fromUserId,
      );
    } catch (e) {
      debugPrint('Error creating friend accepted notification: $e');
      return null;
    }
  }

  // Create a notification for milestone reached
  Future<String?> createMilestoneNotification({
    required String userId,
    required String milestone,
    int? points,
  }) async {
    try {
      // Create notification message
      String notificationMessage;
      if (points != null) {
        notificationMessage = 'You reached a milestone: $milestone and earned $points aura points!';
      } else {
        notificationMessage = 'You reached a milestone: $milestone!';
      }

      // Create the notification
      return await createNotification(
        userId: userId,
        type: NotificationType.milestone,
        message: notificationMessage,
        data: {
          'milestone': milestone,
          'points': points,
        },
      );
    } catch (e) {
      debugPrint('Error creating milestone notification: $e');
      return null;
    }
  }

  // Create a system notification
  Future<String?> createSystemNotification({
    required String userId,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create the notification
      final notificationId = await createNotification(
        userId: userId,
        type: NotificationType.system,
        message: message,
        data: data,
      );

      // Send push notification if possible - temporarily disabled for testing
      /*
      await _sendPushNotification(
        userId: userId,
        title: 'TaskSwap',
        body: message,
        data: data ?? {},
      );
      */

      return notificationId;
    } catch (e) {
      debugPrint('Error creating system notification: $e');
      return null;
    }
  }

  // Send a push notification to a user - temporarily disabled for testing
  /*
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get the user's FCM tokens
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final fcmTokens = userData?['fcmTokens'] as List<dynamic>?;

      if (fcmTokens == null || fcmTokens.isEmpty) {
        debugPrint('No FCM tokens found for user $userId');
        return;
      }

      // For now, we'll just show a local notification for testing
      // In a production app, you would use Firebase Cloud Functions or a server
      // to send the actual push notification to the FCM tokens

      // For testing, we'll show a local notification if the user is the current user
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await _showLocalNotification(
          title: title,
          body: body,
          payload: jsonEncode(data),
        );
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
  */
}
