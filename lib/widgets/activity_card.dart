import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/models/activity_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/services/activity_service.dart';
import 'package:taskswap/screens/profile/user_profile_screen.dart';
import 'package:taskswap/widgets/activity_options_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityCard extends StatefulWidget {
  final Activity activity;
  final bool showUserInfo;
  final VoidCallback? onActivityUpdated;

  const ActivityCard({
    super.key,
    required this.activity,
    this.showUserInfo = true,
    this.onActivityUpdated,
  });

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showUserInfo) {
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _userService.getUserById(widget.activity.userId);
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    // Add haptic feedback
    HapticFeedback.selectionClick();

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final activityId = widget.activity.id;
      if (activityId == null) {
        throw Exception('Activity ID is missing');
      }

      final isLiked = widget.activity.likedBy.contains(currentUser.uid);

      if (isLiked) {
        await _activityService.unlikeActivity(activityId);
      } else {
        await _activityService.likeActivity(activityId);
        // Add stronger haptic feedback for likes
        HapticFeedback.lightImpact();
      }

      widget.onActivityUpdated?.call();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToUserProfile() {
    if (_user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: _user!.id,
          initialUserData: _user,
        ),
      ),
    );
  }

  void _showOptionsDialog() {
    if (widget.activity.id == null) return;
    if (!mounted) return;

    // Use a local variable to avoid closure issues
    final activity = widget.activity;
    final callback = widget.onActivityUpdated;

    showDialog(
      context: context,
      builder: (context) => ActivityOptionsDialog(
        activity: activity,
        onActivityUpdated: () {
          // Check if the widget is still mounted before calling the callback
          if (mounted) {
            callback?.call();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final isLiked = currentUser != null && widget.activity.likedBy.contains(currentUser.uid);
    final likeCount = widget.activity.likedBy.length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: colorScheme.surfaceTint.withAlpha(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.showUserInfo && _user != null ? _navigateToUserProfile : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info (if showing)
                if (widget.showUserInfo && _user != null)
                  GestureDetector(
                    onTap: _navigateToUserProfile,
                    child: Row(
                      children: [
                        CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(51),
                      backgroundImage: _user!.photoUrl != null && _user!.photoUrl!.isNotEmpty && _user!.photoUrl!.startsWith('http')
                          ? NetworkImage(_user!.photoUrl!)
                          : null,
                      child: _user!.photoUrl == null || _user!.photoUrl!.isEmpty || !_user!.photoUrl!.startsWith('http')
                          ? Text(
                              _user!.displayName?.isNotEmpty == true
                                  ? _user!.displayName![0].toUpperCase()
                                  : _user!.email[0].toUpperCase(),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user!.displayName ?? 'User',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (widget.activity.timestamp != null)
                            Text(
                              DateFormat.yMMMd().add_jm().format(widget.activity.timestamp!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),

                    // Options menu for user's own activities
                    if (currentUser != null && widget.activity.userId == currentUser.uid && widget.activity.id != null)
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _showOptionsDialog();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),

            if (widget.showUserInfo && _user != null)
              const SizedBox(height: 12),

            // Activity content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.activity.title ?? _getDefaultTitle(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (widget.activity.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.activity.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      if (widget.activity.points != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${widget.activity.points} points',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Timestamp (if not showing user info)
                      if (!widget.showUserInfo && widget.activity.timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat.yMMMd().add_jm().format(widget.activity.timestamp!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),

                // Options menu for user's own activities (when not showing user info)
                if (!widget.showUserInfo && currentUser != null && widget.activity.userId == currentUser.uid && widget.activity.id != null)
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _showOptionsDialog();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            // Like button and count
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (likeCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '$likeCount ${likeCount == 1 ? 'like' : 'likes'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  IconButton(
                    onPressed: _isLoading ? null : _toggleLike,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIcon() {
    IconData iconData;
    Color color;

    switch (widget.activity.type) {
      case ActivityType.taskCompleted:
        iconData = Icons.task_alt;
        color = Colors.green;
        break;
      case ActivityType.challengeCompleted:
        iconData = Icons.emoji_events;
        color = Colors.amber;
        break;
      case ActivityType.auraGiven:
        iconData = Icons.auto_awesome;
        color = Theme.of(context).colorScheme.primary;
        break;
      case ActivityType.auraReceived:
        iconData = Icons.auto_awesome;
        color = Theme.of(context).colorScheme.primary;
        break;
      case ActivityType.achievementEarned:
        iconData = Icons.star;
        color = Colors.purple;
        break;
      case ActivityType.friendAdded:
        iconData = Icons.people;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: color,
        size: 22,
      ),
    );
  }

  String _getDefaultTitle() {
    switch (widget.activity.type) {
      case ActivityType.taskCompleted:
        return 'Completed a task';
      case ActivityType.challengeCompleted:
        return 'Completed a challenge';
      case ActivityType.auraGiven:
        return 'Gave aura points';
      case ActivityType.auraReceived:
        return 'Received aura points';
      case ActivityType.achievementEarned:
        return 'Earned an achievement';
      case ActivityType.friendAdded:
        return 'Added a friend';
    }
  }
}
