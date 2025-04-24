import 'package:flutter/material.dart';
import 'package:taskswap/constants/app_constants.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/auth_service.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/widgets/custom_button.dart';
import 'package:taskswap/widgets/custom_text_field.dart';
import 'package:taskswap/widgets/date_time_picker.dart';

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
        // Create challenges for each selected friend
        for (final friend in _selectedFriends) {
          await _challengeService.sendChallenge(
            friend.id,
            _titleController.text.trim() + (_descriptionController.text.isNotEmpty ? ': ${_descriptionController.text.trim()}' : ''),
            points: int.parse(_pointsController.text),
            category: _selectedCategory,
            timerDuration: _timerDuration,
            challengeYourself: _challengeYourself,
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
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
                // Task Type Selector
                _buildTaskTypeSelector(),
                const SizedBox(height: 24),

                // Title Field
                CustomTextField(
                  controller: _titleController,
                  label: _isChallenge ? 'Challenge Title' : 'Task Title',
                  hint: _isChallenge ? 'Enter challenge title' : 'Enter task title',
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
                  hint: _isChallenge ? 'Enter challenge description' : 'Enter task description',
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
                      label: _isChallenge ? 'Challenge Points' : 'Recognition Points',
                      hint: _isChallenge
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

                // Category Selector
                const SizedBox(height: 24),
                _buildCategorySelector(),

                // Challenge options
                if (_isChallenge) ...[
                  const SizedBox(height: 24),
                  _buildFriendSelector(),
                  const SizedBox(height: 24),
                  _buildChallengeOptions(),
                ],

                const SizedBox(height: 40),

                // Create Button
                CustomButton(
                  text: _isChallenge ? 'Send Challenge' : 'Create Task',
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

  Widget _buildTaskTypeSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to create?',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTaskTypeCard(
                title: 'Personal Task',
                icon: Icons.check_circle_outline,
                isSelected: !_isChallenge,
                onTap: () {
                  setState(() {
                    _isChallenge = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTaskTypeCard(
                title: 'Challenge Friends',
                icon: Icons.emoji_events_outlined,
                isSelected: _isChallenge,
                onTap: () {
                  setState(() {
                    _isChallenge = true;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withAlpha(25) : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                        // Navigate to friends screen
                        Navigator.pushNamed(context, '/friends');
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
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  TaskCategory.work,
                  TaskCategory.health,
                  TaskCategory.learning,
                  TaskCategory.personal,
                ].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 18,
                            color: isSelected ? Colors.white : category.color,
                          ),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      selectedColor: category.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
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
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: [
              // Challenge yourself with friend option
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Challenge yourself with friend',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: _challengeYourself,
                    onChanged: (value) {
                      setState(() {
                        _challengeYourself = value;
                      });
                    },
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timer option
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Set a timer (minutes)',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Optional',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _timerDuration = value.isNotEmpty ? int.tryParse(value) : null;
                        });
                      },
                    ),
                  ),
                ],
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
