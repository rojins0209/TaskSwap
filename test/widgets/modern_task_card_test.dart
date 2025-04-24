import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/widgets/modern_task_card.dart';

// Mock callback
class MockCallback extends Mock {
  void call();
}

void main() {
  group('ModernTaskCard Widget', () {
    testWidgets('should display task title and description', (WidgetTester tester) async {
      // Create a test task
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'This is a test task description',
        createdBy: 'user1',
        isCompleted: false,
        points: 10,
        category: TaskCategory.work,
      );

      // Create a mock callback
      final mockCallback = MockCallback();

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTaskCard(
              task: task,
              onTaskUpdated: mockCallback,
            ),
          ),
        ),
      );

      // Verify that the task title and description are displayed
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('This is a test task description'), findsOneWidget);
    });

    testWidgets('should display completed task with strikethrough', (WidgetTester tester) async {
      // Create a completed test task
      final task = Task(
        id: '1',
        title: 'Completed Task',
        description: 'This task is completed',
        createdBy: 'user1',
        isCompleted: true,
        points: 10,
        category: TaskCategory.work,
      );

      // Create a mock callback
      final mockCallback = MockCallback();

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTaskCard(
              task: task,
              onTaskUpdated: mockCallback,
            ),
          ),
        ),
      );

      // Verify that the task title is displayed
      expect(find.text('Completed Task'), findsOneWidget);

      // Find the Text widget for the title
      final titleFinder = find.text('Completed Task');
      final titleWidget = tester.widget<Text>(titleFinder);

      // Verify that the title has strikethrough decoration
      expect(titleWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgets('should display category chip for incomplete tasks', (WidgetTester tester) async {
      // Create a test task
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'This is a test task',
        createdBy: 'user1',
        isCompleted: false,
        points: 10,
        category: TaskCategory.work,
      );

      // Create a mock callback
      final mockCallback = MockCallback();

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTaskCard(
              task: task,
              onTaskUpdated: mockCallback,
            ),
          ),
        ),
      );

      // Verify that the category chip is displayed
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('should not display category chip for completed tasks', (WidgetTester tester) async {
      // Create a completed test task
      final task = Task(
        id: '1',
        title: 'Completed Task',
        description: 'This task is completed',
        createdBy: 'user1',
        isCompleted: true,
        points: 10,
        category: TaskCategory.work,
      );

      // Create a mock callback
      final mockCallback = MockCallback();

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernTaskCard(
              task: task,
              onTaskUpdated: mockCallback,
            ),
          ),
        ),
      );

      // Verify that the category chip is not displayed
      expect(find.text('Work'), findsNothing);
    });
  });
}
