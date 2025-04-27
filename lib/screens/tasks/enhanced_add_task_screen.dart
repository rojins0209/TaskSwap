import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/constants/app_constants.dart';
import 'package:taskswap/main.dart'; // Import for navigatorKey
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/auth_service.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/utils/haptic_feedback_util.dart';
import 'package:intl/intl.dart';

// Custom TextField Widget
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? hint;
  final TextEditingController controller;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool enabled;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hintText,
    this.hint,
    required this.controller,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.enabled = true,
    this.decoration,
    this.textInputAction,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          focusNode: focusNode,
          autofocus: autofocus,
          readOnly: readOnly,
          onTap: onTap,
          enabled: enabled,
          textInputAction: textInputAction,
          decoration: decoration ?? InputDecoration(
            hintText: hintText ?? hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              child: _buildButtonContent(colorScheme.primary),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? colorScheme.primary,
                foregroundColor: textColor ?? colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              child: _buildButtonContent(textColor ?? colorScheme.onPrimary),
            ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }
}

// Date Time Picker Widget
class DateTimePicker extends StatefulWidget {
  final DateTime? selectedDateTime;
  final Function(DateTime?) onDateTimeSelected;
  final String label;
  final bool allowRemoval;

  const DateTimePicker({
    Key? key,
    this.selectedDateTime,
    required this.onDateTimeSelected,
    required this.label,
    this.allowRemoval = true,
  }) : super(key: key);

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _hasTime = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDateTime != null) {
      _selectedDate = widget.selectedDateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.selectedDateTime!);
      _hasTime = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (_selectedDate != null && widget.allowRemoval)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _selectedTime = null;
                        _hasTime = false;
                      });
                      widget.onDateTimeSelected(null);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuickDateButton('Today', DateTime.now()),
            const SizedBox(width: 8),
            _buildQuickDateButton('Tomorrow', DateTime.now().add(const Duration(days: 1))),
            const SizedBox(width: 8),
            _buildQuickDateButton('Next Week', DateTime.now().add(const Duration(days: 7))),
          ],
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showTimePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _hasTime && _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Add time (optional)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (_hasTime && _selectedTime != null)
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedTime = null;
                                _hasTime = false;
                              });
                              widget.onDateTimeSelected(_selectedDate);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickDateButton(String label, DateTime date) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          HapticFeedbackUtil.lightImpact();
          setState(() {
            _selectedDate = date;
            _selectedTime = null;
            _hasTime = false;
          });
          widget.onDateTimeSelected(_selectedDate);
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    HapticFeedbackUtil.lightImpact();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });

      DateTime dateTimeToReturn = pickedDate;
      if (_hasTime && _selectedTime != null) {
        dateTimeToReturn = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      widget.onDateTimeSelected(dateTimeToReturn);
    }
  }

  Future<void> _showTimePicker() async {
    HapticFeedbackUtil.lightImpact();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _hasTime = true;
      });

      if (_selectedDate != null) {
        final dateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        widget.onDateTimeSelected(dateTime);
      }
    }
  }
}

class EnhancedAddTaskScreen extends StatefulWidget {
  const EnhancedAddTaskScreen({super.key});

  @override
  State<EnhancedAddTaskScreen> createState() => _EnhancedAddTaskScreenState();
}

