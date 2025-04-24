import 'package:cloud_firestore/cloud_firestore.dart';

class FollowerRelation {
  final String? id;
  final String followerId; // User who is following
  final String followedId; // User being followed
  final DateTime? timestamp;

  FollowerRelation({
    this.id,
    required this.followerId,
    required this.followedId,
    this.timestamp,
  });

  // Convert FollowerRelation object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'followerId': followerId,
      'followedId': followedId,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }

  // Create a FollowerRelation object from a Firestore document
  factory FollowerRelation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FollowerRelation(
      id: doc.id,
      followerId: data['followerId'] ?? '',
      followedId: data['followedId'] ?? '',
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
    );
  }
}
