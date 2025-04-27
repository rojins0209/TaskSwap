import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/widgets/combined_task_list.dart';
import 'package:taskswap/widgets/notification_badge.dart';
import 'package:taskswap/widgets/app_header.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/services/auth_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  int _totalTasks = 0;
  int _completedTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadTaskStats();
  }

  Future<void> _loadTaskStats() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        // Get user document to retrieve task stats
        final userDoc = await _taskService.getUserTaskCount(userId);
        setState(() {
          _totalTasks = userDoc['totalTasks'] ?? 0;
          _completedTasks = userDoc['completedTasks'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading task stats: $e');
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
            // Consistent app header
            AppHeader(
              title: 'My Tasks',
              titleFontSize: 32,
              leadingIcon: Icons.task_alt,
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatChip(
                        icon: Icons.task_alt,
                        label: '$_completedTasks completed',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        icon: Icons.pending_actions,
                        label: '${_totalTasks - _completedTasks} pending',
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Notification badge
                const NotificationBadge(),

                // Competitive challenges button
                IconButton(
                  icon: Icon(Icons.emoji_events_outlined, color: colorScheme.onSurface),
                  tooltip: 'Competitive Challenges',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pushNamed(context, '/competitive-challenges');
                  },
                ),

                // Refresh button
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.onSurface),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _loadTaskStats();
                    // Force rebuild of the CombinedTaskList
                    setState(() {});
                  },
                ),
              ],
            ),

            // Main content
            Expanded(
              child: CombinedTaskList(key: ValueKey('task_list_${DateTime.now().millisecondsSinceEpoch}')),
            ),
          ],
        ),
      ),
    );
  }

  // Stat chip for task counts
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // opacity 0.1
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(77), // opacity 0.3
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
