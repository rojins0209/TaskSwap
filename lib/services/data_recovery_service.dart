import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/user_model.dart';

class DataRecoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _userCollectionPath = 'users';
  final String _friendRequestsCollectionPath = 'friendRequests';
  final String _activitiesCollectionPath = 'activities';
  final String _tasksCollectionPath = 'tasks';
  final String _challengesCollectionPath = 'challenges';

  // Diagnose database issues
  Future<Map<String, dynamic>> diagnoseDatabase() async {
    final result = <String, dynamic>{};
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      result['error'] = 'User not authenticated';
      return result;
    }

    try {
      // Check user document
      final userDoc = await _firestore.collection(_userCollectionPath).doc(currentUser.uid).get();
      result['userDocExists'] = userDoc.exists;
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        result['userData'] = userData;
        result['friendsCount'] = userData?['friends']?.length ?? 0;
      }

      // Check tasks
      final tasksQuery = await _firestore
          .collection(_tasksCollectionPath)
          .where('createdBy', isEqualTo: currentUser.uid)
          .get();
      result['tasksCount'] = tasksQuery.docs.length;

      // Check challenges
      final challengesQuery = await _firestore
          .collection(_challengesCollectionPath)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .get();
      result['sentChallengesCount'] = challengesQuery.docs.length;

      final receivedChallengesQuery = await _firestore
          .collection(_challengesCollectionPath)
          .where('toUserId', isEqualTo: currentUser.uid)
          .get();
      result['receivedChallengesCount'] = receivedChallengesQuery.docs.length;

      // Check activities
      final activitiesQuery = await _firestore
          .collection(_activitiesCollectionPath)
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      result['activitiesCount'] = activitiesQuery.docs.length;

      // Check friend requests
      final friendRequestsQuery = await _firestore
          .collection(_friendRequestsCollectionPath)
          .where('toUserId', isEqualTo: currentUser.uid)
          .get();
      result['friendRequestsCount'] = friendRequestsQuery.docs.length;

      // Check Firestore connection
      result['firestoreConnection'] = 'OK';

      return result;
    } catch (e) {
      debugPrint('Error diagnosing database: $e');
      result['error'] = e.toString();
      return result;
    }
  }

  // Repair user document if it's missing or corrupted
  Future<bool> repairUserDocument() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      final userDoc = await _firestore.collection(_userCollectionPath).doc(currentUser.uid).get();
      
      // If user document doesn't exist, create it
      if (!userDoc.exists) {
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).set({
          'email': currentUser.email ?? '',
          'displayName': currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User',
          'photoUrl': currentUser.photoURL,
          'auraPoints': 0,
          'streakCount': 0,
          'completedTasks': 0,
          'totalTasks': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastPointsEarnedAt': FieldValue.serverTimestamp(),
          'friends': [],
          'friendRequests': [],
          'auraVisibility': 'public',
          'allowAuraFrom': 'everyone',
        });
        return true;
      }
      
      // If user document exists but might be missing fields, update it
      final userData = userDoc.data() as Map<String, dynamic>;
      final updates = <String, dynamic>{};
      
      if (!userData.containsKey('email') || userData['email'] == null) {
        updates['email'] = currentUser.email ?? '';
      }
      
      if (!userData.containsKey('displayName') || userData['displayName'] == null) {
        updates['displayName'] = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
      }
      
      if (!userData.containsKey('photoUrl')) {
        updates['photoUrl'] = currentUser.photoURL;
      }
      
      if (!userData.containsKey('auraPoints')) {
        updates['auraPoints'] = 0;
      }
      
      if (!userData.containsKey('streakCount')) {
        updates['streakCount'] = 0;
      }
      
      if (!userData.containsKey('completedTasks')) {
        updates['completedTasks'] = 0;
      }
      
      if (!userData.containsKey('totalTasks')) {
        updates['totalTasks'] = 0;
      }
      
      if (!userData.containsKey('createdAt')) {
        updates['createdAt'] = FieldValue.serverTimestamp();
      }
      
      if (!userData.containsKey('lastPointsEarnedAt')) {
        updates['lastPointsEarnedAt'] = FieldValue.serverTimestamp();
      }
      
      if (!userData.containsKey('friends')) {
        updates['friends'] = [];
      }
      
      if (!userData.containsKey('friendRequests')) {
        updates['friendRequests'] = [];
      }
      
      if (!userData.containsKey('auraVisibility')) {
        updates['auraVisibility'] = 'public';
      }
      
      if (!userData.containsKey('allowAuraFrom')) {
        updates['allowAuraFrom'] = 'everyone';
      }
      
      if (updates.isNotEmpty) {
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).update(updates);
        return true;
      }
      
      return false; // No repairs needed
    } catch (e) {
      debugPrint('Error repairing user document: $e');
      return false;
    }
  }

  // Rebuild friends list from friend requests
  Future<int> rebuildFriendsList() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 0;
    }

    try {
      // Get all accepted friend requests where the current user is either the sender or receiver
      final sentRequestsQuery = await _firestore
          .collection(_friendRequestsCollectionPath)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();
          
      final receivedRequestsQuery = await _firestore
          .collection(_friendRequestsCollectionPath)
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      // Extract friend IDs
      final friendIds = <String>{};
      
      for (final doc in sentRequestsQuery.docs) {
        final data = doc.data();
        if (data['toUserId'] != null) {
          friendIds.add(data['toUserId'] as String);
        }
      }
      
      for (final doc in receivedRequestsQuery.docs) {
        final data = doc.data();
        if (data['fromUserId'] != null) {
          friendIds.add(data['fromUserId'] as String);
        }
      }
      
      // Update the user's friends list
      if (friendIds.isNotEmpty) {
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).update({
          'friends': friendIds.toList(),
        });
        
        // Also update each friend's friends list to include the current user
        for (final friendId in friendIds) {
          await _firestore.collection(_userCollectionPath).doc(friendId).update({
            'friends': FieldValue.arrayUnion([currentUser.uid]),
          });
        }
      }
      
      return friendIds.length;
    } catch (e) {
      debugPrint('Error rebuilding friends list: $e');
      return -1;
    }
  }

  // Recalculate user stats (aura points, completed tasks, etc.)
  Future<bool> recalculateUserStats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      // Get all completed tasks
      final tasksQuery = await _firestore
          .collection(_tasksCollectionPath)
          .where('createdBy', isEqualTo: currentUser.uid)
          .get();
      
      int completedTasks = 0;
      int totalTasks = tasksQuery.docs.length;
      int totalPoints = 0;
      
      for (final doc in tasksQuery.docs) {
        final data = doc.data();
        if (data['isCompleted'] == true) {
          completedTasks++;
          if (data['points'] != null) {
            totalPoints += (data['points'] as num).toInt();
          }
        }
      }
      
      // Get all completed challenges
      final challengesQuery = await _firestore
          .collection(_challengesCollectionPath)
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'completed')
          .get();
      
      for (final doc in challengesQuery.docs) {
        final data = doc.data();
        if (data['points'] != null) {
          totalPoints += (data['points'] as num).toInt();
        }
      }
      
      // Update user stats
      await _firestore.collection(_userCollectionPath).doc(currentUser.uid).update({
        'completedTasks': completedTasks,
        'totalTasks': totalTasks,
        'auraPoints': totalPoints,
        'lastPointsEarnedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error recalculating user stats: $e');
      return false;
    }
  }

  // Full recovery process
  Future<Map<String, dynamic>> performFullRecovery() async {
    final result = <String, dynamic>{};
    
    try {
      // Step 1: Diagnose the database
      final diagnosis = await diagnoseDatabase();
      result['diagnosis'] = diagnosis;
      
      // Step 2: Repair user document
      final userRepaired = await repairUserDocument();
      result['userRepaired'] = userRepaired;
      
      // Step 3: Rebuild friends list
      final friendsCount = await rebuildFriendsList();
      result['friendsRebuilt'] = friendsCount;
      
      // Step 4: Recalculate user stats
      final statsRecalculated = await recalculateUserStats();
      result['statsRecalculated'] = statsRecalculated;
      
      result['success'] = true;
      return result;
    } catch (e) {
      debugPrint('Error performing full recovery: $e');
      result['error'] = e.toString();
      result['success'] = false;
      return result;
    }
  }
}
