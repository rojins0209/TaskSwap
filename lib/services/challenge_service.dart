import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'package:taskswap/constants/app_constants.dart';
import 'package:taskswap/models/challenge_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/services/activity_service.dart';
import 'package:taskswap/services/notification_service.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final NotificationService _notificationService = NotificationService();
  final String _challengesCollectionPath = 'challenges';

  // Send a challenge to a friend
  Future<void> sendChallenge(String toUserId, String taskDescription, {
    int points = AppConstants.defaultChallengePoints,
    bool bothUsersComplete = false,
    DateTime? dueDate,
    TaskCategory category = TaskCategory.personal,
    int? timerDuration,
    bool challengeYourself = false,
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

      // Enforce maximum points limit
      if (points > AppConstants.maxChallengePoints) {
        throw Exception('Maximum points allowed for challenges is ${AppConstants.maxChallengePoints}');
      }

      // Create a new challenge
      final challenge = Challenge(
        fromUserId: currentUser.uid,
        toUserId: toUserId,
        taskDescription: taskDescription,
        points: points,
        bothUsersComplete: bothUsersComplete,
        dueDate: dueDate,
        category: category,
        timerDuration: timerDuration,
        challengeYourself: challengeYourself,
      );

      // Add the challenge to Firestore
      await _firestore.collection(_challengesCollectionPath).add(challenge.toMap());

      // Create a notification for the challenge recipient
      String message = 'You received a new challenge: "$taskDescription"';
      if (bothUsersComplete) {
        message += ' (Both of you need to complete this task)';
      }
      if (dueDate != null) {
        final formattedDate = DateFormat('MMM d, yyyy').format(dueDate);
        message += ' (Due: $formattedDate)';
      }
      if (timerDuration != null) {
        message += ' (Timer: $timerDuration minutes)';
      }
      if (challengeYourself) {
        message += ' (Challenge yourself with a friend)';
      }

      await _notificationService.createSystemNotification(
        userId: toUserId,
        message: message,
        data: {
          'type': 'challenge_received',
          'fromUserId': currentUser.uid,
          'points': points,
          'bothUsersComplete': bothUsersComplete,
          'dueDate': dueDate?.millisecondsSinceEpoch,
          'timerDuration': timerDuration,
          'challengeYourself': challengeYourself,
        },
      );
    } catch (e) {
      debugPrint('Error sending challenge: $e');
      rethrow;
    }
  }

  // Accept a challenge
  Future<void> acceptChallenge(String challengeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the challenge
      final challengeDoc = await _firestore.collection(_challengesCollectionPath).doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challengeData = challengeDoc.data() as Map<String, dynamic>;
      if (challengeData['toUserId'] != currentUser.uid) {
        throw Exception('Not authorized to accept this challenge');
      }

      if (challengeData['status'] != 'pending') {
        throw Exception('Challenge is not pending');
      }

      // Update the challenge status
      await _firestore.collection(_challengesCollectionPath).doc(challengeId).update({
        'status': 'accepted',
      });
    } catch (e) {
      debugPrint('Error accepting challenge: $e');
      rethrow;
    }
  }

  // Reject a challenge
  Future<void> rejectChallenge(String challengeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the challenge
      final challengeDoc = await _firestore.collection(_challengesCollectionPath).doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challengeData = challengeDoc.data() as Map<String, dynamic>;
      if (challengeData['toUserId'] != currentUser.uid) {
        throw Exception('Not authorized to reject this challenge');
      }

      if (challengeData['status'] != 'pending') {
        throw Exception('Challenge is not pending');
      }

      // Update the challenge status
      await _firestore.collection(_challengesCollectionPath).doc(challengeId).update({
        'status': 'rejected',
      });
    } catch (e) {
      debugPrint('Error rejecting challenge: $e');
      rethrow;
    }
  }

  // Complete a challenge (for receiver)
  Future<Map<String, dynamic>> completeChallenge(String challengeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the challenge data outside the transaction
      final challengeDoc = await _firestore.collection(_challengesCollectionPath).doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challengeData = challengeDoc.data() as Map<String, dynamic>;
      if (challengeData['toUserId'] != currentUser.uid) {
        throw Exception('Not authorized to complete this challenge');
      }

      if (challengeData['status'] != 'accepted') {
        throw Exception('Challenge must be accepted before completion');
      }

      // Check if this is a challenge that both users need to complete
      final bothUsersComplete = challengeData['bothUsersComplete'] ?? false;
      final senderCompleted = challengeData['senderCompleted'] ?? false;

      // Mark the receiver as completed
      final updateData = {
        'receiverCompleted': true,
        'receiverCompletedAt': FieldValue.serverTimestamp(),
      };

      // If both users need to complete, only mark as fully completed if sender has also completed
      if (!bothUsersComplete || (bothUsersComplete && senderCompleted)) {
        updateData['status'] = 'completed';
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      // Get the challenge points
      final challengePoints = challengeData['points'] ?? AppConstants.defaultChallengePoints;
      final fromUserId = challengeData['fromUserId'];

      // Calculate bonus points based on how quickly the challenge was completed
      int bonusPoints = 0;
      final createdAt = challengeData['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final now = DateTime.now();
        final daysSinceCreation = now.difference(createdAt.toDate()).inDays;

        // Bonus points for completing quickly
        if (daysSinceCreation <= 1) {
          bonusPoints = AppConstants.challengeCompletionBonusSameDay; // Same day or next day completion
        } else if (daysSinceCreation <= 3) {
          bonusPoints = AppConstants.challengeCompletionBonusWithin3Days; // Within 3 days
        }
      }

      // Calculate total points earned
      final totalPointsEarned = challengePoints + bonusPoints;

      // For challenges where both users complete, each gets full points when they complete their part
      final senderPointsEarned = bothUsersComplete ? totalPointsEarned : totalPointsEarned ~/ 2;

      // Update the challenge with points earned information
      updateData['pointsEarned'] = totalPointsEarned;
      updateData['notifiedSender'] = false; // Will be set to true when sender is notified

      await _firestore.collection(_challengesCollectionPath).doc(challengeId).update(updateData);

      // If both users need to complete and the sender has already completed, or if it's a regular challenge
      if (!bothUsersComplete || (bothUsersComplete && senderCompleted)) {
        // Update the challenger's points
        await _firestore.collection('users').doc(fromUserId).update({
          'auraPoints': FieldValue.increment(senderPointsEarned),
          'lastPointsEarnedAt': FieldValue.serverTimestamp(),
        });

        // Update the challenger's streak
        await _userService.updateUserStreak(fromUserId);
      }

      // Update the current user's points and completed tasks
      await _firestore.collection('users').doc(currentUser.uid).update({
        'auraPoints': FieldValue.increment(totalPointsEarned),
        'completedTasks': FieldValue.increment(1),
        'lastPointsEarnedAt': FieldValue.serverTimestamp(),
      });

      // Update the current user's streak
      await _userService.updateUserStreak(currentUser.uid);

      // Create activity records for both users
      await _activityService.createChallengeCompletedActivity(
        userId: currentUser.uid,
        challengerId: fromUserId,
        description: challengeData['taskDescription'] ?? 'Challenge',
        points: totalPointsEarned,
        challengeId: challengeId,
      );

      // Create activity for the challenger as well (they get half the points)
      if (!bothUsersComplete || (bothUsersComplete && senderCompleted)) {
        await _activityService.createChallengeCompletedActivity(
          userId: fromUserId,
          challengerId: currentUser.uid,
          description: challengeData['taskDescription'] ?? 'Challenge',
          points: senderPointsEarned,
          challengeId: challengeId,
        );
      }

      // Create a notification for the challenge sender

      await _notificationService.createChallengeCompletedNotification(
        challengerId: fromUserId,
        completerId: currentUser.uid,
        challengeDescription: challengeData['taskDescription'] ?? 'Challenge',
        points: senderPointsEarned,
        challengeId: challengeId,
      );

      // Get the challenger's name for the UI
      final challengerDoc = await _firestore.collection('users').doc(fromUserId).get();
      final challengerName = challengerDoc.exists ?
          (challengerDoc.data() as Map<String, dynamic>)['displayName'] ??
          (challengerDoc.data() as Map<String, dynamic>)['email'] ?? 'your friend' :
          'your friend';

      // Return information about the completed challenge for the UI
      return {
        'pointsEarned': totalPointsEarned,
        'bonusPoints': bonusPoints,
        'challengerName': challengerName,
        'challengeDescription': challengeData['taskDescription'],
        'bothUsersComplete': bothUsersComplete,
        'fullyCompleted': !bothUsersComplete || (bothUsersComplete && senderCompleted),
      };
    } catch (e) {
      debugPrint('Error completing challenge: $e');
      rethrow;
    }
  }

  // Complete a challenge as the sender (for challenges where both users complete)
  Future<Map<String, dynamic>> completeChallengeAsSender(String challengeId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the challenge data
      final challengeDoc = await _firestore.collection(_challengesCollectionPath).doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw Exception('Challenge not found');
      }

      final challengeData = challengeDoc.data() as Map<String, dynamic>;
      if (challengeData['fromUserId'] != currentUser.uid) {
        throw Exception('Not authorized to complete this challenge as sender');
      }

      if (challengeData['status'] != 'accepted') {
        throw Exception('Challenge must be accepted before completion');
      }

      // Check if this is a challenge that both users need to complete
      final bothUsersComplete = challengeData['bothUsersComplete'] ?? false;
      if (!bothUsersComplete) {
        throw Exception('This challenge does not require the sender to complete it');
      }

      final receiverCompleted = challengeData['receiverCompleted'] ?? false;

      // Mark the sender as completed
      final updateData = {
        'senderCompleted': true,
        'senderCompletedAt': FieldValue.serverTimestamp(),
      };

      // If receiver has also completed, mark the challenge as fully completed
      if (receiverCompleted) {
        updateData['status'] = 'completed';
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      // Get the challenge points
      final challengePoints = challengeData['points'] ?? AppConstants.defaultChallengePoints;
      final toUserId = challengeData['toUserId'];

      // Calculate bonus points based on how quickly the challenge was completed
      int bonusPoints = 0;
      final createdAt = challengeData['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final now = DateTime.now();
        final daysSinceCreation = now.difference(createdAt.toDate()).inDays;

        // Bonus points for completing quickly
        if (daysSinceCreation <= 1) {
          bonusPoints = AppConstants.challengeCompletionBonusSameDay;
        } else if (daysSinceCreation <= 3) {
          bonusPoints = AppConstants.challengeCompletionBonusWithin3Days;
        }
      }

      // Calculate total points earned
      final totalPointsEarned = challengePoints + bonusPoints;

      await _firestore.collection(_challengesCollectionPath).doc(challengeId).update(updateData);

      // Update the current user's points and completed tasks
      await _firestore.collection('users').doc(currentUser.uid).update({
        'auraPoints': FieldValue.increment(totalPointsEarned),
        'completedTasks': FieldValue.increment(1),
        'lastPointsEarnedAt': FieldValue.serverTimestamp(),
      });

      // Update the current user's streak
      await _userService.updateUserStreak(currentUser.uid);

      // If the receiver has already completed, update their points too
      if (receiverCompleted) {
        // Update the challenge with points earned information
        await _firestore.collection(_challengesCollectionPath).doc(challengeId).update({
          'pointsEarned': totalPointsEarned,
        });

        // Update the receiver's points
        await _firestore.collection('users').doc(toUserId).update({
          'auraPoints': FieldValue.increment(totalPointsEarned),
          'lastPointsEarnedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create an activity record for the completed challenge
      await _activityService.createChallengeCompletedActivity(
        userId: currentUser.uid,
        challengerId: toUserId, // In this case, the receiver is considered the challenger
        description: challengeData['taskDescription'] ?? 'Challenge',
        points: totalPointsEarned,
        challengeId: challengeId,
      );

      // Create a notification for the challenge receiver
      await _notificationService.createSystemNotification(
        userId: toUserId,
        message: '${currentUser.displayName ?? 'Your friend'} completed their part of the challenge: "${challengeData['taskDescription'] ?? 'Challenge'}"',
        data: {
          'type': 'challenge_sender_completed',
          'challengeId': challengeId,
          'points': totalPointsEarned,
        },
      );

      // Get the receiver's name for the UI
      final receiverDoc = await _firestore.collection('users').doc(toUserId).get();
      final receiverName = receiverDoc.exists ?
          (receiverDoc.data() as Map<String, dynamic>)['displayName'] ??
          (receiverDoc.data() as Map<String, dynamic>)['email'] ?? 'your friend' :
          'your friend';

      // Return information for UI animations and messages
      return {
        'pointsEarned': totalPointsEarned,
        'bonusPoints': bonusPoints,
        'receiverName': receiverName,
        'challengeDescription': challengeData['taskDescription'],
        'fullyCompleted': receiverCompleted,
      };
    } catch (e) {
      debugPrint('Error completing challenge as sender: $e');
      rethrow;
    }
  }

  // Get all challenges for the current user (sent or received)
  Stream<List<Challenge>> getUserChallenges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Use a simpler approach - get all challenges and filter in memory
    return _firestore
        .collection(_challengesCollectionPath)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromFirestore(doc))
              .where((challenge) =>
                  challenge.fromUserId == currentUser.uid ||
                  challenge.toUserId == currentUser.uid)
              .toList();

          // Sort by createdAt date
          challenges.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });

          return challenges;
        });
  }

  // Get pending challenges received by the current user
  Stream<List<Challenge>> getPendingReceivedChallenges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_challengesCollectionPath)
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        // Removed orderBy to avoid needing a complex index
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
          // Sort in memory instead
          challenges.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return challenges;
        });
  }

  // Get pending challenges sent by the current user
  Stream<List<Challenge>> getPendingSentChallenges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_challengesCollectionPath)
        .where('fromUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
          // Sort in memory instead
          challenges.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return challenges;
        });
  }

  // Get accepted challenges for the current user
  Stream<List<Challenge>> getAcceptedChallenges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_challengesCollectionPath)
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'accepted')
        // Removed orderBy to avoid needing a complex index
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
          // Sort in memory instead
          challenges.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return challenges;
        });
  }

  // Get challenges that the current user (as sender) needs to complete
  Stream<List<Challenge>> getSenderChallenges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_challengesCollectionPath)
        .where('fromUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'accepted')
        .where('bothUsersComplete', isEqualTo: true)
        .where('senderCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs.map((doc) => Challenge.fromFirestore(doc)).toList();
          // Sort in memory
          challenges.sort((a, b) {
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return challenges;
        });
  }

  // Get completed challenges for the current user
  Stream<List<Challenge>> getCompletedChallenges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Use a simpler query and filter in memory
    return _firestore
        .collection(_challengesCollectionPath)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromFirestore(doc))
              .where((challenge) =>
                  challenge.fromUserId == currentUser.uid ||
                  challenge.toUserId == currentUser.uid)
              .toList();

          // Sort by completedAt date
          challenges.sort((a, b) {
            if (a.completedAt == null) return 1;
            if (b.completedAt == null) return -1;
            return b.completedAt!.compareTo(a.completedAt!);
          });

          return challenges;
        });
  }

  // Get challenges that have been completed but the sender hasn't been notified yet
  Stream<List<Challenge>> getUnnotifiedCompletedChallenges() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_challengesCollectionPath)
        .where('fromUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'completed')
        .where('notifiedSender', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs
              .map((doc) => Challenge.fromFirestore(doc))
              .toList();

          // Sort by completedAt date
          challenges.sort((a, b) {
            if (a.completedAt == null) return 1;
            if (b.completedAt == null) return -1;
            return b.completedAt!.compareTo(a.completedAt!);
          });

          return challenges;
        });
  }

  // Mark a challenge as notified to the sender
  Future<void> markChallengeAsNotified(String challengeId) async {
    try {
      await _firestore.collection(_challengesCollectionPath).doc(challengeId).update({
        'notifiedSender': true,
      });
    } catch (e) {
      debugPrint('Error marking challenge as notified: $e');
      rethrow;
    }
  }
}
