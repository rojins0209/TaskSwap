import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/models/activity_model.dart';

import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/services/activity_service.dart';
import 'package:taskswap/services/follower_service.dart';

import 'package:taskswap/services/stats_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/activity_card.dart';
import 'package:taskswap/widgets/give_aura_dialog.dart';
import 'package:taskswap/widgets/level_progress.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';

// Removed unused import: import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taskswap/widgets/user_avatar.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final UserModel? initialUserData;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialUserData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final ActivityService _activityService = ActivityService();
  final FollowerService _followerService = FollowerService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoading = true;

  int _followerCount = 0;
  int _followingCount = 0;
  String _activityFilter = 'All';

  // Stream subscriptions
  StreamSubscription? _followerCountSubscription;
  StreamSubscription? _followingCountSubscription;
  StreamSubscription? _userStreamSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _checkFollowingStatus();
    _loadFollowerCounts();

    // Initialize the broadcast stream
    _userStream = _userService.getUserStream(widget.userId).asBroadcastStream();

    // Set up a listener that we'll keep alive for the widget's lifetime
    _userStreamSubscription = _userStream.listen((user) {
      // This empty listener ensures the stream stays active
      // The actual data is handled by the StreamBuilder
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _followerCountSubscription?.cancel();
    _followingCountSubscription?.cancel();
    _userStreamSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Create broadcast stream that can be listened to multiple times
  late final Stream<UserModel?> _userStream;

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _checkFollowingStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isFriend = await _followerService.isFollowing(widget.userId);
      if (mounted) {
        setState(() {
          _isFollowing = isFriend;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking friend status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFollowerCounts() async {
    // Cancel any existing subscriptions
    _followerCountSubscription?.cancel();
    _followingCountSubscription?.cancel();

    // Set up new subscriptions
    _followerCountSubscription = _followerService.getFollowerCount(widget.userId).listen((count) {
      if (mounted) {
        setState(() {
          _followerCount = count;
        });
      }
    });

    _followingCountSubscription = _followerService.getFollowingCount(widget.userId).listen((count) {
      if (mounted) {
        setState(() {
          _followingCount = count;
        });
      }
    });
  }

  Future<void> _toggleFollow() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFollowing) {
        await _followerService.unfollowUser(widget.userId);
      } else {
        await _followerService.followUser(widget.userId);
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error toggling friend status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _refreshProfile() async {
    // Refresh profile data
    await Future.wait([
      _checkFollowingStatus(),
      _loadFollowerCounts(),
      Future.delayed(const Duration(milliseconds: 800)), // Minimum refresh time for better UX
    ]);

    // Clear cached activities to force a refresh
    if (mounted) {
      setState(() {
        _cachedActivities = null;
      });
    }
  }

  void _showGiveAuraDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => GiveAuraDialog(
        receiverId: widget.userId,
        onAuraGiven: () {
          // Refresh the profile after giving aura
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Aura gifted successfully!'),
                backgroundColor: AppTheme.accentColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final isCurrentUser = currentUser != null && currentUser.uid == widget.userId;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: StreamBuilder<UserModel?>(
          stream: _userStream,
          initialData: widget.initialUserData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final userProfile = snapshot.data;

            if (userProfile == null) {
              return _buildUserNotFoundState();
            }

            return NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildProfileAppBar(userProfile, isCurrentUser),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Stats row
                        _buildStatsRow(userProfile),

                        // Bio section
                        // Bio section is not available in the current UserModel
                        // Uncomment when bio field is added to UserModel
                        // if (userProfile.bio != null && userProfile.bio!.isNotEmpty)
                        //   _buildBioSection(userProfile.bio!),

                        // Give Aura button (if not current user)
                        if (!isCurrentUser)
                          _buildGiveAuraButton(),

                        // Tab bar
                        _buildTabBar(),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Activity tab
                  _buildActivityTab(userProfile),

                  // Achievements tab
                  _buildAchievementsTab(userProfile),

                  // Stats tab
                  _buildStatsTab(userProfile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardColor,
      highlightColor: AppTheme.cardColor.withAlpha(51),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) =>
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
            ),
            const SizedBox(height: 32),
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor.withAlpha(179),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _refreshProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 24),
          Text(
            'User Not Found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The user profile you are looking for does not exist or has been removed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildProfileAppBar(UserModel userProfile, bool isCurrentUser) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        title: Container(),
        background: Stack(
          children: [
            // Background color
            Container(
              color: colorScheme.primary.withAlpha(230),
            ),
            // Content container
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with back button and user's avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button is already in the app bar
                        const SizedBox(width: 40),
                        const Spacer(),
                        // User avatar in top right
                        Hero(
                          tag: 'profile-avatar-mini-${widget.userId}',
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: UserAvatar(
                              displayName: userProfile.displayName,
                              email: userProfile.email,
                              radius: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // User name in large text
                    Text(
                      userProfile.displayName?.toUpperCase() ??
                      userProfile.email.split('@')[0].toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        height: 0.9,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // User description - show streak for everyone, aura points only for friends/self
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${userProfile.streakCount} day streak',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withAlpha(204),
                          ),
                        ),
                        // Only show aura points for friends or self
                        if (isCurrentUser || _isFollowing) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${userProfile.auraPoints} aura points',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha(204),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action buttons row
                    Row(
                      children: [
                        // Primary action button
                        if (!isCurrentUser)
                          _buildActionButton(
                            label: _isFollowing ? 'FRIENDS' : 'ADD FRIEND',
                            backgroundColor: Colors.amber,
                            textColor: Colors.black87,
                            onPressed: _toggleFollow,
                            isLoading: _isLoading,
                          ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isCurrentUser) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 16, top: 8),
            child: FloatingActionButton(
              heroTag: 'friend-button',
              onPressed: _isLoading ? null : _toggleFollow,
              mini: true,
              tooltip: _isFollowing ? 'Remove friend' : 'Add friend',
              backgroundColor: _isFollowing ? Colors.white : colorScheme.primary,
              foregroundColor: _isFollowing ? colorScheme.primary : Colors.white,
              elevation: 3,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(
                      _isFollowing ? Icons.person_remove : Icons.person_add,
                      size: 20,
                    ),
            ),
          ),
        ],

      ],
    );
  }

  // Avatar fallback method removed as we're using UserAvatar widget

  Widget _buildStatsRow(UserModel userProfile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Followers section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Friends',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Navigate to followers list
                  },
                  child: Text(
                    'View all',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Follower stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Friends',
                    '$_followerCount',
                    Icons.people,
                    Colors.blue[400]!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Following',
                    '$_followingCount',
                    Icons.person_add,
                    Colors.teal[400]!,
                  ),
                ),
              ],
            ),
          ),

          // Recent activity section
          _isFollowing || _auth.currentUser!.uid.contains(widget.userId)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Recent activity cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FutureBuilder<List<Activity>>(
                        future: _activityService.getUserActivitiesFuture(widget.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outlineVariant.withAlpha(50), width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  'Could not load activities',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                              ),
                            );
                          }

                          final activities = snapshot.data ?? [];

                          if (activities.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outlineVariant.withAlpha(50), width: 1),
                              ),
                              child: Center(
                                child: Text(
                                  'No recent activities',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colorScheme.outlineVariant.withAlpha(50), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Show only the first 2 activities
                                for (int i = 0; i < min(2, activities.length); i++) ...[
                                  _buildActivityItemFromActivity(activities[i]),
                                  if (i < min(2, activities.length) - 1)
                                    const Divider(height: 24),
                                ],

                                // Show "See all" button if there are more than 2 activities
                                if (activities.length > 2) ...[
                                  const Divider(height: 24),
                                  TextButton.icon(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      // Switch to the Activity tab
                                      _tabController.animateTo(0);
                                    },
                                    icon: Icon(
                                      Icons.expand_more,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    label: Text(
                                      'See all ${activities.length} activities',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(50), width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add as friend to see more',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add this user as a friend to see their recent activities and detailed stats.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Add Friend'),
                        ),
                      ],
                    ),
                  ),
                ),

          // Only show Give Aura button if not current user
          if (!_auth.currentUser!.uid.contains(widget.userId))
            Container(
              margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showGiveAuraDialog,
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Give Aura',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItemFromActivity(Activity activity) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine icon and color based on activity type
    IconData icon;
    Color color;
    String title;
    String subtitle = '';

    // Set icon, color, and title based on activity type
    if (activity.type == ActivityType.taskCompleted) {
      icon = Icons.task_alt;
      color = Colors.green[400]!;
      title = 'Completed a task';
    } else if (activity.type == ActivityType.challengeCompleted) {
      icon = Icons.emoji_events;
      color = Colors.amber[600]!;
      title = 'Completed a challenge';
    } else if (activity.type == ActivityType.achievementEarned) {
      icon = Icons.emoji_events;
      color = Colors.orange[400]!;
      title = 'Earned an achievement';
    } else if (activity.type == ActivityType.auraReceived) {
      icon = Icons.auto_awesome;
      color = Colors.purple[400]!;
      title = 'Received aura points';
    } else if (activity.type == ActivityType.auraGiven) {
      icon = Icons.favorite;
      color = Colors.red[400]!;
      title = 'Gave aura points';
    } else if (activity.type == ActivityType.friendAdded) {
      icon = Icons.person_add;
      color = Colors.blue[400]!;
      title = 'Added a friend';
    } else {
      // Fallback for any future activity types
      icon = Icons.star;
      color = Colors.indigo[400]!;
      title = activity.title ?? 'Activity';
    }

    // Set subtitle from activity description
    subtitle = activity.description ?? '';

    // Format time
    String timeText = 'Recently';
    if (activity.timestamp != null) {
      final now = DateTime.now();
      final difference = now.difference(activity.timestamp!);

      if (difference.inMinutes < 1) {
        timeText = 'Just now';
      } else if (difference.inHours < 1) {
        timeText = '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        timeText = '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        timeText = '${difference.inDays}d ago';
      } else {
        timeText = DateFormat('MMM d').format(activity.timestamp!);
      }
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          timeText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }



  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(50), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }





  // Removed unused method

  // Removed unused method

  // Bio section method removed as it's not used in the current implementation

  Widget _buildGiveAuraButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showGiveAuraDialog,
        icon: const Icon(Icons.auto_awesome, size: 22),
        label: const Text(
          'Give Aura Points',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: colorScheme.primary.withAlpha(102),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withAlpha(25)),
          bottom: BorderSide(color: colorScheme.outline.withAlpha(25)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: theme.textTheme.bodyMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tabs: const [
          Tab(text: 'Tasks'),
          Tab(text: 'Challenges'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  // Cache for activities to avoid stream issues
  List<Activity>? _cachedActivities;

  Widget _buildActivityTab(UserModel userProfile) {
    // If we don't have cached activities yet, fetch them once
    if (_cachedActivities == null) {
      return FutureBuilder<List<Activity>>(
        future: _activityService.getUserActivitiesFuture(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Theme.of(context).colorScheme.error.withAlpha(179),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading activities',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          // Cache the activities
          _cachedActivities = snapshot.data ?? [];

          // Now build the UI with the cached data
          return _buildActivityTabContent(userProfile, _cachedActivities!);
        },
      );
    } else {
      // Use cached activities
      return _buildActivityTabContent(userProfile, _cachedActivities!);
    }
  }

  Widget _buildActivityTabContent(UserModel userProfile, List<Activity> activities) {
    return Column(
      children: [
        // Activity filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', Icons.list),
                _buildFilterChip('Tasks', Icons.task),
                _buildFilterChip('Challenges', Icons.flag),
                _buildFilterChip('Rewards', Icons.card_giftcard),
              ],
            ),
          ),
        ),

        // Activity list
        Expanded(
          child: Builder(builder: (context) {
            // Filter activities based on selected filter
            List<Activity> filteredActivities = activities;
            if (_activityFilter != 'All') {
              filteredActivities = activities.where((activity) {
                switch (_activityFilter) {
                  case 'Tasks':
                    return activity.type == ActivityType.taskCompleted;
                  case 'Challenges':
                    return activity.type == ActivityType.challengeCompleted;
                  case 'Rewards':
                    return activity.type == ActivityType.auraReceived;
                  default:
                    return true;
                }
              }).toList();
            }

            if (filteredActivities.isEmpty) {
              return _buildEmptyState(
                icon: Icons.history,
                title: activities.isEmpty ? 'No Activity Yet' : 'No $_activityFilter Activities',
                message: activities.isEmpty
                    ? 'This user hasn\'t recorded any activity yet'
                    : 'No $_activityFilter activities to display',
              );
            }

            return ListView.builder(
              itemCount: filteredActivities.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final activity = filteredActivities[index];

                // Group activities by date
                bool showDateHeader = false;
                if (index == 0) {
                  showDateHeader = true;
                } else {
                  final previousDate = filteredActivities[index - 1].timestamp ?? DateTime.now();
                  final currentDate = activity.timestamp ?? DateTime.now();
                  showDateHeader = !_isSameDay(previousDate, currentDate);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader) _buildDateHeader(activity.timestamp ?? DateTime.now()),
                    ActivityCard(
                      activity: activity,
                      showUserInfo: false, // Don't show user info since we're on their profile
                      onActivityUpdated: () {
                        // Refresh when activity is updated
                        HapticFeedback.selectionClick();
                        _refreshProfile();
                      },
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    String dateText;
    IconData iconData;

    if (_isSameDay(date, now)) {
      dateText = 'Today';
      iconData = Icons.today;
    } else if (_isSameDay(date, yesterday)) {
      dateText = 'Yesterday';
      iconData = Icons.history;
    } else if (now.difference(date).inDays < 7) {
      dateText = DateFormat('EEEE').format(date); // Day name
      iconData = Icons.calendar_view_week;
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
      iconData = Icons.calendar_month;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 20, bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              dateText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _activityFilter == label;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          selected: isSelected,
          showCheckmark: false,
          avatar: Icon(
            icon,
            size: 18,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
          label: Text(label),
          labelStyle: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          selectedColor: colorScheme.primary,
          backgroundColor: colorScheme.surfaceContainerLow,
          elevation: isSelected ? 2 : 0,
          pressElevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.transparent : colorScheme.outline.withAlpha(30),
              width: 1,
            ),
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _activityFilter = label;
              });
              HapticFeedback.selectionClick();
            }
          },
        ),
      ),
    );
  }

  Widget _buildAchievementsTab(UserModel userProfile) {
    final achievements = userProfile.achievements ?? [];

    if (achievements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No Achievements Yet',
        message: 'This user hasn\'t earned any achievements yet',
      );
    }

    // Organize achievements by category
    final Map<String, List<String>> categorizedAchievements = {
      'Streaks': achievements.where((a) => a.contains('Streak') || a.contains('Days')).toList(),
      'Tasks': achievements.where((a) => a.contains('Task') || a.contains('Complete')).toList(),
      'Social': achievements.where((a) => a.contains('Social') || a.contains('Friend') || a.contains('Follow')).toList(),
      'Challenges': achievements.where((a) => a.contains('Challenge') || a.contains('Champion')).toList(),
      'Other': achievements.where((a) =>
        !a.contains('Streak') &&
        !a.contains('Days') &&
        !a.contains('Task') &&
        !a.contains('Complete') &&
        !a.contains('Social') &&
        !a.contains('Friend') &&
        !a.contains('Follow') &&
        !a.contains('Challenge') &&
        !a.contains('Champion')
      ).toList(),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Achievement Progress Card
        _buildAchievementProgress(userProfile, achievements.length),

        // Categorized Achievements
        ...categorizedAchievements.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  children: [
                    _getCategoryIcon(entry.key),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((achievement) => _buildAchievementChip(achievement)).toList(),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData iconData;
    Color color;

    switch (category) {
      case 'Streaks':
        iconData = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case 'Tasks':
        iconData = Icons.task_alt;
        color = Colors.green;
        break;
      case 'Social':
        iconData = Icons.people;
        color = Colors.blue;
        break;
      case 'Challenges':
        iconData = Icons.flag;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.star;
        color = AppTheme.accentColor;
    }

    return Icon(
      iconData,
      color: color,
      size: 24,
    );
  }

  Widget _buildAchievementProgress(UserModel userProfile, int achievementCount) {
    // Mock total possible achievements number
    const int totalPossibleAchievements = 30;
    final double progressPercentage = achievementCount / totalPossibleAchievements;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber[600],
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Achievement Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$achievementCount/$totalPossibleAchievements',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              // Background track
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Progress indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 12,
                width: MediaQuery.of(context).size.width * progressPercentage - 40, // Adjust for padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(40),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progressPercentage * 100).toInt()}% Complete',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${totalPossibleAchievements - achievementCount} remaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementChip(String achievement) {
    IconData iconData;
    Color color;

    // Determine icon and color based on achievement type
    if (achievement.contains('Streak')) {
      iconData = Icons.local_fire_department;
      color = Colors.deepOrange[400]!;
    } else if (achievement.contains('Challenge')) {
      iconData = Icons.emoji_events;
      color = Colors.amber[600]!;
    } else if (achievement.contains('Task') || achievement.contains('Complete')) {
      iconData = Icons.task_alt;
      color = Colors.teal[400]!;
    } else if (achievement.contains('Early') || achievement.contains('Morning')) {
      iconData = Icons.wb_sunny;
      color = Colors.blue[400]!;
    } else if (achievement.contains('Social') || achievement.contains('Friend') || achievement.contains('Follow')) {
      iconData = Icons.people;
      color = Colors.indigo[400]!;
    } else {
      iconData = Icons.star;
      color = Colors.purple[400]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            HapticFeedback.lightImpact();
            // Show achievement details
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _buildAchievementDetailsModal(achievement, iconData, color),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withAlpha(75)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  achievement,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementDetailsModal(String achievement, IconData iconData, Color color) {
    // Mock data for achievement details
    final String description = _getAchievementDescription(achievement);
    final String earnedDate = DateFormat('MMMM d, yyyy').format(DateTime.now().subtract(const Duration(days: 14)));
    final int auraBonus = 25;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Achievement icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(51),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              iconData,
              color: color,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          // Achievement name
          Text(
            achievement,
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Earned info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Earned on $earnedDate',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Aura bonus
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                '+$auraBonus Aura Points',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _getAchievementDescription(String achievement) {
    // Mock descriptions for achievements
    if (achievement.contains('Streak')) {
      return 'Maintained an activity streak for an extended period, showing exceptional consistency and dedication.';
    } else if (achievement.contains('Challenge')) {
      return 'Successfully completed a difficult challenge that tested skills and determination.';
    } else if (achievement.contains('Task')) {
      return 'Demonstrated excellent task management and completion, showing reliability and focus.';
    } else if (achievement.contains('Early') || achievement.contains('Morning')) {
      return 'Consistently active during early morning hours, showing dedication and a productive routine.';
    } else if (achievement.contains('Social') || achievement.contains('Friend') || achievement.contains('Follow')) {
      return 'Built a strong community presence and engaged positively with other users.';
    } else {
      return 'Unlocked a special achievement through unique actions and dedication to personal growth.';
    }
  }

  Widget _buildStatsTab(UserModel userProfile) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: StatsService().getUserStatsStream(userProfile.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Theme.of(context).colorScheme.error.withAlpha(180),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final weeklyActivity = stats['weeklyActivity'] as Map<String, int>? ?? {
          'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
        };
        final completionRate = (stats['completionRate'] as double?) ?? 0.0;
        final averageDailyTasks = (stats['averageDailyTasks'] as double?) ?? 0.0;
        final mostActiveDay = (stats['mostActiveDay'] as String?) ?? 'Unknown';
        final mostActiveTime = (stats['mostActiveTime'] as String?) ?? 'Unknown';
        final taskCategories = stats['taskCategories'] as Map<String, int>? ?? {
          'Work': 25, 'Health': 25, 'Learning': 25, 'Personal': 25
        };
        final streakData = stats['streakData'] as Map<String, dynamic>? ?? {
          'currentStreak': 0, 'longestStreak': 0, 'lastActive': 'Never'
        };

        final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final List<int> activityValues = days.map((day) => weeklyActivity[day] ?? 0).toList();
        final int maxActivityValue = activityValues.isEmpty ? 1 : activityValues.reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Level Progress
            LevelProgress(
              auraPoints: userProfile.auraPoints,
              animate: true,
              showNextLevel: true,
            ),
            const SizedBox(height: 20),

            // Streak Card
            _buildStreakCard(streakData),
            const SizedBox(height: 20),

            // Weekly Activity Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        color: Colors.blue[400],
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Weekly Activity',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        final value = activityValues[index];
                        final double percentage = maxActivityValue > 0 ? value / maxActivityValue : 0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              height: max(150 * percentage, 5), // Minimum height of 5
                              width: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withAlpha(200),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              children: [
                                Text(
                                  value.toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: value > 0 ? Colors.blue[400] : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  days[index],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task Completion and Daily Tasks in a row
            Row(
              children: [
                // Task Completion Rate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _getCardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[400],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Completion Rate',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: completionRate / 100),
                                duration: const Duration(milliseconds: 1500),
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.grey.withAlpha(30),
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                                    strokeWidth: 10,
                                  );
                                },
                              ),
                              Text(
                                '${completionRate.toInt()}%',
                                style: AppTheme.headingMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.green[400]
                                      : Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Daily Tasks
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _getCardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.event_note,
                              color: Colors.blue[400],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Daily Tasks',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: averageDailyTasks),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, value, child) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: AppTheme.headingLarge.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue[400]
                                    : Colors.blue[700],
                              ),
                            );
                          },
                        ),
                        Text(
                          'avg per day',
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Most Active Times
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.orange[400],
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Activity Patterns',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActivityPatternCard(
                          icon: Icons.calendar_today,
                          title: 'Most Active Day',
                          value: mostActiveDay,
                          color: Colors.orange[400]!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActivityPatternCard(
                          icon: Icons.access_time,
                          title: 'Most Active Time',
                          value: mostActiveTime,
                          color: Colors.purple[400]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task Categories
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart,
                        color: Colors.indigo[400],
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Task Categories',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        padding: const EdgeInsets.all(16),
                        child: CustomPaint(
                          painter: PieChartPainter(taskCategories),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Category legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: TaskCategory.values.map((category) {
                      final categoryName = category.name;
                      final categoryValue = taskCategories[categoryName] ?? 0;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$categoryName ($categoryValue)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method for card decoration
  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withAlpha(30),
        width: 1,
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> streakData) {
    final currentStreak = streakData['currentStreak'] as int? ?? 0;
    final longestStreak = streakData['longestStreak'] as int? ?? 0;
    final lastActive = streakData['lastActive'] as String? ?? 'Never';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.deepOrange[400],
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Streak Stats',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakStat(
                title: 'Current Streak',
                value: '$currentStreak days',
                icon: Icons.whatshot,
                color: Colors.deepOrange[400]!,
              ),
              _buildStreakStat(
                title: 'Longest Streak',
                value: '$longestStreak days',
                icon: Icons.emoji_events,
                color: Colors.amber[600]!,
              ),
              _buildStreakStat(
                title: 'Last Active',
                value: lastActive,
                icon: Icons.calendar_today,
                color: Colors.blue[400]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityPatternCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? color.withAlpha(230)
                        : color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          minimumSize: const Size(100, 36),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }


}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final Map<String, dynamic> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    var startAngle = -90.0 * (3.14159 / 180);
    int total = 0;
    for (var value in data.values) {
      total += value as int;
    }

    // Map category names to their colors
    final Map<String, Color> categoryColors = {};
    for (var category in TaskCategory.values) {
      categoryColors[category.name] = category.color;
    }

    // Fallback colors if category not found
    final fallbackColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.indigo, Colors.amber];
    int colorIndex = 0;

    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * 3.14159;

      // Use category color if available, otherwise use fallback
      final color = categoryColors[key] ?? fallbackColors[colorIndex % fallbackColors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
      colorIndex++;
    });

    // Draw inner circle for donut chart effect
    final BuildContext? context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
    final Color innerColor;

    if (context != null) {
      final theme = Theme.of(context);
      // Use explicit colors based on theme brightness
      innerColor = theme.brightness == Brightness.dark
          ? theme.cardTheme.color ?? Colors.grey.shade800 // Dark mode container
          : theme.cardTheme.color ?? Colors.white; // Light mode container
    } else {
      // Fallback color if context is not available
      innerColor = Colors.grey.shade200;
    }

    // Draw shadow for 3D effect
    canvas.drawCircle(
      center,
      radius * 0.65,
      Paint()
        ..color = Colors.black.withAlpha(20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      center,
      radius * 0.6,
      Paint()..color = innerColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}