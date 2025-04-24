import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

class FriendRequest {
  final String? id;
  final String fromUserId;
  final String toUserId;
  final DateTime? createdAt;
  final FriendRequestStatus status;

  FriendRequest({
    this.id,
    required this.fromUserId,
    required this.toUserId,
    this.createdAt,
    this.status = FriendRequestStatus.pending,
  });

  // Convert FriendRequest object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'status': status.toString().split('.').last, // Convert enum to string
    };
  }

  // Create a FriendRequest object from a Firestore document
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Convert status string to enum
    FriendRequestStatus requestStatus = FriendRequestStatus.pending;
    if (data['status'] != null) {
      final statusString = data['status'] as String;
      for (var status in FriendRequestStatus.values) {
        if (status.toString().split('.').last == statusString) {
          requestStatus = status;
          break;
        }
      }
    }
    
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      status: requestStatus,
    );
  }

  // Create a copy of the friend request with updated fields
  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    DateTime? createdAt,
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