class _EnhancedAddTaskScreenState extends State<EnhancedAddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController(text: AppConstants.defaultTaskPoints.toString());

  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isChallenge = false;
  final List<UserModel> _selectedFriends = [];
  TaskCategory _selectedCategory = TaskCategory.personal;
  bool _challengeYourself = false;
  int? _timerDuration;

  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final FriendService _friendService = FriendService();
  final ChallengeService _challengeService = ChallengeService();

  @override
  void initState() {
    super.initState();

    // Check if we were passed arguments to pre-select options
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        if (args['isChallenge'] == true) {
          setState(() {
            _isChallenge = true;
          });
        }
        if (args['challengeYourself'] == true) {
          setState(() {
            _challengeYourself = true;
          });
        }
      }
    });
  }

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

    if (_isChallenge && _selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one friend to challenge'),
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

      if (_isChallenge) {
        // Get friend IDs for the task
        final List<String> friendIds = _selectedFriends.map((friend) => friend.id).toList();

        // Create a challenge task first
        final challengeTask = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          createdBy: userId,
          points: int.parse(_pointsController.text),
          category: _selectedCategory,
          isChallenge: true,
          challengeFriends: friendIds,
          timerDuration: _timerDuration,
          challengeYourself: _challengeYourself,
        );

        // Save the challenge task
        await _taskService.createTask(challengeTask);

        // Create challenges for each selected friend
        for (final friend in _selectedFriends) {
          await _challengeService.sendChallenge(
            friend.id,
            _titleController.text.trim() + (_descriptionController.text.isNotEmpty ? ': ${_descriptionController.text.trim()}' : ''),
            points: int.parse(_pointsController.text),
            category: _selectedCategory,
            timerDuration: _timerDuration,
            challengeYourself: _challengeYourself,
            dueDate: _dueDate,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Challenge${_selectedFriends.length > 1 ? 's' : ''} sent successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        // Create a personal task
        final task = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          createdBy: userId,
          points: int.parse(_pointsController.text),
          category: _selectedCategory,
          isChallenge: false, // Explicitly set to false for personal tasks
          challengeYourself: false,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isChallenge ? 'Create Challenge' : 'Create Task',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withAlpha(15),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondary.withAlpha(10),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 100.0), // Extra bottom padding for the button
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Type Selector
                    _buildTaskTypeSelector(),
                    const SizedBox(height: 32),

                    // Title Field with modern styling
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withAlpha(5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title Field
                          CustomTextField(
                            controller: _titleController,
                            label: _isChallenge ? 'Challenge Title' : 'Task Title',
                            hint: _isChallenge ? 'Enter challenge title' : 'Enter task title',
                            prefixIcon: Icon(
                              Icons.title,
                              color: colorScheme.primary,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Description Field
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Description (Optional)',
                            hint: _isChallenge ? 'Enter challenge description' : 'Enter task description',
                            prefixIcon: Icon(
                              Icons.description_outlined,
                              color: colorScheme.primary,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),

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
                          const SizedBox(height: 20),

                          // Points Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: _pointsController,
                                label: _isChallenge ? 'Challenge Points' : 'Recognition Points',
                                hint: _isChallenge
                                    ? 'Enter points for this challenge'
                                    : 'Enter points friends can award you',
                                prefixIcon: Icon(
                                  Icons.stars,
                                  color: colorScheme.primary,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter points';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  final points = int.parse(value);
                                  if (points <= 0) {
                                    return 'Points must be greater than 0';
                                  }
                                  if (_isChallenge && points > AppConstants.maxChallengePoints) {
                                    return 'Maximum points for challenges is ${AppConstants.maxChallengePoints}';
                                  }
                                  return null;
                                },
                              ),
                              if (!_isChallenge) ...[  // Only show for personal tasks
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withAlpha(50),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colorScheme.primary.withAlpha(50)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Personal tasks don\'t award points automatically. When you complete a task, you can share it with friends who can recognize your achievement.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Category Selector
                    const SizedBox(height: 32),
                    _buildCategorySelector(),

                    // Challenge options
                    if (_isChallenge) ...[
                      const SizedBox(height: 32),
                      _buildFriendSelector(),
                      const SizedBox(height: 32),
                      _buildChallengeOptions(),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isChallenge ? Icons.send : Icons.add_task,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isChallenge ? 'Send Challenge' : 'Create Task',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTypeSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to create?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),

        // Modern segmented control
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Personal Task Option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Always update state when tapped, even if already selected
                      // This ensures proper UI refresh
                      setState(() {
                        _isChallenge = false;
                        // Reset selected friends when switching to personal task
                        _selectedFriends.clear();
                      });
                      HapticFeedbackUtil.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: !_isChallenge
                            ? colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: !_isChallenge ? [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: !_isChallenge
                                  ? colorScheme.primary.withAlpha(40)
                                  : colorScheme.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 28,
                              color: !_isChallenge
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Personal Task',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: !_isChallenge ? FontWeight.bold : FontWeight.normal,
                              color: !_isChallenge
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Challenge Friends Option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Always update state when tapped, even if already selected
                      // This ensures proper UI refresh
                      setState(() {
                        _isChallenge = true;
                      });
                      HapticFeedbackUtil.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _isChallenge
                            ? colorScheme.secondaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isChallenge ? [
                          BoxShadow(
                            color: colorScheme.secondary.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isChallenge
                                  ? colorScheme.secondary.withAlpha(40)
                                  : colorScheme.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_events_outlined,
                              size: 28,
                              color: _isChallenge
                                  ? colorScheme.secondary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Challenge Friends',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: _isChallenge ? FontWeight.bold : FontWeight.normal,
                              color: _isChallenge
                                  ? colorScheme.secondary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Friends to Challenge',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<UserModel>>(
          stream: _friendService.getFriends(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading friends: ${snapshot.error}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                ),
              );
            }

            final friends = snapshot.data ?? [];

            if (friends.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No friends found',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add friends to challenge them',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Add Friends',
                      onPressed: () {
                        // Use the global navigator key to navigate
                        navigatorKey.currentState?.pushNamed('/friends');
                      },
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                children: [
                  // Selected friends chips
                  if (_selectedFriends.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedFriends.map((friend) {
                          return Chip(
                            label: Text(friend.email),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedFriends.remove(friend);
                              });
                            },
                            backgroundColor: colorScheme.primary.withAlpha(25),
                            deleteIconColor: colorScheme.primary,
                            labelStyle: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Divider if there are selected friends
                  if (_selectedFriends.isNotEmpty)
                    const Divider(height: 1),

                  // Friends list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected = _selectedFriends.contains(friend);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAvatarColor(friend.email),
                          child: Text(
                            friend.email.isNotEmpty ? friend.email[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(friend.email),
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: colorScheme.primary,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!_selectedFriends.contains(friend)) {
                                  _selectedFriends.add(friend);
                                }
                              } else {
                                _selectedFriends.remove(friend);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriends.remove(friend);
                            } else {
                              _selectedFriends.add(friend);
                            }
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Category',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Modern grid layout for categories
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            TaskCategory.work,
            TaskCategory.health,
            TaskCategory.learning,
            TaskCategory.personal,
          ].map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                HapticFeedbackUtil.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? category.color.withAlpha(40) : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? category.color : colorScheme.outline.withAlpha(128),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: category.color.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Stack(
                  children: [
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category.icon,
                            size: 32,
                            color: isSelected ? category.color : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: isSelected ? category.color : colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChallengeOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Challenge Options',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // Modern card with options
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Challenge yourself with friend option
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _challengeYourself
                      ? colorScheme.secondaryContainer.withAlpha(100)
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _challengeYourself
                        ? colorScheme.secondary.withAlpha(100)
                        : colorScheme.outline.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _challengeYourself
                            ? colorScheme.secondaryContainer
                            : colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 20,
                        color: _challengeYourself
                            ? colorScheme.secondary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge yourself with friends',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You and your friends will compete on the same task',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _challengeYourself,
                      onChanged: (value) {
                        setState(() {
                          _challengeYourself = value;
                        });
                        HapticFeedbackUtil.lightImpact();
                      },
                      activeColor: colorScheme.secondary,
                      activeTrackColor: colorScheme.secondaryContainer,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Timer option
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _timerDuration != null
                      ? colorScheme.tertiaryContainer.withAlpha(100)
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _timerDuration != null
                        ? colorScheme.tertiary.withAlpha(100)
                        : colorScheme.outline.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _timerDuration != null
                            ? colorScheme.tertiaryContainer
                            : colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: _timerDuration != null
                            ? colorScheme.tertiary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set a timer',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time limit in minutes (optional)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Minutes',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _timerDuration != null
                                  ? colorScheme.tertiary.withAlpha(100)
                                  : colorScheme.outline.withAlpha(50),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.tertiary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: _timerDuration != null
                              ? colorScheme.tertiaryContainer.withAlpha(50)
                              : colorScheme.surfaceContainerLow,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _timerDuration = value.isNotEmpty ? int.tryParse(value) : null;
                          });
                          HapticFeedbackUtil.lightImpact();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAvatarColor(String email) {
    // Generate a consistent color based on the email
    final int hash = email.hashCode;
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepPurple,
    ];

    return colors[hash.abs() % colors.length];
  }
}
