import 'package:cloud_firestore/cloud_firestore.dart';

class AuraGift {
  final String? id;
  final String giverId;
  final String receiverId;
  final int pointsGiven;
  final DateTime? timestamp;
  final String? message;
  final String? taskId; // Optional reference to a task that earned the aura
  final String? taskTitle; // Optional task title for display purposes

  AuraGift({
    this.id,
    required this.giverId,
    required this.receiverId,
    required this.pointsGiven,
    this.timestamp,
    this.message,
    this.taskId,
    this.taskTitle,
  });

  // Convert AuraGift object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'giverId': giverId,
      'receiverId': receiverId,
      'pointsGiven': pointsGiven,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'message': message,
      'taskId': taskId,
      'taskTitle': taskTitle,
    };
  }

  // Create an AuraGift object from a Firestore document
  factory AuraGift.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert numeric fields from double to int if needed
    int getIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    return AuraGift(
      id: doc.id,
      giverId: data['giverId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      pointsGiven: getIntValue(data['pointsGiven'], 0),
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
      message: data['message'],
      taskId: data['taskId'],
      taskTitle: data['taskTitle'],
    );
  }

  // Create a copy of the aura gift with updated fields
  AuraGift copyWith({
    String? id,
    String? giverId,
    String? receiverId,
    int? pointsGiven,
    DateTime? timestamp,
    String? message,
    String? taskId,
    String? taskTitle,
  }) {
    return AuraGift(
      id: id ?? this.id,
      giverId: giverId ?? this.giverId,
      receiverId: receiverId ?? this.receiverId,
      pointsGiven: pointsGiven ?? this.pointsGiven,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
    );
  }
}
