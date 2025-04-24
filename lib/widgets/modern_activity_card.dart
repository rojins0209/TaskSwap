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
import 'package:timeago/timeago.dart' as timeago;

class ModernActivityCard extends StatefulWidget {
  final Activity activity;
  final bool showUserInfo;
  final VoidCallback? onActivityUpdated;

  const ModernActivityCard({
    super.key,
    required this.activity,
    this.showUserInfo = true,
    this.onActivityUpdated,
  });

  @override
  State<ModernActivityCard> createState() => _ModernActivityCardState();
}

class _ModernActivityCardState extends State<ModernActivityCard> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  bool _isLoading = false;
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showUserInfo) {
      _loadUserInfo();
    }
    
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
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered 
                  ? colorScheme.primary.withAlpha(77) // opacity 0.3
                  : colorScheme.outlineVariant.withAlpha(51), // opacity 0.2
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.showUserInfo && _user != null ? _navigateToUserProfile : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user info and activity icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar (if showing user info)
                      if (widget.showUserInfo && _user != null)
                        GestureDetector(
                          onTap: _navigateToUserProfile,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.primary.withAlpha(51),
                            backgroundImage: _user!.photoUrl != null && _user!.photoUrl!.isNotEmpty && _user!.photoUrl!.startsWith('http')
                                ? NetworkImage(_user!.photoUrl!)
                                : null,
                            child: _user!.photoUrl == null || _user!.photoUrl!.isEmpty || !_user!.photoUrl!.startsWith('http')
                                ? Text(
                                    _user!.displayName?.isNotEmpty == true
                                        ? _user!.displayName![0].toUpperCase()
                                        : _user!.email[0].toUpperCase(),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      
                      if (widget.showUserInfo && _user != null)
                        const SizedBox(width: 12),
                      
                      // Activity content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User name (if showing)
                            if (widget.showUserInfo && _user != null)
                              Row(
                                children: [
                                  Text(
                                    _user!.displayName ?? 'User',
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildActivityTypeChip(),
                                ],
                              ),
                            
                            // Activity title and description
                            Padding(
                              padding: EdgeInsets.only(
                                top: widget.showUserInfo && _user != null ? 4 : 0,
                                bottom: widget.activity.description != null ? 4 : 0,
                              ),
                              child: Text(
                                widget.activity.title ?? _getDefaultTitle(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: widget.showUserInfo && _user != null ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            if (widget.activity.description != null)
                              Text(
                                widget.activity.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            
                            // Points (if available)
                            if (widget.activity.points != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${widget.activity.points} points',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Timestamp
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                widget.activity.timestamp != null
                                    ? timeago.format(widget.activity.timestamp!)
                                    : 'Recently',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Activity icon
                      _buildActivityIcon(),
                    ],
                  ),
                  
                  // Divider and actions
                  if (currentUser != null) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Like button with count
                        Row(
                          children: [
                            IconButton(
                              onPressed: _isLoading ? null : _toggleLike,
                              icon: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                              ),
                              iconSize: 20,
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(36, 36),
                              ),
                            ),
                            if (likeCount > 0)
                              Text(
                                likeCount.toString(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        
                        // Options menu for user's own activities
                        if (currentUser.uid == widget.activity.userId && widget.activity.id != null)
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _showOptionsDialog();
                            },
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(36, 36),
                            ),
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
    );
  }

  Widget _buildActivityTypeChip() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color chipColor;
    String chipText;
    
    switch (widget.activity.type) {
      case ActivityType.taskCompleted:
        chipColor = Colors.green;
        chipText = 'Task';
        break;
      case ActivityType.challengeCompleted:
        chipColor = Colors.amber;
        chipText = 'Challenge';
        break;
      case ActivityType.auraGiven:
        chipColor = colorScheme.primary;
        chipText = 'Aura';
        break;
      case ActivityType.auraReceived:
        chipColor = colorScheme.primary;
        chipText = 'Aura';
        break;
      case ActivityType.achievementEarned:
        chipColor = Colors.purple;
        chipText = 'Achievement';
        break;
      case ActivityType.friendAdded:
        chipColor = Colors.blue;
        chipText = 'Friend';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(26), // opacity 0.1
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        chipText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w500,
          fontSize: 10,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // opacity 0.1
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 18,
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
