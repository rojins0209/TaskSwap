import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskswap/constants/app_constants.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/custom_button.dart';
import 'package:taskswap/widgets/custom_text_field.dart';

class CreateChallengeScreen extends StatefulWidget {
  final String? initialTaskDescription;
  final int? initialPoints;

  const CreateChallengeScreen({
    super.key,
    this.initialTaskDescription,
    this.initialPoints,
  });

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final FriendService _friendService = FriendService();
  final ChallengeService _challengeService = ChallengeService();

  late final TextEditingController _taskDescriptionController;
  late final TextEditingController _pointsController;

  List<UserModel> _selectedFriends = [];
  bool _isLoading = false;
  bool _bothUsersComplete = false;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _taskDescriptionController = TextEditingController(
      text: widget.initialTaskDescription ?? '',
    );
    _pointsController = TextEditingController(
      text: widget.initialPoints?.toString() ?? AppConstants.defaultChallengePoints.toString(),
    );
  }

  @override
  void dispose() {
    _taskDescriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _sendChallenge() async {
    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one friend'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_taskDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task description'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final points = int.tryParse(_pointsController.text) ?? AppConstants.defaultChallengePoints;
    if (points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Points must be greater than 0'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Enforce maximum points limit
    if (points > AppConstants.maxChallengePoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum points allowed is ${AppConstants.maxChallengePoints}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Send challenge to each selected friend
      for (final friend in _selectedFriends) {
        await _challengeService.sendChallenge(
          friend.id,
          _taskDescriptionController.text,
          points: points,
          bothUsersComplete: _bothUsersComplete,
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
        Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Challenge',
          style: AppTheme.headingSmall,
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Friends',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Friend selector
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
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final friends = snapshot.data ?? [];

                if (friends.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: AppTheme.accentColor.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'You need to add friends first',
                            style: AppTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate to friends screen
                              // This will be implemented later
                            },
                            child: Text(
                              'Add Friends',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dividerColor),
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
                                backgroundColor: AppTheme.accentColor.withAlpha(25),
                                deleteIconColor: AppTheme.accentColor,
                                labelStyle: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Divider if there are selected friends
                      if (_selectedFriends.isNotEmpty)
                        const Divider(height: 1),

                      // Friend list
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
                              activeColor: AppTheme.accentColor,
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

            const SizedBox(height: 24),

            // Task description
            Text(
              'Task Description',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _taskDescriptionController,
              label: 'Task Description',
              hint: 'Enter task description',
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Points
            Text(
              'Points',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _pointsController,
              label: 'Points',
              hint: 'Enter points',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // Both users complete option
            Text(
              'Challenge Options',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Both users complete option
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Both of us need to complete this task',
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _bothUsersComplete,
                        onChanged: (value) {
                          setState(() {
                            _bothUsersComplete = value;
                          });
                        },
                        activeColor: AppTheme.accentColor,
                      ),
                    ],
                  ),

                  // Due date option
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Set a due date',
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              _dueDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          _dueDate != null
                              ? DateFormat('MMM d, yyyy').format(_dueDate!)
                              : 'Select Date',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                            });
                          },
                          color: AppTheme.textSecondaryColor,
                          iconSize: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Send button
            CustomButton(
              text: _selectedFriends.isEmpty
                  ? 'Send Challenge'
                  : _selectedFriends.length == 1
                      ? 'Send Challenge'
                      : 'Send Challenges to ${_selectedFriends.length} Friends',
              onPressed: _sendChallenge,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
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
