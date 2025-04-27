import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/notification_service.dart';
import 'package:taskswap/services/cache_service.dart';
import 'package:taskswap/services/widget_service.dart';

// Time filter options for leaderboard
enum TimeFilter { allTime, monthly, weekly }

// Aura visibility options
enum AuraVisibility { public, friends, private }

// Allow aura from options
enum AllowAuraFrom { everyone, friends, none }

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionPath = 'users';
  final NotificationService _notificationService = NotificationService();
  final WidgetService _widgetService = WidgetService();

  // Create a new user
  Future<void> createUser(String userId, String email) async {
    try {
      final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

      // Only create if user doesn't exist
      if (!userDoc.exists) {
        // Extract display name from email (before the @ symbol)
        String? displayName;
        if (email.isNotEmpty && email.contains('@')) {
          displayName = email.split('@')[0];
          // Capitalize first letter of each word
          displayName = displayName.split('.').map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
          ).join(' ');
        }

        final user = UserModel(
          id: userId,
          email: email,
          displayName: displayName,
          photoUrl: null,
          auraPoints: 0,
          streakCount: 0,
          completedTasks: 0,
          totalTasks: 0,
        );

        await _firestore.collection(_collectionPath).doc(userId).set(user.toMap());
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Get user by ID with enhanced caching
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check cache first
      final cacheKey = 'user_$userId';
      final cachedData = await CacheService.getFromCache(cacheKey);

      if (cachedData != null) {
        debugPrint('Retrieved user $userId from cache');
        return UserModel.fromMap(cachedData);
      }

      // If not in cache, get from Firestore
      DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);

        // Save to cache for 1 hour (longer cache time for user data)
        await CacheService.saveToCache(
          cacheKey,
          user.toMap(),
          expiry: const Duration(hours: 1)
        );

        // Update widget data
        try {
          _widgetService.updateUserStatsWidget(user);
        } catch (e) {
          debugPrint('Error updating widget data: $e');
          // Continue execution even if widget update fails
        }

        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      // Return cached data if available, even if it's expired
      try {
        final cacheKey = 'user_$userId';
        final cachedData = await CacheService.getFromCache(cacheKey);
        if (cachedData != null) {
          debugPrint('Returning expired cached user data due to error');
          return UserModel.fromMap(cachedData);
        }
      } catch (_) {
        // Ignore cache errors
      }
      rethrow;
    }
  }

  // Prefetch user data for faster access
  Future<void> prefetchUserData(String userId) async {
    try {
      // Check if we already have this user in cache
      final cacheKey = 'user_$userId';
      final cachedData = await CacheService.getFromCache(cacheKey);

      if (cachedData != null) {
        // Already cached, no need to prefetch
        return;
      }

      // Fetch user data and cache it
      final user = await getUserById(userId);
      if (user != null) {
        debugPrint('Prefetched user data for $userId');
      }
    } catch (e) {
      debugPrint('Error prefetching user data: $e');
    }
  }

  // Get user's friends with caching
  Future<List<UserModel>> getFriendsList(String userId) async {
    try {
      // Check cache first
      final cacheKey = 'friends_$userId';
      final cachedData = await CacheService.getFromCache(cacheKey);

      if (cachedData != null && cachedData is List) {
        debugPrint('Retrieved friends list for $userId from cache');
        final List<UserModel> cachedFriends = [];
        for (final userData in cachedData) {
          if (userData is Map<String, dynamic>) {
            try {
              final user = UserModel.fromMap(userData);
              cachedFriends.add(user);
            } catch (e) {
              debugPrint('Error parsing cached friend data: $e');
            }
          }
        }

        if (cachedFriends.isNotEmpty) {
          return cachedFriends;
        }
      }

      // Get the user document to access the friends list
      final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> friendIds = List<String>.from(userData['friends'] ?? []);

      if (friendIds.isEmpty) {
        return [];
      }

      // Get friend user documents
      final List<UserModel> friends = [];

      // Process in batches of 10 to avoid Firestore limitations
      for (int i = 0; i < friendIds.length; i += 10) {
        final end = (i + 10 < friendIds.length) ? i + 10 : friendIds.length;
        final batch = friendIds.sublist(i, end);

        final snapshot = await _firestore
            .collection(_collectionPath)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          friends.add(UserModel.fromFirestore(doc));
        }
      }

      // Cache the results
      await CacheService.saveToCache(
        cacheKey,
        friends.map((friend) => friend.toMap()).toList(),
        expiry: const Duration(minutes: 15)
      );

      return friends;
    } catch (e) {
      debugPrint('Error getting friends list: $e');
      return [];
    }
  }

  // Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(_collectionPath)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // This method is now handled directly in TaskService.markTaskAsCompleted
  // to avoid race conditions and ensure atomic updates
  //
  // // Update user aura points
  // Future<void> updateUserAuraPoints(String userId, int pointsToAdd) async {
  //   // Implementation removed
  // }

  // Increment total tasks count
  Future<void> incrementTotalTasks(String userId) async {
    try {
      // Get a reference to the user document
      final userRef = _firestore.collection(_collectionPath).doc(userId);

      // Check if the document exists
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        // If the document exists, increment the totalTasks field
        await userRef.update({
          'totalTasks': FieldValue.increment(1),
        });
      } else {
        // If the document doesn't exist, create it with initial values
        // Get the user's email from Firebase Auth if possible
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
        await userRef.set({
          'email': email,
          'auraPoints': 0,
          'completedTasks': 0,
          'totalTasks': 1, // Start with 1 since this is the first task
          'createdAt': FieldValue.serverTimestamp(),
          'friends': [],
          'friendRequests': [],
        });
      }
    } catch (e) {
      debugPrint('Error incrementing total tasks: $e');
      rethrow;
    }
  }

  // Get top users by aura points (for leaderboard) with caching
  Stream<List<UserModel>> getTopUsersByAuraPoints(int limit, {TimeFilter timeFilter = TimeFilter.allTime}) {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final cacheKey = 'leaderboard_${timeFilter.toString()}_$limit';

      // Check cache first for faster initial load
      _checkLeaderboardCache(cacheKey, limit, timeFilter);

      // Create a StreamController to manage the stream
      final controller = StreamController<List<UserModel>>();

      // Process asynchronously
      Future<void> process() async {
        try {
          // Start with a basic query without visibility filter
          // We'll filter the results manually after fetching
          Query query = _firestore.collection(_collectionPath);

          // Debug log
          debugPrint('Fetching users for Everyone leaderboard - limit: $limit');

          // Apply time filter
          if (timeFilter != TimeFilter.allTime) {
            // Calculate the start date based on the time filter
            DateTime startDate;
            final now = DateTime.now();

            if (timeFilter == TimeFilter.weekly) {
              // Start of the current week (Monday)
              startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
            } else if (timeFilter == TimeFilter.monthly) {
              // Start of the current month
              startDate = DateTime(now.year, now.month, 1);
            } else {
              // Default to all-time (no filter)
              startDate = DateTime(2000, 1, 1);
            }

            // Convert to Timestamp for Firestore query
            final startTimestamp = Timestamp.fromDate(startDate);

            // Query for tasks completed within the time period
            query = query.where('lastPointsEarnedAt', isGreaterThanOrEqualTo: startTimestamp);

            try {
              // Order by lastPointsEarnedAt first, then by auraPoints
              final snapshot = await query
                  .orderBy('lastPointsEarnedAt', descending: true)
                  .orderBy('auraPoints', descending: true)
                  .limit(limit * 2) // Get more users to filter
                  .get();

              // Filter users based on privacy settings
              List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
              List<UserModel> filteredUsers = [];

              // If user is logged in, filter based on privacy settings
              if (currentUser != null) {
                for (final user in users) {
                  // Always include the current user
                  if (user.id == currentUser.uid) {
                    filteredUsers.add(user);
                    continue;
                  }

                  // Include public users
                  if (user.auraVisibility == AuraVisibility.public) {
                    filteredUsers.add(user);
                    continue;
                  }

                  // Include friends-only users if the current user is a friend
                  if (user.auraVisibility == AuraVisibility.friends && user.friends.contains(currentUser.uid)) {
                    filteredUsers.add(user);
                    continue;
                  }
                }
              } else {
                // If not logged in, only include public users
                filteredUsers = users.where((user) => user.auraVisibility == AuraVisibility.public).toList();
              }

              // Limit to the requested number of users
              if (filteredUsers.length > limit) {
                filteredUsers = filteredUsers.sublist(0, limit);
              }

              controller.add(filteredUsers);

              // Set up a stream subscription to keep updating the leaderboard
              final subscription = query
                  .orderBy('lastPointsEarnedAt', descending: true)
                  .orderBy('auraPoints', descending: true)
                  .limit(limit * 2)
                  .snapshots()
                  .listen((snapshot) async {
                    List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
                    List<UserModel> filteredUsers = [];

                    // Filter users based on privacy settings
                    if (currentUser != null) {
                      for (final user in users) {
                        // Always include the current user
                        if (user.id == currentUser.uid) {
                          filteredUsers.add(user);
                          continue;
                        }

                        // Include public users
                        if (user.auraVisibility == AuraVisibility.public) {
                          filteredUsers.add(user);
                          continue;
                        }

                        // Include friends-only users if the current user is a friend
                        if (user.auraVisibility == AuraVisibility.friends && user.friends.contains(currentUser.uid)) {
                          filteredUsers.add(user);
                          continue;
                        }
                      }
                    } else {
                      // If not logged in, only include public users
                      filteredUsers = users.where((user) => user.auraVisibility == AuraVisibility.public).toList();
                    }

                    // Limit to the requested number of users
                    if (filteredUsers.length > limit) {
                      filteredUsers = filteredUsers.sublist(0, limit);
                    }

                    controller.add(filteredUsers);
                  });

              // Close the controller when the stream is done
              controller.onCancel = () {
                subscription.cancel();
              };
            } catch (error) {
              // If we get an index error, fall back to all-time leaderboard
              debugPrint('Error in time-filtered leaderboard: $error');
              debugPrint('Falling back to all-time leaderboard');

              // Fall back to all-time query without visibility filter
              // We'll filter the results manually after fetching
              final fallbackQuery = _firestore.collection(_collectionPath)
                  .orderBy('auraPoints', descending: true)
                  .limit(limit * 5); // Increased from 2x to 5x

              debugPrint('Using fallback query for all users with limit: ${limit * 5}');

              final snapshot = await fallbackQuery.get();

              // Filter users based on privacy settings
              List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
              List<UserModel> filteredUsers = [];

              // If user is logged in, filter based on privacy settings
              if (currentUser != null) {
                for (final user in users) {
                  // Always include the current user
                  if (user.id == currentUser.uid) {
                    filteredUsers.add(user);
                    continue;
                  }

                  // Include public users
                  if (user.auraVisibility == AuraVisibility.public) {
                    filteredUsers.add(user);
                    continue;
                  }

                  // Include friends-only users if the current user is a friend
                  if (user.auraVisibility == AuraVisibility.friends && user.friends.contains(currentUser.uid)) {
                    filteredUsers.add(user);
                    continue;
                  }
                }
              } else {
                // If not logged in, only include public users
                filteredUsers = users.where((user) => user.auraVisibility == AuraVisibility.public).toList();
              }

              // Limit to the requested number of users
              if (filteredUsers.length > limit) {
                filteredUsers = filteredUsers.sublist(0, limit);
              }

              controller.add(filteredUsers);

              // Set up a stream subscription to keep updating the leaderboard
              final subscription = fallbackQuery
                  .snapshots()
                  .listen((snapshot) async {
                    List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
                    List<UserModel> filteredUsers = [];

                    // Filter users based on privacy settings
                    if (currentUser != null) {
                      for (final user in users) {
                        // Always include the current user
                        if (user.id == currentUser.uid) {
                          filteredUsers.add(user);
                          continue;
                        }

                        // Include public users
                        if (user.auraVisibility == AuraVisibility.public) {
                          filteredUsers.add(user);
                          continue;
                        }

                        // Include friends-only users if the current user is a friend
                        if (user.auraVisibility == AuraVisibility.friends && user.friends.contains(currentUser.uid)) {
                          filteredUsers.add(user);
                          continue;
                        }
                      }
                    } else {
                      // If not logged in, only include public users
                      filteredUsers = users.where((user) => user.auraVisibility == AuraVisibility.public).toList();
                    }

                    // Limit to the requested number of users
                    if (filteredUsers.length > limit) {
                      filteredUsers = filteredUsers.sublist(0, limit);
                    }

                    controller.add(filteredUsers);
                  });

              // Close the controller when the stream is done
              controller.onCancel = () {
                subscription.cancel();
              };
            }
          } else {
            // For all-time, just order by aura points
            try {
              final snapshot = await query
                  .orderBy('auraPoints', descending: true)
                  .limit(limit * 5) // Get more users to filter (increased from 2x to 5x)
                  .get();

              // Filter users based on privacy settings
              List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
              List<UserModel> filteredUsers = [];

              debugPrint('Retrieved ${users.length} users from Firestore for all-time leaderboard');

              // If user is logged in, filter based on privacy settings
              if (currentUser != null) {
                for (final user in users) {
                  // Always include the current user
                  if (user.id == currentUser.uid) {
                    filteredUsers.add(user);
                    debugPrint('Including current user: ${user.email}');
                    continue;
                  }

                  // The UserModel already sets a default of AuraVisibility.public
                  // so we don't need to check for null

                  // Include public users
                  if (user.auraVisibility == AuraVisibility.public) {
                    filteredUsers.add(user);
                    debugPrint('Including public user: ${user.email}');
                    continue;
                  }

                  // Include friends-only users if the current user is a friend
                  if (user.auraVisibility == AuraVisibility.friends && user.friends.contains(currentUser.uid)) {
                    filteredUsers.add(user);
                    debugPrint('Including friend user: ${user.email}');
                    continue;
                  }
                }
              } else {
                // If not logged in, include public users
                filteredUsers = users.where((user) =>
                  user.auraVisibility == AuraVisibility.public
                ).toList();
                debugPrint('Not logged in, including ${filteredUsers.length} public users');
              }

              debugPrint('Filtered to ${filteredUsers.length} users for all-time leaderboard');

              // Limit to the requested number of users
              if (filteredUsers.length > limit) {
                filteredUsers = filteredUsers.sublist(0, limit);
              }

              // Save to cache before adding to stream
              CacheService.saveToCache(
                cacheKey,
                filteredUsers.map((user) => user.toMap()).toList(),
                expiry: const Duration(minutes: 5)
              ).then((_) {
                controller.add(filteredUsers);
              });

              // Set up a stream subscription to keep updating the leaderboard
              final subscription = query
                  .orderBy('auraPoints', descending: true)
                  .limit(limit * 5) // Increased from 2x to 5x to match initial query
                  .snapshots()
                  .listen((snapshot) async {
                    List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
                    List<UserModel> filteredUsers = [];

                    // Filter users based on privacy settings
                    if (currentUser != null) {
                      for (final user in users) {
                        // Always include the current user
                        if (user.id == currentUser.uid) {
                          filteredUsers.add(user);
                          continue;
                        }

                        // Include public users
                        if (user.auraVisibility == AuraVisibility.public) {
                          filteredUsers.add(user);
                          continue;
                        }

                        // Include friends-only users if the current user is a friend
                        if (user.auraVisibility == AuraVisibility.friends && user.friends.contains(currentUser.uid)) {
                          filteredUsers.add(user);
                          continue;
                        }
                      }
                    } else {
                      // If not logged in, only include public users
                      filteredUsers = users.where((user) => user.auraVisibility == AuraVisibility.public).toList();
                    }

                    // Limit to the requested number of users
                    if (filteredUsers.length > limit) {
                      filteredUsers = filteredUsers.sublist(0, limit);
                    }

                    // Update cache with latest data
                    CacheService.saveToCache(
                      cacheKey,
                      filteredUsers.map((user) => user.toMap()).toList(),
                      expiry: const Duration(minutes: 5)
                    ).then((_) {
                      controller.add(filteredUsers);
                    });
                  });

              // Close the controller when the stream is done
              controller.onCancel = () {
                subscription.cancel();
              };
            } catch (error) {
              debugPrint('Error in all-time leaderboard: $error');
              controller.add([]);
              await controller.close();
            }
          }
        } catch (e) {
          debugPrint('Error getting leaderboard: $e');
          controller.add([]);
          await controller.close();
        }
      }

      // Start the processing
      process();

      // Return the stream from the controller
      return controller.stream;
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
  }

  // Get top users by aura points among friends
  Stream<List<UserModel>> getTopFriendsByAuraPoints(String userId, int limit, {TimeFilter timeFilter = TimeFilter.allTime}) {
    // Create a StreamController to manage the stream
    final controller = StreamController<List<UserModel>>();

    // Process asynchronously
    Future<void> process() async {
      try {
        // Get the current user's friends list
        final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

        if (!userDoc.exists) {
          controller.add([]);
          await controller.close();
          return;
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final List<String> friendIds = List<String>.from(userData['friends'] ?? []);

        // Add the current user to the list
        friendIds.add(userId);

        if (friendIds.isEmpty || friendIds.length == 1) {
          // If only the current user is in the list (no friends)
          // Just get the current user's data
          final userStream = _firestore
              .collection(_collectionPath)
              .where(FieldPath.documentId, isEqualTo: userId)
              .snapshots()
              .map((snapshot) =>
                  snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());

          // Pipe the user stream to our controller
          userStream.listen(
            (data) => controller.add(data),
            onError: (error) {
              debugPrint('Error getting user data: $error');
              controller.add([]);
            },
            onDone: () => controller.close(),
          );
          return;
        }

        // Create a query to get friends' data
        Query query = _firestore.collection(_collectionPath).where(FieldPath.documentId, whereIn: friendIds);

        // Apply time filter if not all-time
        if (timeFilter != TimeFilter.allTime) {
          try {
            // Calculate the start date based on the time filter
            DateTime startDate;
            final now = DateTime.now();

            if (timeFilter == TimeFilter.weekly) {
              // Start of the current week (Monday)
              startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
            } else if (timeFilter == TimeFilter.monthly) {
              // Start of the current month
              startDate = DateTime(now.year, now.month, 1);
            } else {
              // Default to all-time (no filter)
              startDate = DateTime(2000, 1, 1);
            }

            // Convert to Timestamp for Firestore query
            final startTimestamp = Timestamp.fromDate(startDate);

            // Query for tasks completed within the time period
            query = query.where('lastPointsEarnedAt', isGreaterThanOrEqualTo: startTimestamp);

            // Order by lastPointsEarnedAt first, then by auraPoints
            final timeFilteredStream = query
                .orderBy('lastPointsEarnedAt', descending: true)
                .orderBy('auraPoints', descending: true)
                .limit(limit)
                .snapshots()
                .map((snapshot) =>
                    snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());

            // Pipe the time-filtered stream to our controller
            timeFilteredStream.listen(
              (data) => controller.add(data),
              onError: (error) {
                debugPrint('Error in time-filtered friends leaderboard: $error');
                debugPrint('Falling back to all-time friends leaderboard');

                // Fall back to all-time leaderboard for friends
                final fallbackStream = _firestore
                    .collection(_collectionPath)
                    .where(FieldPath.documentId, whereIn: friendIds)
                    .orderBy('auraPoints', descending: true)
                    .limit(limit)
                    .snapshots()
                    .map((snapshot) =>
                        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());

                fallbackStream.listen(
                  (data) => controller.add(data),
                  onError: (error) {
                    debugPrint('Error in fallback friends leaderboard: $error');
                    controller.add([]);
                  },
                  onDone: () => controller.close(),
                );
              },
              onDone: () => controller.close(),
            );
            return;
          } catch (e) {
            debugPrint('Error setting up time-filtered friends query: $e');
            // Continue with all-time query
          }
        }

        // Order by aura points and limit results (all-time)
        final allTimeStream = query
            .orderBy('auraPoints', descending: true)
            .limit(limit)
            .snapshots()
            .map((snapshot) =>
                snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());

        // Pipe the all-time stream to our controller
        allTimeStream.listen(
          (data) => controller.add(data),
          onError: (error) {
            debugPrint('Error in all-time friends leaderboard: $error');
            controller.add([]);
          },
          onDone: () => controller.close(),
        );
      } catch (e) {
        debugPrint('Error getting friends leaderboard: $e');
        controller.add([]);
        await controller.close();
      }
    }

    // Start the processing
    process();

    // Return the stream from the controller
    return controller.stream;
  }

  // Get the current user's rank based on aura points
  Future<int> getUserRank(String userId) async {
    try {
      // Get the current user's aura points
      final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

      if (!userDoc.exists) {
        return 0; // User not found
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userPoints = userData['auraPoints'] ?? 0;

      // Get all users with more points than the current user
      final usersWithMorePoints = await _firestore
          .collection(_collectionPath)
          .orderBy('auraPoints', descending: true)
          .where('auraPoints', isGreaterThan: userPoints)
          .get();

      // Rank is the number of users with more points + 1
      return usersWithMorePoints.docs.length + 1;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return 0;
    }
  }

  // Get the total number of users
  Future<int> getTotalUsersCount() async {
    try {
      final usersSnapshot = await _firestore
          .collection(_collectionPath)
          .get();

      return usersSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting total users count: $e');
      return 0;
    }
  }

  // Update user streak when they earn aura points
  // Returns milestone data if a milestone was reached, null otherwise
  Future<Map<String, dynamic>?> updateUserStreak(String? userId) async {
    // If userId is null or empty, there's nothing to update
    if (userId == null || userId.isEmpty) {
      debugPrint('Cannot update streak: userId is null or empty');
      return null;
    }
    try {
      // Get a reference to the user document
      final userRef = _firestore.collection(_collectionPath).doc(userId);

      // Use a transaction to ensure atomic updates
      bool streakMilestoneReached = false;
      String? milestoneName;
      int? bonusPoints;
      int? newStreakCount;

      await _firestore.runTransaction((transaction) async {
        // Get the current user data
        DocumentSnapshot userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          // User doesn't exist, nothing to update
          return;
        }

        // Get current user data
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Get current streak count and last aura date
        int currentStreak = userData['streakCount'] ?? 0;
        Timestamp? lastAuraTimestamp = userData['lastAuraDate'];

        // Today's date at midnight (for date comparison)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Initialize new streak count
        int newStreak = 1; // Default to 1 if no previous streak or streak broken

        if (lastAuraTimestamp != null) {
          // Convert timestamp to DateTime
          final lastAuraDate = lastAuraTimestamp.toDate();

          // Get just the date part (no time)
          final lastDate = DateTime(lastAuraDate.year, lastAuraDate.month, lastAuraDate.day);

          // Calculate the difference in days
          final difference = today.difference(lastDate).inDays;

          if (difference == 0) {
            // Already earned aura points today, keep current streak
            newStreak = currentStreak;
            // No need to update the database
            return;
          } else if (difference == 1) {
            // Earned aura points yesterday, increment streak
            newStreak = currentStreak + 1;
          }
          // If difference > 1, streak is broken, reset to 1 (default value)
        }

        // Store the new streak count for returning later
        newStreakCount = newStreak;

        // Update the user document with new streak count and last aura date
        transaction.update(userRef, {
          'streakCount': newStreak,
          'lastAuraDate': Timestamp.fromDate(today),
        });

        // Check for streak milestones
        if (newStreak > currentStreak) { // Only check if streak increased
          if (newStreak == 3) {
            streakMilestoneReached = true;
            milestoneName = '3-Day Streak';
            bonusPoints = 5;

            // Award bonus points
            transaction.update(userRef, {
              'auraPoints': FieldValue.increment(bonusPoints!),
            });
          } else if (newStreak == 7) {
            streakMilestoneReached = true;
            milestoneName = '7-Day Streak';
            bonusPoints = 10;

            // Award bonus points
            transaction.update(userRef, {
              'auraPoints': FieldValue.increment(bonusPoints!),
            });

            // Add streak achievement
            if (!_hasAchievement(userData, 'Streak Master')) {
              List<String> achievements = userData['achievements'] != null ?
                  List<String>.from(userData['achievements']) : [];

              achievements.add('Streak Master');

              transaction.update(userRef, {
                'achievements': achievements,
              });
            }
          } else if (newStreak == 14) {
            streakMilestoneReached = true;
            milestoneName = '14-Day Streak';
            bonusPoints = 20;

            // Award bonus points
            transaction.update(userRef, {
              'auraPoints': FieldValue.increment(bonusPoints!),
            });
          } else if (newStreak == 30) {
            streakMilestoneReached = true;
            milestoneName = '30-Day Streak';
            bonusPoints = 50;

            // Award bonus points
            transaction.update(userRef, {
              'auraPoints': FieldValue.increment(bonusPoints!),
            });

            // Add achievement
            if (!_hasAchievement(userData, 'Streak Champion')) {
              List<String> achievements = userData['achievements'] != null ?
                  List<String>.from(userData['achievements']) : [];

              achievements.add('Streak Champion');

              transaction.update(userRef, {
                'achievements': achievements,
              });
            }
          } else if (newStreak == 100) {
            streakMilestoneReached = true;
            milestoneName = '100-Day Streak';
            bonusPoints = 100;

            // Award bonus points
            transaction.update(userRef, {
              'auraPoints': FieldValue.increment(bonusPoints!),
            });

            // Add achievement
            if (!_hasAchievement(userData, 'Streak Legend')) {
              List<String> achievements = userData['achievements'] != null ?
                  List<String>.from(userData['achievements']) : [];

              achievements.add('Streak Legend');

              transaction.update(userRef, {
                'achievements': achievements,
              });
            }
          } else if (newStreak == 365) {
            streakMilestoneReached = true;
            milestoneName = '365-Day Streak';
            bonusPoints = 500;

            // Award bonus points
            transaction.update(userRef, {
              'auraPoints': FieldValue.increment(bonusPoints!),
            });

            // Add achievement
            if (!_hasAchievement(userData, 'Aura Master')) {
              List<String> achievements = userData['achievements'] != null ?
                  List<String>.from(userData['achievements']) : [];

              achievements.add('Aura Master');

              transaction.update(userRef, {
                'achievements': achievements,
              });
            }
          }
        }
      });

      // Create a notification for the milestone if one was reached
      if (streakMilestoneReached && milestoneName != null && bonusPoints != null) {
        await _notificationService.createMilestoneNotification(
          userId: userId, // userId is guaranteed to be non-null here because we check it at the beginning of the method
          milestone: milestoneName!, // Using ! operator because we've already checked it's not null
          points: bonusPoints,
        );

        // Return milestone data for UI animations
        return {
          'type': 'streak',
          'name': milestoneName,
          'streakCount': newStreakCount,
          'bonusPoints': bonusPoints,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error updating user streak: $e');
      // Don't rethrow - streak updates should not break core functionality
      return null;
    }
  }

  // Check if user has a specific achievement
  bool _hasAchievement(Map<String, dynamic> userData, String achievement) {
    if (userData['achievements'] == null) return false;

    List<String> achievements = List<String>.from(userData['achievements']);
    return achievements.contains(achievement);
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, {String? displayName, String? photoUrl}) async {
    try {
      final updates = <String, dynamic>{};

      if (displayName != null) {
        updates['displayName'] = displayName;
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection(_collectionPath).doc(userId).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Update user privacy settings
  Future<void> updatePrivacySettings(String userId, {
    AuraVisibility? auraVisibility,
    AllowAuraFrom? allowAuraFrom,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (auraVisibility != null) {
        updates['auraVisibility'] = auraVisibility.toString().split('.').last;
      }

      if (allowAuraFrom != null) {
        updates['allowAuraFrom'] = allowAuraFrom.toString().split('.').last;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection(_collectionPath).doc(userId).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      rethrow;
    }
  }

  // Block a user
  Future<void> blockUser(String userId, String userToBlockId) async {
    try {
      // Get the current user's blocked users list
      final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> blockedUsers = List<String>.from(userData['blockedUsers'] ?? []);

      // Check if the user is already blocked
      if (blockedUsers.contains(userToBlockId)) {
        return; // User is already blocked, nothing to do
      }

      // Add the user to the blocked list
      blockedUsers.add(userToBlockId);

      // Update the user document
      await _firestore.collection(_collectionPath).doc(userId).update({
        'blockedUsers': blockedUsers,
      });

      // Also remove from friends list if they are friends
      final List<String> friends = List<String>.from(userData['friends'] ?? []);
      if (friends.contains(userToBlockId)) {
        friends.remove(userToBlockId);
        await _firestore.collection(_collectionPath).doc(userId).update({
          'friends': friends,
        });

        // Also remove the current user from the blocked user's friends list
        final blockedUserDoc = await _firestore.collection(_collectionPath).doc(userToBlockId).get();
        if (blockedUserDoc.exists) {
          final blockedUserData = blockedUserDoc.data() as Map<String, dynamic>;
          final List<String> blockedUserFriends = List<String>.from(blockedUserData['friends'] ?? []);
          if (blockedUserFriends.contains(userId)) {
            blockedUserFriends.remove(userId);
            await _firestore.collection(_collectionPath).doc(userToBlockId).update({
              'friends': blockedUserFriends,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock a user
  Future<void> unblockUser(String userId, String userToUnblockId) async {
    try {
      // Get the current user's blocked users list
      final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> blockedUsers = List<String>.from(userData['blockedUsers'] ?? []);

      // Check if the user is blocked
      if (!blockedUsers.contains(userToUnblockId)) {
        return; // User is not blocked, nothing to do
      }

      // Remove the user from the blocked list
      blockedUsers.remove(userToUnblockId);

      // Update the user document
      await _firestore.collection(_collectionPath).doc(userId).update({
        'blockedUsers': blockedUsers,
      });
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }

  // Helper method to check leaderboard cache and emit cached data to controller
  Future<List<UserModel>?> _checkLeaderboardCache(String cacheKey, int limit, TimeFilter timeFilter) async {
    try {
      final cachedData = await CacheService.getFromCache(cacheKey);
      if (cachedData != null && cachedData is List) {
        debugPrint('Retrieved leaderboard from cache: $cacheKey');

        // Convert cached data to UserModel objects
        final List<UserModel> cachedUsers = [];
        for (final userData in cachedData) {
          if (userData is Map<String, dynamic>) {
            try {
              final user = UserModel.fromMap(userData);
              cachedUsers.add(user);
            } catch (e) {
              debugPrint('Error parsing cached user data: $e');
            }
          }
        }

        if (cachedUsers.isNotEmpty) {
          // Return cached data to be emitted to the controller
          debugPrint('Returning ${cachedUsers.length} cached users for leaderboard');
          return cachedUsers;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error checking leaderboard cache: $e');
      // Continue with normal operation if cache check fails
      return null;
    }
  }

  // Prefetch leaderboard data for faster initial load
  Future<void> prefetchLeaderboardData(int limit, {TimeFilter timeFilter = TimeFilter.allTime}) async {
    try {
      final cacheKey = 'leaderboard_${timeFilter.toString()}_$limit';
      final cachedData = await CacheService.getFromCache(cacheKey);

      if (cachedData != null) {
        // Already cached, no need to prefetch
        return;
      }

      // Get current user for privacy filtering
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Start with a basic query
      Query query = _firestore.collection(_collectionPath);

      // Apply time filter if needed
      if (timeFilter != TimeFilter.allTime) {
        // Calculate the start date based on the time filter
        DateTime startDate;
        final now = DateTime.now();

        if (timeFilter == TimeFilter.weekly) {
          startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
        } else if (timeFilter == TimeFilter.monthly) {
          startDate = DateTime(now.year, now.month, 1);
        } else {
          startDate = DateTime(2000, 1, 1);
        }

        // Convert to Timestamp for Firestore query
        final startTimestamp = Timestamp.fromDate(startDate);
        query = query.where('lastPointsEarnedAt', isGreaterThanOrEqualTo: startTimestamp);
      }

      // Order by points and get data
      final snapshot = await query
          .orderBy('auraPoints', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      // Filter and process users
      List<UserModel> users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      List<UserModel> filteredUsers = [];

      // Filter based on privacy settings
      for (final user in users) {
        // Always include the current user
        if (user.id == currentUser.uid) {
          filteredUsers.add(user);
          continue;
        }

        // Include public users
        if (user.auraVisibility == AuraVisibility.public) {
          filteredUsers.add(user);
          continue;
        }

        // Include friends-only users if the current user is a friend
        if (user.auraVisibility == AuraVisibility.friends && user.friends.contains(currentUser.uid)) {
          filteredUsers.add(user);
          continue;
        }
      }

      // Limit to the requested number of users
      if (filteredUsers.length > limit) {
        filteredUsers = filteredUsers.sublist(0, limit);
      }

      // Cache the filtered users
      if (filteredUsers.isNotEmpty) {
        await CacheService.saveToCache(
          cacheKey,
          filteredUsers.map((user) => user.toMap()).toList(),
          expiry: const Duration(minutes: 10) // Shorter expiry for leaderboard data
        );
        debugPrint('Prefetched and cached leaderboard data: $cacheKey');
      }
    } catch (e) {
      debugPrint('Error prefetching leaderboard data: $e');
    }
  }

  // Get blocked users
  Future<List<UserModel>> getBlockedUsers(String userId) async {
    try {
      // Get the current user's blocked users list
      final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> blockedUserIds = List<String>.from(userData['blockedUsers'] ?? []);

      if (blockedUserIds.isEmpty) {
        return [];
      }

      // Get the user documents for all blocked users
      final blockedUsersSnapshot = await _firestore
          .collection(_collectionPath)
          .where(FieldPath.documentId, whereIn: blockedUserIds)
          .get();

      return blockedUsersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      // Check if userId has blocked otherUserId
      final userDoc = await _firestore.collection(_collectionPath).doc(userId).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<String> blockedUsers = List<String>.from(userData['blockedUsers'] ?? []);

      return blockedUsers.contains(otherUserId);
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Check if user can see another user's aura
  Future<bool> canSeeUserAura(String viewerId, String targetUserId) async {
    try {
      // If viewing own profile, always allow
      if (viewerId == targetUserId) {
        return true;
      }

      // Check if either user has blocked the other
      final isBlocked = await isUserBlocked(viewerId, targetUserId);
      final isBlockedBy = await isUserBlocked(targetUserId, viewerId);

      if (isBlocked || isBlockedBy) {
        return false;
      }

      // Get target user's visibility settings
      final targetUserDoc = await _firestore.collection(_collectionPath).doc(targetUserId).get();

      if (!targetUserDoc.exists) {
        return false;
      }

      final targetUserData = targetUserDoc.data() as Map<String, dynamic>;
      final String visibilitySetting = targetUserData['auraVisibility'] ?? 'public';

      // Parse the visibility setting
      AuraVisibility visibility;
      try {
        visibility = AuraVisibility.values.firstWhere(
          (e) => e.toString().split('.').last == visibilitySetting,
          orElse: () => AuraVisibility.public,
        );
      } catch (_) {
        visibility = AuraVisibility.public; // Default to public if parsing fails
      }

      // Check visibility settings
      switch (visibility) {
        case AuraVisibility.public:
          return true; // Everyone can see
        case AuraVisibility.friends:
          // Check if users are friends
          final List<String> targetUserFriends = List<String>.from(targetUserData['friends'] ?? []);
          return targetUserFriends.contains(viewerId);
        case AuraVisibility.private:
          return false; // Only the user can see
      }
    } catch (e) {
      debugPrint('Error checking if user can see aura: $e');
      return false;
    }
  }

  // Check if user can give aura to another user
  Future<bool> canGiveAuraTo(String giverId, String receiverId) async {
    try {
      // Cannot give aura to self
      if (giverId == receiverId) {
        return false;
      }

      // Check if either user has blocked the other
      final isBlocked = await isUserBlocked(giverId, receiverId);
      final isBlockedBy = await isUserBlocked(receiverId, giverId);

      if (isBlocked || isBlockedBy) {
        return false;
      }

      // Get receiver's aura settings
      final receiverDoc = await _firestore.collection(_collectionPath).doc(receiverId).get();

      if (!receiverDoc.exists) {
        return false;
      }

      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final String allowAuraSetting = receiverData['allowAuraFrom'] ?? 'everyone';

      // Parse the allow aura setting
      AllowAuraFrom allowAura;
      try {
        allowAura = AllowAuraFrom.values.firstWhere(
          (e) => e.toString().split('.').last == allowAuraSetting,
          orElse: () => AllowAuraFrom.everyone,
        );
      } catch (_) {
        allowAura = AllowAuraFrom.everyone; // Default to everyone if parsing fails
      }

      // Check allow aura settings
      switch (allowAura) {
        case AllowAuraFrom.everyone:
          return true; // Anyone can give aura
        case AllowAuraFrom.friends:
          // Check if users are friends
          final List<String> receiverFriends = List<String>.from(receiverData['friends'] ?? []);
          return receiverFriends.contains(giverId);
        case AllowAuraFrom.none:
          return false; // No one can give aura
      }
    } catch (e) {
      debugPrint('Error checking if user can give aura: $e');
      return false;
    }
  }
}
