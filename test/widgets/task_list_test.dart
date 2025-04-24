import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/providers/theme_provider.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/widgets/modern_task_card.dart';

// Mock classes
class MockTaskService extends Mock implements TaskService {}

void main() {
  group('Task List Widget Tests', () {
    testWidgets('ModernTaskCard displays task information correctly', (WidgetTester tester) async {
      // Create a test task
      final task = Task(
        id: 'test-id',
        title: 'Test Task',
        description: 'This is a test task',
        createdBy: 'user-id',
        points: 10,
        category: TaskCategory.work,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => ThemeProvider(),
              child: ModernTaskCard(
                task: task,
                onTaskUpdated: () {},
              ),
            ),
          ),
        ),
      );

      // Verify that the task title and description are displayed
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('This is a test task'), findsOneWidget);
      
      // Verify that the category is displayed
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('ModernTaskCard handles completed tasks correctly', (WidgetTester tester) async {
      // Create a completed test task
      final task = Task(
        id: 'test-id',
        title: 'Completed Task',
        description: 'This task is completed',
        createdBy: 'user-id',
        points: 10,
        isCompleted: true,
        category: TaskCategory.work,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => ThemeProvider(),
              child: ModernTaskCard(
                task: task,
                onTaskUpdated: () {},
              ),
            ),
          ),
        ),
      );

      // Verify that the task title is displayed with strikethrough
      final titleFinder = find.text('Completed Task');
      expect(titleFinder, findsOneWidget);
      
      // Verify that the category is not displayed for completed tasks
      expect(find.text('Work'), findsNothing);
    });
  });
}
