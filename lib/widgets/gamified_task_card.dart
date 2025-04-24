import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/screens/tasks/edit_task_screen.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/screens/challenges/create_challenge_screen.dart';

class GamifiedTaskCard extends StatefulWidget {
  // TODO: Rename this class to TaskCard in a future update
  final Task task;
  final VoidCallback onTaskUpdated;
  final bool animate;

  const GamifiedTaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    this.animate = true,
  });

  @override
  State<GamifiedTaskCard> createState() => _GamifiedTaskCardState();
}

class _GamifiedTaskCardState extends State<GamifiedTaskCard> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Get category color - Not used in simplified design
  // Color _getCategoryColor(TaskCategory category) {
  //   switch (category) {
  //     case TaskCategory.work:
  //       return Colors.blue;
  //     case TaskCategory.health:
  //       return Colors.green;
  //     case TaskCategory.learning:
  //       return Colors.orange;
  //     case TaskCategory.personal:
  //       return Colors.purple;
  //   }
  // }

  // Get category icon
  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
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

  // Get difficulty color based on points - Not used in simplified design
  // Color _getDifficultyColor() {
  //   final points = widget.task.points;
  //   if (points >= 50) return Colors.red.shade300;
  //   if (points >= 30) return Colors.orange.shade300;
  //   if (points >= 20) return Colors.amber.shade300;
  //   return Colors.green.shade300;
  // }

  // Get difficulty label based on points - Not used in simplified design
  // String _getDifficultyLabel() {
  //   final points = widget.task.points;
  //   if (points >= 50) return 'Hard';
  //   if (points >= 30) return 'Medium';
  //   if (points >= 20) return 'Normal';
  //   return 'Easy';
  // }

  @override
  Widget build(BuildContext context) {
    final TaskService taskService = TaskService();

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51), // opacity 0.2
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                ? Theme.of(context).shadowColor.withAlpha(26) // opacity 0.1
                : Theme.of(context).shadowColor.withAlpha(13), // opacity 0.05
              blurRadius: _isHovered ? 8 : 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to task details or edit screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditTaskScreen(task: widget.task),
              ),
            ).then((value) {
              if (value == true) {
                widget.onTaskUpdated();
              }
            });
          },
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task title and completion status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Task completion status
                        Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.task.isCompleted
                                ? Theme.of(context).colorScheme.primary.withAlpha(26) // opacity 0.1
                                : Colors.transparent,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () async {
                              if (widget.task.id != null && !widget.task.isCompleted) {
                                try {
                                  // Mark task as completed
                                  await taskService.markTaskAsCompleted(widget.task.id!);
                                  widget.onTaskUpdated();

                                  // Show simple completion message
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Task completed'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Handle error
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error completing task: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } else if (widget.task.id != null && widget.task.isCompleted) {
                                try {
                                  // Update task to mark as incomplete
                                  final task = widget.task.copyWith(isCompleted: false);
                                  await taskService.updateTask(widget.task.id!, task);
                                  widget.onTaskUpdated();
                                } catch (e) {
                                  // Handle error
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error updating task: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                widget.task.isCompleted ? Icons.check : null,
                                color: widget.task.isCompleted ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Task content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.task.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      decoration: widget.task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: widget.task.isCompleted
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  // Category and points in a row
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(widget.task.category),
                                        color: Theme.of(context).colorScheme.primary.withAlpha(178), // opacity 0.7
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.task.category.name,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.star_outline,
                                        color: Theme.of(context).colorScheme.secondary.withAlpha(178), // opacity 0.7
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.task.points} points',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (widget.task.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.task.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    decoration: widget.task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),



                    // Due date and action buttons
                    if (widget.task.dueDate != null || !widget.task.isCompleted) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Due date simple text
                          if (widget.task.dueDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: _isTaskOverdue()
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, yyyy').format(widget.task.dueDate!),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _isTaskOverdue()
                                        ? Colors.red
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: _isTaskOverdue() ? FontWeight.bold : null,
                                  ),
                                ),
                              ],
                            ),

                          // Action buttons
                          if (!widget.task.isCompleted)
                            Row(
                              children: [
                                // Edit button
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTaskScreen(task: widget.task),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        widget.onTaskUpdated();
                                      }
                                    });
                                  },
                                  iconSize: 18,
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(32, 32),
                                  ),
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),

                                // Challenge button
                                IconButton(
                                  icon: const Icon(Icons.people_outline),
                                  onPressed: () {
                                    _showChallengeDialog(context);
                                  },
                                  iconSize: 18,
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(32, 32),
                                  ),
                                  color: Theme.of(context).colorScheme.primary,
                                ),

                                // Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    _showDeleteConfirmation(context);
                                  },
                                  iconSize: 18,
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(32, 32),
                                  ),
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),


            ],
          ),
        ),
      ),
    );

    // Apply simple fade animation if enabled
    if (widget.animate) {
      card = card.animate()
        .fadeIn(duration: const Duration(milliseconds: 300));
    }

    return card;
  }

  bool _isTaskOverdue() {
    if (widget.task.dueDate == null) return false;
    final now = DateTime.now();
    return widget.task.dueDate!.isBefore(now) && !widget.task.isCompleted;
  }

  void _showChallengeDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Challenge a Friend', style: theme.textTheme.titleLarge),
        content: Text(
          'Would you like to challenge a friend with this task?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateChallengeScreen(
                    initialTaskDescription: widget.task.title,
                    initialPoints: widget.task.points,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Challenge'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final TaskService taskService = TaskService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Delete Task', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to delete this task?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (widget.task.id != null) {
                try {
                  await taskService.deleteTask(widget.task.id!);
                  widget.onTaskUpdated();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting task: $e'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
