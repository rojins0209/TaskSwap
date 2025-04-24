import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/screens/tasks/edit_task_screen.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/utils/animation_utils.dart';
import 'package:taskswap/screens/challenges/create_challenge_screen.dart';
import 'package:taskswap/widgets/aura_recognition_dialog.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TaskService taskService = TaskService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task completion status
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: widget.task.isCompleted,
                      onChanged: (value) async {
                        if (widget.task.id != null && !widget.task.isCompleted) {
                          try {
                            // Get reward details from completing the task
                            final rewardDetails = await taskService.markTaskAsCompleted(widget.task.id!);
                            widget.onTaskUpdated();

                            // Check if context is still valid before showing animation
                            if (context.mounted) {
                              // Extract reward information
                              final int pointsEarned = rewardDetails['pointsEarned'] ?? widget.task.points;
                              final int bonusPoints = rewardDetails['bonusPoints'] ?? 0;
                              final String taskTitle = rewardDetails['taskTitle'] ?? widget.task.title;
                              final bool isChallenge = rewardDetails['isChallenge'] ?? false;
                              final bool showAuraMessage = rewardDetails['showAuraMessage'] ?? false;

                              if (showAuraMessage) {
                                // For regular tasks, show the aura recognition dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AuraRecognitionDialog(
                                    taskId: widget.task.id!,
                                    taskTitle: taskTitle,
                                  ),
                                );
                              } else {
                                // For challenge tasks, show the celebration animation
                                AnimationUtils.showTaskCompletionAnimation(
                                  context: context,
                                  taskTitle: taskTitle,
                                  pointsEarned: pointsEarned,
                                  confettiController: _confettiController,
                                  isChallenge: isChallenge,
                                );
                              }

                              // If there was a streak milestone, show that animation after a delay
                              if (rewardDetails.containsKey('streakMilestone')) {
                                final streakMilestone = rewardDetails['streakMilestone'];
                                Future.delayed(const Duration(seconds: 4), () {
                                  if (context.mounted) {
                                    AnimationUtils.showStreakMilestoneAnimation(
                                      context: context,
                                      streakDays: streakMilestone['streakCount'] ?? 0,
                                      bonusPoints: streakMilestone['bonusPoints'] ?? 0,
                                      confettiController: _confettiController,
                                    );
                                  }
                                });
                              }

                              // If there was a task milestone, show that animation after a delay
                              if (rewardDetails.containsKey('taskMilestone')) {
                                final taskMilestone = rewardDetails['taskMilestone'];
                                final delaySeconds = rewardDetails.containsKey('streakMilestone') ? 8 : 4;
                                Future.delayed(Duration(seconds: delaySeconds), () {
                                  if (context.mounted) {
                                    AnimationUtils.showMilestoneAnimation(
                                      context: context,
                                      milestone: taskMilestone['name'] ?? 'Achievement',
                                      bonusPoints: taskMilestone['bonusPoints'] ?? 0,
                                      confettiController: _confettiController,
                                    );
                                  }
                                });
                              }

                              // Show snackbar with total points earned
                              final totalPoints = pointsEarned + bonusPoints;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Task completed! Earned $totalPoints points'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      activeColor: AppTheme.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Task content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: AppTheme.headingSmall.copyWith(
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.task.isCompleted
                                ? AppTheme.textSecondaryColor
                                : AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (widget.task.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.task.description,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondaryColor,
                              decoration: widget.task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Due date
                            if (widget.task.dueDate != null) ...[
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: _getDueDateColor(widget.task.dueDate!),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(widget.task.dueDate!),
                                style: AppTheme.bodySmall.copyWith(
                                  color: _getDueDateColor(widget.task.dueDate!),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],

                            // Points
                            Icon(
                              Icons.star,
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.task.points} points',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Column(
                    children: [
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
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.people_outline),
                        onPressed: () {
                          _showChallengeDialog(context);
                        },
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          _showDeleteConfirmation(context);
                        },
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppTheme.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      // Overdue
      return AppTheme.errorColor;
    } else if (difference == 0) {
      // Due today
      return Colors.orange;
    } else if (difference <= 2) {
      // Due soon
      return Colors.amber;
    } else {
      // Due later
      return AppTheme.textSecondaryColor;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final TaskService taskService = TaskService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              if (widget.task.id != null) {
                try {
                  await taskService.deleteTask(widget.task.id!);
                  widget.onTaskUpdated();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task deleted'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting task: ${e.toString()}'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showChallengeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Challenge a Friend'),
        content: const Text('Would you like to challenge a friend to complete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog

              // Navigate to the create challenge screen with the task details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateChallengeScreen(
                    initialTaskDescription: '${widget.task.title}${widget.task.description.isNotEmpty ? '\n\n${widget.task.description}' : ''}',
                    initialPoints: widget.task.points,
                  ),
                ),
              );
            },
            child: Text(
              'Challenge',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
