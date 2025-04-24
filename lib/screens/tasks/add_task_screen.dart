import 'package:flutter/material.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/services/auth_service.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/custom_button.dart';
import 'package:taskswap/widgets/custom_text_field.dart';
import 'package:taskswap/widgets/date_time_picker.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  
  DateTime? _dueDate;
  bool _isLoading = false;
  
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
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
      final userId = _authService.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final task = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        createdBy: userId,
        points: int.parse(_pointsController.text),
      );

      await _taskService.createTask(task);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully'),
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
            content: Text('Error creating task: ${e.toString()}'),
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
          'Create New Task',
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
                CustomTextField(
                  controller: _pointsController,
                  label: 'Points',
                  hint: 'Enter points for this task',
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
                const SizedBox(height: 40),
                
                // Create Button
                CustomButton(
                  text: 'Create Task',
                  onPressed: _createTask,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
