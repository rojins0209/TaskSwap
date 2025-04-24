import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/services/aura_gift_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/models/user_model.dart';

class AuraRecognitionDialog extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const AuraRecognitionDialog({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<AuraRecognitionDialog> createState() => _AuraRecognitionDialogState();
}

class _AuraRecognitionDialogState extends State<AuraRecognitionDialog> {
  final FriendService _friendService = FriendService();
  final AuraGiftService _auraGiftService = AuraGiftService();

  bool _isLoading = true;
  List<UserModel> _friends = [];
  List<String> _selectedFriendIds = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the stream to get friends
      final friendsSnapshot = await _friendService.getFriends().first;
      setState(() {
        _friends = friendsSnapshot;
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFriendSelection(String friendId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  Future<void> _shareTaskWithFriends() async {
    if (_selectedFriendIds.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a notification for each selected friend
      for (final friendId in _selectedFriendIds) {
        await _auraGiftService.notifyFriendOfTaskCompletion(
          friendId: friendId,
          taskId: widget.taskId,
          taskTitle: widget.taskTitle,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error sharing task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing task: $e'),
            behavior: SnackBarBehavior.floating,
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Your Achievement',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Let friends recognize your effort',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In TaskSwap, you earn aura points when friends recognize your completed tasks. Share your achievement with friends to earn aura!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Task completed info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Completed:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.taskTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Friends list
            Text(
              'Select friends to share with:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _friends.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 40,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No friends yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add friends to share your achievements',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            final isSelected = _selectedFriendIds.contains(friend.id);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: friend.photoUrl != null
                                    ? NetworkImage(friend.photoUrl!)
                                    : null,
                                child: friend.photoUrl == null
                                    ? Text(
                                        friend.displayName?.isNotEmpty == true
                                            ? friend.displayName![0].toUpperCase()
                                            : '?',
                                      )
                                    : null,
                              ),
                              title: Text(
                                friend.displayName ?? 'Friend',
                                style: theme.textTheme.bodyLarge,
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleFriendSelection(friend.id),
                                activeColor: colorScheme.primary,
                              ),
                              onTap: () => _toggleFriendSelection(friend.id),
                            );
                          },
                        ),
                      ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _shareTaskWithFriends,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
