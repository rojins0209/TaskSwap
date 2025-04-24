import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  auraReceived,
  challengeCompleted,
  friendRequest,
  friendAccepted,
  milestone,
  system,
  taskCompleted,
}

class NotificationModel {
  final String? id;
  final String userId; // User who receives the notification
  final NotificationType type;
  final String message;
  final DateTime? timestamp;
  final bool read;
  final String? fromUserId; // User who triggered the notification (if applicable)
  final String? relatedTaskId; // Related task (if applicable)
  final String? relatedChallengeId; // Related challenge (if applicable)
  final String? relatedAuraGiftId; // Related aura gift (if applicable)
  final Map<String, dynamic>? data; // Additional data for the notification

  NotificationModel({
    this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.timestamp,
    this.read = false,
    this.fromUserId,
    this.relatedTaskId,
    this.relatedChallengeId,
    this.relatedAuraGiftId,
    this.data,
  });

  // Convert NotificationModel object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last, // Convert enum to string
      'message': message,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'read': read,
      'fromUserId': fromUserId,
      'relatedTaskId': relatedTaskId,
      'relatedChallengeId': relatedChallengeId,
      'relatedAuraGiftId': relatedAuraGiftId,
      'data': data,
    };
  }

  // Create a NotificationModel object from a Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse notification type
    NotificationType notificationType;
    try {
      notificationType = NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.system,
      );
    } catch (_) {
      notificationType = NotificationType.system;
    }

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: notificationType,
      message: data['message'] ?? '',
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
      read: data['read'] ?? false,
      fromUserId: data['fromUserId'],
      relatedTaskId: data['relatedTaskId'],
      relatedChallengeId: data['relatedChallengeId'],
      relatedAuraGiftId: data['relatedAuraGiftId'],
      data: data['data'],
    );
  }

  // Create a copy of the notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? message,
    DateTime? timestamp,
    bool? read,
    String? fromUserId,
    String? relatedTaskId,
    String? relatedChallengeId,
    String? relatedAuraGiftId,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      fromUserId: fromUserId ?? this.fromUserId,
      relatedTaskId: relatedTaskId ?? this.relatedTaskId,
      relatedChallengeId: relatedChallengeId ?? this.relatedChallengeId,
      relatedAuraGiftId: relatedAuraGiftId ?? this.relatedAuraGiftId,
      data: data ?? this.data,
    );
  }
}
