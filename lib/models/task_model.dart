import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskswap/models/task_category.dart';

class Task {
  final String? id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String createdBy;
  final bool isCompleted;
  final int points;
  final TaskCategory category;
  final bool isChallenge;
  final List<String>? challengeFriends; // List of friend IDs for challenges
  final int? timerDuration; // Optional timer duration in minutes
  final bool challengeYourself; // Whether this is a self-challenge with friends

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.createdAt,
    required this.createdBy,
    this.isCompleted = false,
    required this.points,
    this.category = TaskCategory.personal,
    this.isChallenge = false,
    this.challengeFriends,
    this.timerDuration,
    this.challengeYourself = false,
  });

  // Convert Task object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'isCompleted': isCompleted,
      'points': points,
      'category': category.toString().split('.').last,
      'isChallenge': isChallenge,
      'challengeFriends': challengeFriends,
      'timerDuration': timerDuration,
      'challengeYourself': challengeYourself,
    };
  }

  // Create a Task object from a Firestore document
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert numeric fields from double to int if needed
    int getIntValue(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Convert challengeFriends from dynamic to List<String>
    List<String>? challengeFriends;
    if (data['challengeFriends'] != null) {
      challengeFriends = List<String>.from(data['challengeFriends']);
    }

    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      createdBy: data['createdBy'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      points: getIntValue(data['points'], 0),
      category: TaskCategoryHelper.fromString(data['category']),
      isChallenge: data['isChallenge'] ?? false,
      challengeFriends: challengeFriends,
      timerDuration: data['timerDuration'] != null ? getIntValue(data['timerDuration'], 0) : null,
      challengeYourself: data['challengeYourself'] ?? false,
    );
  }

  // Create a copy of the task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? createdAt,
    String? createdBy,
    bool? isCompleted,
    int? points,
    TaskCategory? category,
    bool? isChallenge,
    List<String>? challengeFriends,
    int? timerDuration,
    bool? challengeYourself,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isCompleted: isCompleted ?? this.isCompleted,
      points: points ?? this.points,
      category: category ?? this.category,
      isChallenge: isChallenge ?? this.isChallenge,
      challengeFriends: challengeFriends ?? this.challengeFriends,
      timerDuration: timerDuration ?? this.timerDuration,
      challengeYourself: challengeYourself ?? this.challengeYourself,
    );
  }
}
