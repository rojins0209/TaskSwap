import 'package:flutter/material.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/custom_button.dart';
import 'package:taskswap/widgets/custom_text_field.dart';
import 'package:taskswap/widgets/date_time_picker.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;

  late DateTime? _dueDate;
  bool _isLoading = false;

  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing task data
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _pointsController = TextEditingController(text: widget.task.points.toString());
    _dueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.task.id == null) {
        throw Exception('Task ID is missing');
      }

      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        points: int.parse(_pointsController.text),
      );

      await _taskService.updateTask(widget.task.id!, updatedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Task',
          style: AppTheme.headingSmall,
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                CustomTextField(
                  controller: _titleController,
                  label: 'Task Title',
                  hint: 'Enter task title',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description Field
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Enter task description',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Due Date Picker
                DateTimePicker(
                  selectedDateTime: _dueDate,
                  onDateTimeSelected: (dateTime) {
                    setState(() {
                      _dueDate = dateTime;
                    });
                  },
                  label: 'Due Date',
                ),
                const SizedBox(height: 24),

                // Points Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _pointsController,
                      label: widget.task.isChallenge ? 'Challenge Points' : 'Recognition Points',
                      hint: widget.task.isChallenge
                          ? 'Enter points for this challenge'
                          : 'Enter points friends can award you',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter points';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Points must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    if (!widget.task.isChallenge) ...[  // Only show for personal tasks
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withAlpha(50)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Personal tasks don\'t award points automatically. When you complete a task, you can share it with friends who can recognize your achievement and award you these points.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40),

                // Update Button
                CustomButton(
                  text: 'Update Task',
                  onPressed: _updateTask,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Mark as Completed Button (if not already completed)
                if (!widget.task.isCompleted)
                  CustomButton(
                    text: 'Mark as Completed',
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        if (widget.task.id == null) {
                          throw Exception('Task ID is missing');
                        }

                        await _taskService.markTaskAsCompleted(widget.task.id!);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task marked as completed'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    isOutlined: true,
                    backgroundColor: Colors.transparent,
                    textColor: AppTheme.accentColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
