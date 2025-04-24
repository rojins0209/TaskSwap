import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/friend_request_model.dart';
import 'package:taskswap/models/user_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _userCollectionPath = 'users';
  final String _friendRequestsCollectionPath = 'friendRequests';

  // Send a friend request
  Future<void> sendFriendRequest(String toUserId) async {
    try {
      debugPrint('Starting sendFriendRequest to user: $toUserId');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Current user is null');
        throw Exception('User not authenticated');
      }

      debugPrint('Current user ID: ${currentUser.uid}');
      debugPrint('Recipient user ID: $toUserId');

      // First, let's verify both user documents exist and create them if they don't
      // Check current user document
      final currentUserDocRef = _firestore.collection(_userCollectionPath).doc(currentUser.uid);
      final currentUserDoc = await currentUserDocRef.get();

      if (!currentUserDoc.exists) {
        debugPrint('Creating current user document');
        // Create current user document
        await currentUserDocRef.set({
          'email': currentUser.email ?? '',
          'auraPoints': 0,
          'completedTasks': 0,
          'totalTasks': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'friendRequests': [],
        });
      } else {
        debugPrint('Current user document exists');
      }

      // Get the updated current user document
      final updatedCurrentUserDoc = await currentUserDocRef.get();
      final currentUserData = updatedCurrentUserDoc.data() as Map<String, dynamic>;
      final List<dynamic> friends = currentUserData['friends'] ?? [];

      // Check if users are already friends
      if (friends.contains(toUserId)) {
        debugPrint('Users are already friends');
        throw Exception('Users are already friends');
      }

      // Check recipient user document
      final toUserDocRef = _firestore.collection(_userCollectionPath).doc(toUserId);
      final toUserDoc = await toUserDocRef.get();

      if (!toUserDoc.exists) {
        debugPrint('Recipient user document does not exist, creating it');
        // Create recipient user document
        await toUserDocRef.set({
          'email': '', // We don't know the email
          'auraPoints': 0,
          'completedTasks': 0,
          'totalTasks': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'friendRequests': [currentUser.uid], // Add current user to friend requests
        });
        debugPrint('Recipient user document created with friend request');
      } else {
        debugPrint('Recipient user document exists, updating friendRequests');
        // Update recipient's friendRequests array
        await toUserDocRef.update({
          'friendRequests': FieldValue.arrayUnion([currentUser.uid]),
        });
        debugPrint('Recipient friendRequests updated');
      }

      // Check if a friend request already exists in the friendRequests collection
      debugPrint('Checking for existing friend requests');
      final existingRequests = await _firestore
          .collection(_friendRequestsCollectionPath)
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequests.docs.isNotEmpty) {
        debugPrint('Friend request already exists in collection');
        // Friend request already exists in the collection, but we've already updated the user document
        // So we'll just return without an error
        return;
      }

      // Create a new friend request document
      debugPrint('Creating new friend request document');
      final friendRequest = FriendRequest(
        fromUserId: currentUser.uid,
        toUserId: toUserId,
      );

      await _firestore.collection(_friendRequestsCollectionPath).add(friendRequest.toMap());
      debugPrint('Friend request document created successfully');

      debugPrint('Friend request sent successfully');
    } catch (e) {
      debugPrint('Error in sendFriendRequest: $e');
      rethrow;
    }
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the friend request
      final requestsQuery = await _firestore
          .collection(_friendRequestsCollectionPath)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (requestsQuery.docs.isEmpty) {
        throw Exception('Friend request not found');
      }

      // Update the friend request status
      final requestDoc = requestsQuery.docs.first;
      await _firestore.collection(_friendRequestsCollectionPath).doc(requestDoc.id).update({
        'status': 'accepted',
      });

      // Check if current user document exists
      final currentUserDoc = await _firestore.collection(_userCollectionPath).doc(currentUser.uid).get();

      if (currentUserDoc.exists) {
        // Update current user's friends list
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).update({
          'friends': FieldValue.arrayUnion([fromUserId]),
          'friendRequests': FieldValue.arrayRemove([fromUserId]),
        });
      } else {
        // Create current user document if it doesn't exist
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).set({
          'email': currentUser.email ?? '',
          'auraPoints': 0,
          'completedTasks': 0,
          'totalTasks': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [fromUserId],
          'friendRequests': [],
        });
      }

      // Check if friend's user document exists
      final fromUserDoc = await _firestore.collection(_userCollectionPath).doc(fromUserId).get();

      if (fromUserDoc.exists) {
        // Update friend's friends list
        await _firestore.collection(_userCollectionPath).doc(fromUserId).update({
          'friends': FieldValue.arrayUnion([currentUser.uid]),
        });
      } else {
        // Create friend's user document if it doesn't exist
        await _firestore.collection(_userCollectionPath).doc(fromUserId).set({
          'email': '', // We don't know the email
          'auraPoints': 0,
          'completedTasks': 0,
          'totalTasks': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [currentUser.uid],
          'friendRequests': [],
        });
      }
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Reject a friend request
  Future<void> rejectFriendRequest(String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the friend request
      final requestsQuery = await _firestore
          .collection(_friendRequestsCollectionPath)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (requestsQuery.docs.isEmpty) {
        throw Exception('Friend request not found');
      }

      // Update the friend request status
      final requestDoc = requestsQuery.docs.first;
      await _firestore.collection(_friendRequestsCollectionPath).doc(requestDoc.id).update({
        'status': 'rejected',
      });

      // Check if current user document exists
      final currentUserDoc = await _firestore.collection(_userCollectionPath).doc(currentUser.uid).get();

      if (currentUserDoc.exists) {
        // Remove from friendRequests array
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).update({
          'friendRequests': FieldValue.arrayRemove([fromUserId]),
        });
      } else {
        // Create current user document if it doesn't exist
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).set({
          'email': currentUser.email ?? '',
          'auraPoints': 0,
          'completedTasks': 0,
          'totalTasks': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'friendRequests': [],
        });
      }
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      rethrow;
    }
  }

  // Remove a friend
  Future<void> removeFriend(String friendId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user document exists
      final currentUserDoc = await _firestore.collection(_userCollectionPath).doc(currentUser.uid).get();

      if (currentUserDoc.exists) {
        // Remove friend from current user's friends list
        await _firestore.collection(_userCollectionPath).doc(currentUser.uid).update({
          'friends': FieldValue.arrayRemove([friendId]),
        });
      }

      // Check if friend's user document exists
      final friendDoc = await _firestore.collection(_userCollectionPath).doc(friendId).get();

      if (friendDoc.exists) {
        // Remove current user from friend's friends list
        await _firestore.collection(_userCollectionPath).doc(friendId).update({
          'friends': FieldValue.arrayRemove([currentUser.uid]),
        });
      }
    } catch (e) {
      debugPrint('Error removing friend: $e');
      rethrow;
    }
  }

  // Get all friends of the current user
  Stream<List<UserModel>> getFriends() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_userCollectionPath)
        .doc(currentUser.uid)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists) {
            return [];
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final List<dynamic> friendIds = userData['friends'] ?? [];

          if (friendIds.isEmpty) {
            return [];
          }

          // Get all friends' user documents
          final friendsQuery = await _firestore
              .collection(_userCollectionPath)
              .where(FieldPath.documentId, whereIn: friendIds.cast<String>())
              .get();

          return friendsQuery.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        });
  }

  // Get all pending friend requests for the current user
  Stream<List<FriendRequest>> getPendingFriendRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_friendRequestsCollectionPath)
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList());
  }

  // Search for users by email
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      if (email.isEmpty) {
        return [];
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Get users whose email starts with the search term
      final usersQuery = await _firestore
          .collection(_userCollectionPath)
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThanOrEqualTo: '$email\uf8ff')
          .get();

      // Filter out the current user
      return usersQuery.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.id != currentUser.uid)
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Get user details by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection(_userCollectionPath).doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }
}
