import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/screens/tasks/edit_task_screen.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/screens/challenges/create_challenge_screen.dart';

class CleanTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const CleanTaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<CleanTaskCard> createState() => _CleanTaskCardState();
}

class _CleanTaskCardState extends State<CleanTaskCard> {
  final TaskService taskService = TaskService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and checkbox row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: widget.task.isCompleted,
                      onChanged: (value) async {
                        if (widget.task.id != null) {
                          try {
                            if (value == true) {
                              // Mark task as completed
                              await taskService.markTaskAsCompleted(widget.task.id!);
                            } else {
                              // Mark task as incomplete
                              final task = widget.task.copyWith(isCompleted: false);
                              await taskService.updateTask(widget.task.id!, task);
                            }
                            widget.onTaskUpdated();
                            
                            // Provide haptic feedback
                            HapticFeedback.selectionClick();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating task: $e'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.task.isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.task.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
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
              
              // Due date and actions
              if (widget.task.dueDate != null || !widget.task.isCompleted) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Due date
                    if (widget.task.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _isTaskOverdue()
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(widget.task.dueDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _isTaskOverdue()
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
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
                            color: colorScheme.onSurfaceVariant,
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
                            color: colorScheme.primary,
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
                            color: colorScheme.error,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
        title: const Text('Challenge a Friend'),
        content: const Text(
          'Would you like to challenge a friend to complete this task?',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
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
