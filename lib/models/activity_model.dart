import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  taskCompleted,
  challengeCompleted,
  auraGiven,
  auraReceived,
  achievementEarned,
  friendAdded,
}

class Activity {
  final String? id;
  final String userId;
  final ActivityType type;
  final DateTime? timestamp;
  final String? title;
  final String? description;
  final int? points;
  final String? relatedUserId; // For activities involving another user
  final String? relatedTaskId; // For task-related activities
  final String? relatedChallengeId; // For challenge-related activities
  final String? relatedAuraGiftId; // For aura gift-related activities
  final List<String> likedBy; // Users who liked this activity
  final Map<String, String>? reactions; // User ID to reaction emoji mapping

  Activity({
    this.id,
    required this.userId,
    required this.type,
    this.timestamp,
    this.title,
    this.description,
    this.points,
    this.relatedUserId,
    this.relatedTaskId,
    this.relatedChallengeId,
    this.relatedAuraGiftId,
    this.likedBy = const [],
    this.reactions,
  });

  // Convert Activity object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last, // Convert enum to string
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'title': title,
      'description': description,
      'points': points,
      'relatedUserId': relatedUserId,
      'relatedTaskId': relatedTaskId,
      'relatedChallengeId': relatedChallengeId,
      'relatedAuraGiftId': relatedAuraGiftId,
      'likedBy': likedBy,
      'reactions': reactions,
    };
  }

  // Create an Activity object from a Firestore document
  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert type string to enum
    ActivityType activityType;
    try {
      activityType = ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ActivityType.taskCompleted,
      );
    } catch (_) {
      activityType = ActivityType.taskCompleted;
    }

    // Convert likedBy list
    List<String> likedByList = [];
    if (data['likedBy'] != null) {
      likedByList = List<String>.from(data['likedBy']);
    }

    // Convert reactions map
    Map<String, String>? reactionsMap;
    if (data['reactions'] != null) {
      reactionsMap = Map<String, String>.from(data['reactions']);
    }

    // Convert numeric fields from double to int if needed
    int? getIntValue(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return null;
    }

    return Activity(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: activityType,
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
      title: data['title'],
      description: data['description'],
      points: getIntValue(data['points']),
      relatedUserId: data['relatedUserId'],
      relatedTaskId: data['relatedTaskId'],
      relatedChallengeId: data['relatedChallengeId'],
      relatedAuraGiftId: data['relatedAuraGiftId'],
      likedBy: likedByList,
      reactions: reactionsMap,
    );
  }

  // Create a copy of the activity with updated fields
  Activity copyWith({
    String? id,
    String? userId,
    ActivityType? type,
    DateTime? timestamp,
    String? title,
    String? description,
    int? points,
    String? relatedUserId,
    String? relatedTaskId,
    String? relatedChallengeId,
    String? relatedAuraGiftId,
    List<String>? likedBy,
    Map<String, String>? reactions,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedTaskId: relatedTaskId ?? this.relatedTaskId,
      relatedChallengeId: relatedChallengeId ?? this.relatedChallengeId,
      relatedAuraGiftId: relatedAuraGiftId ?? this.relatedAuraGiftId,
      likedBy: likedBy ?? this.likedBy,
      reactions: reactions ?? this.reactions,
    );
  }
}
