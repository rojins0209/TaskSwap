import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/follower_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/activity_service.dart';

class FollowerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionPath = 'followers';
  final String _userCollectionPath = 'users';
  ActivityService? _activityService;

  // Lazy initialize activity service to avoid circular dependency
  ActivityService get activityService {
    _activityService ??= ActivityService();
    return _activityService!;
  }

  // Follow a user
  Future<void> followUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if already following
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('followerId', isEqualTo: currentUser.uid)
          .where('followedId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Already following
        return;
      }

      // Create follower relation
      final followerRelation = FollowerRelation(
        followerId: currentUser.uid,
        followedId: userId,
      );

      await _firestore.collection(_collectionPath).add(followerRelation.toMap());

      // Create activity for the follow
      await activityService.createFriendAddedActivity(
        userId: currentUser.uid,
        friendId: userId,
      );
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the follower relation
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('followerId', isEqualTo: currentUser.uid)
          .where('followedId', isEqualTo: userId)
          .get();

      // Delete all matching documents (should be only one)
      for (var doc in querySnapshot.docs) {
        await _firestore.collection(_collectionPath).doc(doc.id).delete();
      }
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  // Check if the current user is following a specific user
  Future<bool> isFollowing(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('followerId', isEqualTo: currentUser.uid)
          .where('followedId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if following: $e');
      return false;
    }
  }

  // Get users that the current user is following
  Stream<List<UserModel>> getFollowedUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .where('followerId', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final followedIds = snapshot.docs
              .map((doc) => FollowerRelation.fromFirestore(doc).followedId)
              .toList();

          if (followedIds.isEmpty) {
            return [];
          }

          // Get user documents for all followed users
          final userDocs = await _firestore
              .collection(_userCollectionPath)
              .where(FieldPath.documentId, whereIn: followedIds)
              .get();

          return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        });
  }

  // Get users who are following the current user
  Stream<List<UserModel>> getFollowers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionPath)
        .where('followedId', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final followerIds = snapshot.docs
              .map((doc) => FollowerRelation.fromFirestore(doc).followerId)
              .toList();

          if (followerIds.isEmpty) {
            return [];
          }

          // Get user documents for all followers
          final userDocs = await _firestore
              .collection(_userCollectionPath)
              .where(FieldPath.documentId, whereIn: followerIds)
              .get();

          return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        });
  }

  // Get users who are following a specific user
  Stream<List<UserModel>> getUserFollowers(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('followedId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final followerIds = snapshot.docs
              .map((doc) => FollowerRelation.fromFirestore(doc).followerId)
              .toList();

          if (followerIds.isEmpty) {
            return [];
          }

          // Get user documents for all followers
          final userDocs = await _firestore
              .collection(_userCollectionPath)
              .where(FieldPath.documentId, whereIn: followerIds)
              .get();

          return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        });
  }

  // Get users that a specific user is following
  Stream<List<UserModel>> getUserFollowing(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final followedIds = snapshot.docs
              .map((doc) => FollowerRelation.fromFirestore(doc).followedId)
              .toList();

          if (followedIds.isEmpty) {
            return [];
          }

          // Get user documents for all followed users
          final userDocs = await _firestore
              .collection(_userCollectionPath)
              .where(FieldPath.documentId, whereIn: followedIds)
              .get();

          return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        });
  }

  // Get follower count for a user
  Stream<int> getFollowerCount(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('followedId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get following count for a user
  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
