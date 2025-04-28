import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/widgets/combined_task_list.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/services/auth_service.dart';
import 'package:taskswap/models/task_category.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  int _totalTasks = 0;
  int _completedTasks = 0;
  Map<TaskCategory, int> _categoryStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTaskStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskStats() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        // Get user document to retrieve task stats
        final userDoc = await _taskService.getUserTaskCount(userId);

        // Get category stats
        final categoryStats = await _taskService.getTaskCategoryStats(userId);

        setState(() {
          _totalTasks = userDoc['totalTasks'] ?? 0;
          _completedTasks = userDoc['completedTasks'] ?? 0;
          _categoryStats = categoryStats;
        });
      }
    } catch (e) {
      debugPrint('Error loading task stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header implementation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.task_alt,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'My Tasks',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Notification icon without badge
                          IconButton(
                            icon: Icon(Icons.notifications, color: colorScheme.onSurface),
                            onPressed: () {
                              // Handle notification tap
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
                    ],
                  ),
                  Padding(
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
                ],
              ),
            ),

            // Tab bar for Active/Completed tasks
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                dividerColor: Colors.transparent,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall,
                padding: const EdgeInsets.all(4),
                onTap: (index) {
                  HapticFeedback.selectionClick();
                },
                tabs: [
                  Tab(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        if (_totalTasks - _completedTasks > 0)
                          Positioned(
                            top: -4,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_totalTasks - _completedTasks}',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _tabController.index == 0
                                    ? colorScheme.primary
                                    : colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    text: 'Active',
                  ),
                  Tab(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.done_all, size: 20),
                        if (_completedTasks > 0)
                          Positioned(
                            top: -4,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_completedTasks',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: _tabController.index == 1
                                    ? colorScheme.primary
                                    : colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    text: 'Completed',
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active tasks tab
                  CombinedTaskList(
                    key: const ValueKey('active_tasks'),
                    showCompletedTasks: false,
                    onTasksUpdated: _loadTaskStats,
                  ),

                  // Completed tasks tab
                  CombinedTaskList(
                    key: const ValueKey('completed_tasks'),
                    showCompletedTasks: true,
                    onTasksUpdated: _loadTaskStats,
                  ),
                ],
              ),
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
