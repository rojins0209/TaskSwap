import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskswap/services/user_service.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName; // User's display name
  final String? photoUrl; // URL to user's profile photo
  final int auraPoints;
  final DateTime? createdAt;
  final DateTime? lastPointsEarnedAt; // When the user last earned points
  final DateTime? lastAuraDate; // Date of last aura point (for streak calculation)
  final int streakCount; // Current streak count
  final int completedTasks;
  final int totalTasks;
  final List<String> friends;
  final List<String> friendRequests;
  final List<String>? achievements; // User achievements

  // Privacy settings
  final AuraVisibility auraVisibility; // Who can see user's aura points and activities
  final List<String> blockedUsers; // Users blocked by this user
  final AllowAuraFrom allowAuraFrom; // Who can give aura to this user

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.auraPoints = 0,
    this.createdAt,
    this.lastPointsEarnedAt,
    this.lastAuraDate,
    this.streakCount = 0,
    this.completedTasks = 0,
    this.totalTasks = 0,
    this.friends = const [],
    this.friendRequests = const [],
    this.achievements,
    this.auraVisibility = AuraVisibility.public,
    this.blockedUsers = const [],
    this.allowAuraFrom = AllowAuraFrom.everyone,
  });

  // Convert UserModel object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'auraPoints': auraPoints,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastPointsEarnedAt': lastPointsEarnedAt != null ? Timestamp.fromDate(lastPointsEarnedAt!) : null,
      'lastAuraDate': lastAuraDate != null ? Timestamp.fromDate(lastAuraDate!) : null,
      'streakCount': streakCount,
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
      'friends': friends,
      'friendRequests': friendRequests,
      'achievements': achievements,
      'auraVisibility': auraVisibility.toString().split('.').last, // Convert enum to string
      'blockedUsers': blockedUsers,
      'allowAuraFrom': allowAuraFrom.toString().split('.').last, // Convert enum to string
    };
  }

  // Create a UserModel object from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, id: doc.id);
  }

  // Create a UserModel object from a Map (for caching)
  factory UserModel.fromMap(Map<String, dynamic> data, {String? id}) {
    // Convert friends list
    List<String> friendsList = [];
    if (data['friends'] != null) {
      friendsList = List<String>.from(data['friends']);
    }

    // Convert friend requests list
    List<String> requestsList = [];
    if (data['friendRequests'] != null) {
      requestsList = List<String>.from(data['friendRequests']);
    }

    // Convert achievements list
    List<String>? achievementsList;
    if (data['achievements'] != null) {
      achievementsList = List<String>.from(data['achievements']);
    }

    // Convert blocked users list
    List<String> blockedUsersList = [];
    if (data['blockedUsers'] != null) {
      blockedUsersList = List<String>.from(data['blockedUsers']);
    }

    // Parse auraVisibility enum
    AuraVisibility auraVisibility = AuraVisibility.public; // Default
    if (data['auraVisibility'] != null) {
      try {
        auraVisibility = AuraVisibility.values.firstWhere(
          (e) => e.toString().split('.').last == data['auraVisibility'],
          orElse: () => AuraVisibility.public,
        );
      } catch (_) {}
    }

    // Parse allowAuraFrom enum
    AllowAuraFrom allowAuraFrom = AllowAuraFrom.everyone; // Default
    if (data['allowAuraFrom'] != null) {
      try {
        allowAuraFrom = AllowAuraFrom.values.firstWhere(
          (e) => e.toString().split('.').last == data['allowAuraFrom'],
          orElse: () => AllowAuraFrom.everyone,
        );
      } catch (_) {}
    }

    // Convert numeric fields from double to int if needed
    int getIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Handle timestamps from cache (stored as maps)
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is Map && value.containsKey('seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['seconds'] * 1000 + (value['nanoseconds'] ?? 0) / 1000000).round()
        );
      }
      return null;
    }

    return UserModel(
      id: id ?? data['id'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      auraPoints: getIntValue(data['auraPoints'], 0),
      createdAt: parseDateTime(data['createdAt']),
      lastPointsEarnedAt: parseDateTime(data['lastPointsEarnedAt']),
      lastAuraDate: parseDateTime(data['lastAuraDate']),
      streakCount: getIntValue(data['streakCount'], 0),
      completedTasks: getIntValue(data['completedTasks'], 0),
      totalTasks: getIntValue(data['totalTasks'], 0),
      friends: friendsList,
      friendRequests: requestsList,
      achievements: achievementsList,
      auraVisibility: auraVisibility,
      blockedUsers: blockedUsersList,
      allowAuraFrom: allowAuraFrom,
    );
  }

  // Create a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    int? auraPoints,
    DateTime? createdAt,
    DateTime? lastPointsEarnedAt,
    DateTime? lastAuraDate,
    int? streakCount,
    int? completedTasks,
    int? totalTasks,
    List<String>? friends,
    List<String>? friendRequests,
    List<String>? achievements,
    AuraVisibility? auraVisibility,
    List<String>? blockedUsers,
    AllowAuraFrom? allowAuraFrom,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      auraPoints: auraPoints ?? this.auraPoints,
      createdAt: createdAt ?? this.createdAt,
      lastPointsEarnedAt: lastPointsEarnedAt ?? this.lastPointsEarnedAt,
      lastAuraDate: lastAuraDate ?? this.lastAuraDate,
      streakCount: streakCount ?? this.streakCount,
      completedTasks: completedTasks ?? this.completedTasks,
      totalTasks: totalTasks ?? this.totalTasks,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      achievements: achievements ?? this.achievements,
      auraVisibility: auraVisibility ?? this.auraVisibility,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      allowAuraFrom: allowAuraFrom ?? this.allowAuraFrom,
    );
  }

  // Override equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  // Override hashCode
  @override
  int get hashCode => id.hashCode;
}
