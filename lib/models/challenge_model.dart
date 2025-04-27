import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskswap/models/task_category.dart';

enum ChallengeStatus {
  pending,
  accepted,
  rejected,
  completed,
}

class Challenge {
  final String? id;
  final String fromUserId;
  final String toUserId;
  final String taskDescription;
  final int points;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final ChallengeStatus status;
  final int? pointsEarned; // Points actually earned when completed
  final bool? notifiedSender; // Whether the sender has been notified of completion
  final bool bothUsersComplete; // Whether both users need to complete the task
  final DateTime? dueDate; // Optional due date for the challenge
  final bool senderCompleted; // Whether the sender has completed their part
  final bool receiverCompleted; // Whether the receiver has completed their part
  final DateTime? senderCompletedAt; // When the sender completed their part
  final DateTime? receiverCompletedAt; // When the receiver completed their part
  final TaskCategory category; // Category of the challenge
  final int? timerDuration; // Timer duration in minutes (optional)
  final bool challengeYourself; // Whether this is a challenge yourself with friend
  final double? senderProgress; // Progress of the sender (0.0 to 1.0)
  final double? receiverProgress; // Progress of the receiver (0.0 to 1.0)
  final String? winnerUserId; // User ID of the winner (first to complete)

  Challenge({
    this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.taskDescription,
    this.points = 20,
    this.createdAt,
    this.completedAt,
    this.status = ChallengeStatus.pending,
    this.pointsEarned,
    this.notifiedSender = false,
    this.bothUsersComplete = false,
    this.dueDate,
    this.senderCompleted = false,
    this.receiverCompleted = false,
    this.senderCompletedAt,
    this.receiverCompletedAt,
    this.category = TaskCategory.personal,
    this.timerDuration,
    this.challengeYourself = false,
    this.senderProgress = 0.0,
    this.receiverProgress = 0.0,
    this.winnerUserId,
  });

  // Convert Challenge object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'taskDescription': taskDescription,
      'points': points,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status.toString().split('.').last, // Convert enum to string
      'pointsEarned': pointsEarned,
      'notifiedSender': notifiedSender,
      'bothUsersComplete': bothUsersComplete,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'senderCompleted': senderCompleted,
      'receiverCompleted': receiverCompleted,
      'category': category.toString().split('.').last,
      'timerDuration': timerDuration,
      'challengeYourself': challengeYourself,
      'senderCompletedAt': senderCompletedAt != null ? Timestamp.fromDate(senderCompletedAt!) : null,
      'receiverCompletedAt': receiverCompletedAt != null ? Timestamp.fromDate(receiverCompletedAt!) : null,
      'senderProgress': senderProgress,
      'receiverProgress': receiverProgress,
      'winnerUserId': winnerUserId,
    };
  }

  // Create a Challenge object from a Firestore document
  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert status string to enum
    ChallengeStatus challengeStatus = ChallengeStatus.pending;
    if (data['status'] != null) {
      final statusString = data['status'] as String;
      for (var status in ChallengeStatus.values) {
        if (status.toString().split('.').last == statusString) {
          challengeStatus = status;
          break;
        }
      }
    }

    // Convert numeric fields from double to int if needed
    int getIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Get nullable int value
    int? getNullableIntValue(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return null;
    }

    // Get nullable double value
    double? getNullableDoubleValue(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return null;
    }

    return Challenge(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      taskDescription: data['taskDescription'] ?? '',
      points: getIntValue(data['points'], 20),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      status: challengeStatus,
      pointsEarned: data['pointsEarned'] != null ? getIntValue(data['pointsEarned'], 0) : null,
      notifiedSender: data['notifiedSender'] ?? false,
      bothUsersComplete: data['bothUsersComplete'] ?? false,
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      senderCompleted: data['senderCompleted'] ?? false,
      receiverCompleted: data['receiverCompleted'] ?? false,
      senderCompletedAt: data['senderCompletedAt'] != null ? (data['senderCompletedAt'] as Timestamp).toDate() : null,
      receiverCompletedAt: data['receiverCompletedAt'] != null ? (data['receiverCompletedAt'] as Timestamp).toDate() : null,
      category: TaskCategoryHelper.fromString(data['category']),
      timerDuration: getNullableIntValue(data['timerDuration']),
      challengeYourself: data['challengeYourself'] ?? false,
      senderProgress: getNullableDoubleValue(data['senderProgress']) ?? 0.0,
      receiverProgress: getNullableDoubleValue(data['receiverProgress']) ?? 0.0,
      winnerUserId: data['winnerUserId'],
    );
  }

  // Create a copy of the challenge with updated fields
  Challenge copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? taskDescription,
    int? points,
    DateTime? createdAt,
    DateTime? completedAt,
    ChallengeStatus? status,
    int? pointsEarned,
    bool? notifiedSender,
    bool? bothUsersComplete,
    DateTime? dueDate,
    bool? senderCompleted,
    bool? receiverCompleted,
    DateTime? senderCompletedAt,
    DateTime? receiverCompletedAt,
    TaskCategory? category,
    int? timerDuration,
    bool? challengeYourself,
    double? senderProgress,
    double? receiverProgress,
    String? winnerUserId,
  }) {
    return Challenge(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      taskDescription: taskDescription ?? this.taskDescription,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      notifiedSender: notifiedSender ?? this.notifiedSender,
      bothUsersComplete: bothUsersComplete ?? this.bothUsersComplete,
      dueDate: dueDate ?? this.dueDate,
      senderCompleted: senderCompleted ?? this.senderCompleted,
      receiverCompleted: receiverCompleted ?? this.receiverCompleted,
      senderCompletedAt: senderCompletedAt ?? this.senderCompletedAt,
      receiverCompletedAt: receiverCompletedAt ?? this.receiverCompletedAt,
      category: category ?? this.category,
      timerDuration: timerDuration ?? this.timerDuration,
      challengeYourself: challengeYourself ?? this.challengeYourself,
      senderProgress: senderProgress ?? this.senderProgress,
      receiverProgress: receiverProgress ?? this.receiverProgress,
      winnerUserId: winnerUserId ?? this.winnerUserId,
    );
  }
}
