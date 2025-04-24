import 'package:flutter/material.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/services/auth_service.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/widgets/app_header.dart';
import 'package:taskswap/widgets/modern_task_card.dart';
import 'package:taskswap/utils/haptic_feedback_util.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  late Stream<List<Task>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _initTasksStream();
  }

  void _initTasksStream() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _tasksStream = _taskService.getUserTasks(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // App header
            AppHeader(
              title: 'Completed Tasks',
              titleFontSize: 28,
              leadingIcon: Icons.task_alt,
              showBackButton: true,
              actions: [
                // Refresh button
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.onSurface),
                  onPressed: () {
                    HapticFeedbackUtil.mediumImpact();
                    setState(() {
                      _initTasksStream();
                    });
                  },
                ),
              ],
            ),

            // Main content
            Expanded(
              child: _buildCompletedTasksList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTasksList() {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return const Center(
        child: Text('You need to be logged in to view tasks'),
      );
    }

    return StreamBuilder<List<Task>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading tasks: ${snapshot.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        // Filter only completed tasks
        final completedTasks = tasks.where((task) => task.isCompleted).toList();

        if (completedTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withAlpha(128),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Completed Tasks',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Complete some tasks to see them here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedbackUtil.mediumImpact();
            setState(() {
              _initTasksStream();
            });
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: completedTasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = completedTasks[index];
              return ModernTaskCard(
                task: task,
                onTaskUpdated: () {
                  HapticFeedbackUtil.selectionClick();
                  setState(() {});
                },
              );
            },
          ),
        );
      },
    );
  }
}
