import 'package:flutter/material.dart';

enum TaskCategory {
  work,
  health,
  learning,
  personal,
}

// Helper class for static methods
class TaskCategoryHelper {
  static TaskCategory fromString(String? value) {
    if (value == null) return TaskCategory.personal;

    try {
      return TaskCategory.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return TaskCategory.personal;
    }
  }
}

extension TaskCategoryExtension on TaskCategory {
  String get name {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.learning:
        return 'Learning';
      case TaskCategory.personal:
        return 'Personal';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.health:
        return Icons.favorite;
      case TaskCategory.learning:
        return Icons.school;
      case TaskCategory.personal:
        return Icons.person;
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.learning:
        return Colors.green;
      case TaskCategory.personal:
        return Colors.indigo;
    }
  }

  String get emoji {
    switch (this) {
      case TaskCategory.work:
        return '💼';
      case TaskCategory.health:
        return '❤️';
      case TaskCategory.learning:
        return '📚';
      case TaskCategory.personal:
        return '👤';
    }
  }

  static TaskCategory fromString(String? value) {
    if (value == null) return TaskCategory.personal;

    try {
      return TaskCategory.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return TaskCategory.personal;
    }
  }
}
