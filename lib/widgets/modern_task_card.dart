import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/screens/tasks/edit_task_screen.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/screens/challenges/create_challenge_screen.dart';
import 'package:taskswap/utils/haptic_feedback_util.dart';

class ModernTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;
  final bool isCompletedSection;

  const ModernTaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    this.isCompletedSection = false,
  });

  @override
  State<ModernTaskCard> createState() => _ModernTaskCardState();
}

class _ModernTaskCardState extends State<ModernTaskCard> with SingleTickerProviderStateMixin {
  final TaskService taskService = TaskService();
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: widget.isCompletedSection
                ? colorScheme.surfaceContainerLowest
                : widget.task.isCompleted
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isCompletedSection
                ? []
                : [
                    BoxShadow(
                      color: _isHovered
                          ? colorScheme.shadow.withAlpha(26) // opacity 0.1
                          : colorScheme.shadow.withAlpha(13), // opacity 0.05
                      blurRadius: _isHovered ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: Border.all(
              color: widget.isCompletedSection
                  ? colorScheme.outlineVariant
                  : _isHovered
                      ? colorScheme.primary.withAlpha(77) // opacity 0.3
                      : colorScheme.outlineVariant,
              width: widget.isCompletedSection ? 0.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedbackUtil.selectionClick();
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
                        // Checkbox with animation
                        Semantics(
                          label: widget.task.isCompleted
                            ? 'Mark task ${widget.task.title} as incomplete'
                            : 'Mark task ${widget.task.title} as complete',
                          hint: 'Double tap to ${widget.task.isCompleted ? 'uncheck' : 'check'} this task',
                          button: true,
                          enabled: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              if (widget.task.id != null) {
                                try {
                                  if (!widget.task.isCompleted) {
                                    // Mark task as completed
                                    await taskService.markTaskAsCompleted(widget.task.id!);
                                  } else {
                                    // Mark task as incomplete
                                    final task = widget.task.copyWith(isCompleted: false);
                                    await taskService.updateTask(widget.task.id!, task);
                                  }
                                  widget.onTaskUpdated();

                                  // Provide enhanced haptic feedback based on completion state
                                  if (!widget.task.isCompleted) {
                                    // Task completed - stronger feedback
                                    HapticFeedbackUtil.taskCompleted();
                                  } else {
                                    // Task uncompleted - lighter feedback
                                    HapticFeedbackUtil.lightImpact();
                                  }
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.task.isCompleted
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: widget.task.isCompleted
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                  width: 2,
                                ),
                              ),
                              child: widget.task.isCompleted
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

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
                                  fontWeight: FontWeight.w600,
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

                    // Category chip and due date
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCategoryChip(widget.task.category),
                        if (widget.task.isChallenge) ...[
                          const SizedBox(width: 8),
                          _buildChallengeChip(),
                        ],
                        const Spacer(),
                        if (widget.task.timerDuration != null)
                          _buildTimerChip(widget.task.timerDuration!),
                        if (widget.task.timerDuration != null && widget.task.dueDate != null)
                          const SizedBox(width: 8),
                        if (widget.task.dueDate != null)
                          _buildDueDate(widget.task.dueDate!),
                      ],
                    ),

                    // Due date and actions
                    if (!widget.task.isCompleted && !widget.isCompletedSection) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Edit button
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            color: colorScheme.onSurfaceVariant,
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
                          ),

                          // Challenge button
                          _buildActionButton(
                            icon: Icons.people_outline,
                            label: 'Challenge',
                            color: colorScheme.primary,
                            onTap: () {
                              _showChallengeDialog(context);
                            },
                          ),

                          // Delete button
                          _buildActionButton(
                            icon: Icons.delete_outline,
                            label: 'Delete',
                            color: colorScheme.error,
                            onTap: () {
                              _showDeleteConfirmation(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(TaskCategory category) {
    final theme = Theme.of(context);

    // Use the extension methods from TaskCategoryExtension
    final chipColor = category.color;
    final chipIcon = category.icon;
    final chipText = category.name;

    return Semantics(
      label: 'Category: $chipText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: chipColor.withAlpha(26), // opacity 0.1
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chipColor.withAlpha(77), // opacity 0.3
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              size: 14,
              color: chipColor,
            ),
            const SizedBox(width: 4),
            Text(
              chipText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDate(DateTime dueDate) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverdue = _isTaskOverdue();
    final color = isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant;
    final formattedDate = DateFormat('MMMM d, yyyy').format(dueDate);

    return Semantics(
      label: isOverdue
        ? 'Due date: $formattedDate. This task is overdue.'
        : 'Due date: $formattedDate',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOverdue ? colorScheme.error.withAlpha(26) : colorScheme.surfaceContainerHighest, // opacity 0.1
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM d, yyyy').format(dueDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerChip(int duration) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Timer duration: $duration minutes',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$duration min',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeChip() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: widget.task.challengeYourself
          ? 'This is a challenge with yourself and friends'
          : 'This is a challenge task',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.task.challengeYourself ? Icons.people : Icons.emoji_events_outlined,
              size: 14,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              widget.task.challengeYourself ? 'Group Challenge' : 'Challenge',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$label task',
      button: true,
      enabled: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedbackUtil.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
          Semantics(
            label: 'Cancel challenge',
            button: true,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
            ),
          ),
          Semantics(
            label: 'Create challenge with this task',
            button: true,
            child: ElevatedButton(
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
          Semantics(
            label: 'Cancel deletion',
            button: true,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
            ),
          ),
          Semantics(
            label: 'Confirm delete task',
            button: true,
            hint: 'This action cannot be undone',
            child: ElevatedButton(
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
          ),
        ],
      ),
    );
  }
}
