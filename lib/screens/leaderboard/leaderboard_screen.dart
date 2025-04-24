import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/screens/profile/user_profile_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/widgets/user_avatar.dart';
import 'package:taskswap/widgets/app_header.dart';

// View filter options
enum ViewFilter { everyone, friends }

// Time period filter options
enum TimePeriodFilter { allTime, month, week }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  // Number of users to display in the leaderboard
  final int _leaderboardLimit = 50;

  // Current user's rank (will be calculated)
  int? _currentUserRank;
  int _totalUsers = 0;

  // Selected filters
  ViewFilter _selectedViewFilter = ViewFilter.everyone;

  // For animations and refresh
  bool _isRefreshing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _refreshLeaderboard();
      }
    });
    _calculateCurrentUserRank();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Calculate the current user's rank
  Future<void> _calculateCurrentUserRank() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Assuming these methods don't actually take a timePeriod parameter
      final rank = await _userService.getUserRank(currentUser.uid);
      final totalUsers = await _userService.getTotalUsersCount();

      if (mounted) {
        // Check if user's rank improved since last time
        final previousRank = _currentUserRank;

        setState(() {
          _currentUserRank = rank;
          _totalUsers = totalUsers;
        });

        // Celebrate rank improvement with confetti
        if (previousRank != null && rank < previousRank && rank <= 10) {
          // Show congratulation message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Congratulations! Your rank improved to #$rank!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error calculating user rank: $e');
    }
  }

  Future<void> _refreshLeaderboard() async {
    setState(() {
      _isRefreshing = true;
    });

    await _calculateCurrentUserRank();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Consistent app header
            AppHeader(
              title: 'Leaderboard',
              titleFontSize: 32,
              leadingIcon: Icons.emoji_events,
              actions: [
          // Toggle between everyone and friends only
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _selectedViewFilter == ViewFilter.friends
                  ? colorScheme.primaryContainer.withAlpha(50)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: _selectedViewFilter == ViewFilter.friends
                  ? Border.all(color: colorScheme.primary.withAlpha(100), width: 1)
                  : null,
            ),
            child: Tooltip(
              message: _selectedViewFilter == ViewFilter.everyone
                  ? 'Show friends only'
                  : 'Show everyone',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedViewFilter = _selectedViewFilter == ViewFilter.everyone
                          ? ViewFilter.friends
                          : ViewFilter.everyone;
                    });
                    _refreshLeaderboard();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedViewFilter == ViewFilter.everyone
                              ? Icons.people_outline
                              : Icons.people,
                          color: _selectedViewFilter == ViewFilter.friends
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        if (_selectedViewFilter == ViewFilter.friends) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Friends',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Refresh button
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _isRefreshing ? colorScheme.primaryContainer.withAlpha(50) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isRefreshing
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        key: const ValueKey('refresh'),
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
              tooltip: 'Refresh leaderboard',
              onPressed: _isRefreshing
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _refreshIndicatorKey.currentState?.show();
                  },
            ),
          ),
        ],
              ),

              // Tab bar below header
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(50), width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'All Time'),
                    Tab(text: 'Monthly'),
                    Tab(text: 'Weekly'),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  color: colorScheme.primary,
                  onRefresh: _refreshLeaderboard,
                  child: StreamBuilder<List<UserModel>>(
                    stream: _getFilteredUsersStream(),
                    builder: (context, snapshot) {
                      // Handle loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      // Handle error state
                      if (snapshot.hasError) {
                        final errorMessage = snapshot.error.toString();
                        final bool isIndexError = errorMessage.contains('index');

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isIndexError ? Icons.build : Icons.error_outline,
                                  size: 48,
                                  color: isIndexError ? Colors.orange : colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isIndexError ? 'Creating Leaderboard Index' : 'Error Loading Leaderboard',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isIndexError ? Colors.orange : colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isIndexError
                                      ? 'Firebase needs to create an index. This may take a few minutes. Please try again soon.'
                                      : 'Error: ${snapshot.error}',
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Get users data
                      final users = snapshot.data ?? [];

                      // Handle empty state
                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withAlpha(128),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // We have data, build the UI with a single column
                      return Column(
                        children: [
                          // Top 3 Winners Podium (only show for more than 3 users and only on all-time tab)
                          if (_tabController.index == 0 && users.length >= 3)
                            _buildTopThreePodium(users.take(3).toList()),

                          // Leaderboard list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 80),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final rank = index + 1;
                                final isCurrentUser = user.id == _auth.currentUser?.uid;

                                // Skip top 3 users as they're shown in the podium (only on all-time tab)
                                if (_tabController.index == 0 && rank <= 3 && users.length >= 3) {
                                  return const SizedBox.shrink();
                                }

                                return _buildLeaderboardItem(
                                  user: user,
                                  rank: rank,
                                  isCurrentUser: isCurrentUser,
                                  colorScheme: colorScheme,
                                ).animate(autoPlay: true).fadeIn(
                                  duration: const Duration(milliseconds: 300),
                                  delay: Duration(milliseconds: 50 * index),
                                );
                              },
                            ),
                          ),

                          // Current user's rank (if not in top list)
                          if (_currentUserRank != null && _currentUserRank! > _leaderboardLimit)
                            _buildCurrentUserRank(colorScheme),
                        ],
                      );
                    },
                  ),
                ),
            ),
          ],
        ),
      ),
      floatingActionButton: _auth.currentUser != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Scroll to current user's position if available
                _scrollToCurrentUser();
              },
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.primary,
              elevation: 2,
              icon: const Icon(Icons.person_search),
              label: const Text('Find Me'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
    );
  }

  void _scrollToCurrentUser() {
    // Implementation for scrolling to current user's position
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finding your position...'),
        duration: Duration(seconds: 2),
      ),
    );

    // Here you would implement actual scroll logic
    _refreshLeaderboard();
  }

  Stream<List<UserModel>> _getFilteredUsersStream() {
    if (_selectedViewFilter == ViewFilter.everyone) {
      debugPrint('Leaderboard: Getting everyone view');
      // Assuming this method doesn't actually take a timePeriod parameter
      return _userService.getTopUsersByAuraPoints(_leaderboardLimit);
    } else {
      debugPrint('Leaderboard: Getting friends view');
      // Assuming this method doesn't actually take a timePeriod parameter
      return _userService.getTopFriendsByAuraPoints(
        _auth.currentUser!.uid,
        _leaderboardLimit,
      );
    }
  }

  Widget _buildTopThreePodium(List<UserModel> topUsers) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Only build podium for all-time view
    if (_tabController.index != 0) {
      return const SizedBox.shrink();
    }

    // Arrange users in correct podium positions (2nd, 1st, 3rd)
    final podiumOrder = [
      topUsers.length > 1 ? topUsers[1] : null, // 2nd place
      topUsers[0],                               // 1st place
      topUsers.length > 2 ? topUsers[2] : null,  // 3rd place
    ];

    final heights = [160.0, 200.0, 130.0]; // Heights for each podium position
    final positions = [1, 0, 2]; // Positions on podium (2nd, 1st, 3rd)

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withAlpha(40),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Champions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (index) {
              if (podiumOrder[index] == null) {
                return const Spacer();
              }

              final user = podiumOrder[index]!;
              final rank = positions[index] + 1;
              final isCurrentUser = user.id == _auth.currentUser?.uid;

              // Get display name (use real name if available)
              final displayName = user.displayName ?? _truncateEmail(user.email);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          userId: user.id,
                          initialUserData: user,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      // User avatar with crown for 1st place
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Crown or medal for top positions
                          if (rank == 1)
                            Positioned(
                              top: -15,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.amber[700],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withAlpha(100),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),

                          // Avatar with glow effect for top positions
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (rank == 1)
                                  BoxShadow(
                                    color: Colors.amber.withAlpha(100),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                if (rank == 2)
                                  BoxShadow(
                                    color: Colors.blueGrey.withAlpha(80),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                if (rank == 3)
                                  BoxShadow(
                                    color: Colors.brown.withAlpha(80),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Hero(
                              tag: 'avatar-${user.id}',
                              child: CircleAvatar(
                                radius: rank == 1 ? 40 : (rank == 2 ? 32 : 28),
                                backgroundColor: Colors.white,
                                child: user.photoUrl != null && user.photoUrl!.isNotEmpty && user.photoUrl!.startsWith('http')
                                    ? CircleAvatar(
                                        radius: rank == 1 ? 38 : (rank == 2 ? 30 : 26),
                                        backgroundImage: NetworkImage(user.photoUrl!),
                                      )
                                    : CircleAvatar(
                                        radius: rank == 1 ? 38 : (rank == 2 ? 30 : 26),
                                        backgroundColor: _getAvatarColor(user.email),
                                        child: Text(
                                          displayName[0].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: rank == 1 ? 24 : (rank == 2 ? 20 : 18),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          // Current user indicator
                          if (isCurrentUser)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colorScheme.surface, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(40),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 12,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),

                          // Rank badge for 2nd and 3rd place
                          if (rank != 1)
                            Positioned(
                              top: -5,
                              right: -5,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: rank == 2 ? Colors.blueGrey[300] : Colors.brown[400],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(40),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '#$rank',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // User name with better styling
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: rank == 1 ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? colorScheme.primary : colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Points with improved styling
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user.auraPoints}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Podium with improved styling
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        height: heights[index],
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getPodiumColor(rank),
                              _getPodiumColor(rank).withAlpha(200),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                rank == 1 ? Icons.looks_one : (rank == 2 ? Icons.looks_two : Icons.looks_3),
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rank == 1 ? '1st' : (rank == 2 ? '2nd' : '3rd'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(autoPlay: true).fadeIn(
                duration: const Duration(milliseconds: 600),
                delay: Duration(milliseconds: 200 * index),
              ).moveY(
                begin: 20,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                delay: Duration(milliseconds: 200 * index),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getPodiumColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.blueGrey.shade300;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }

  String _truncateEmail(String email) {
    if (email.contains('@')) {
      return email.substring(0, email.indexOf('@'));
    }
    return email;
  }

  Widget _buildLeaderboardItem({
    required UserModel user,
    required int rank,
    required bool isCurrentUser,
    required ColorScheme colorScheme,
  }) {
    // Determine rank color and icon
    Color rankColor;
    IconData? rankIcon;

    switch (rank) {
      case 1:
        rankColor = Colors.amber.shade700; // Gold
        rankIcon = Icons.looks_one;
        break;
      case 2:
        rankColor = Colors.blueGrey.shade300; // Silver
        rankIcon = Icons.looks_two;
        break;
      case 3:
        rankColor = Colors.brown.shade400; // Bronze
        rankIcon = Icons.looks_3;
        break;
      default:
        rankColor = colorScheme.onSurfaceVariant;
        rankIcon = null;
    }

    // Check for achievements and badges
    final List<String> achievements = user.achievements ?? [];
    final bool hasAchievements = achievements.isNotEmpty;
    final bool isTopPerformer = rank <= 10;
    final bool hasCompletedTasks = user.completedTasks >= 10;
    final bool hasHighPoints = user.auraPoints >= 100;
    final bool hasStreak = user.streakCount >= 3;

    // Get display name (use real name if available)
    final displayName = user.displayName ?? _truncateEmail(user.email);

    // Card elevation and color based on rank and user status
    final double elevation = isCurrentUser ? 4 : (rank <= 10 ? 2 : 1);
    final Color cardColor = isCurrentUser
        ? colorScheme.primaryContainer.withAlpha(50)
        : (rank <= 10 ? colorScheme.surface : colorScheme.surfaceContainerLowest);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isCurrentUser ? 8 : 4,
      ),
      elevation: elevation,
      shadowColor: Colors.black.withAlpha(20),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentUser
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          // Navigate to user profile screen
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: user.id,
                initialUserData: user,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: colorScheme.primary.withAlpha(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Rank indicator with improved styling
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withAlpha(30),
                  shape: BoxShape.circle,
                  border: rank <= 3 ? Border.all(color: rankColor, width: 1.5) : null,
                  boxShadow: rank <= 3 ? [
                    BoxShadow(
                      color: rankColor.withAlpha(40),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ] : null,
                ),
                child: rankIcon != null
                    ? Icon(
                        rankIcon,
                        color: rankColor,
                        size: 24,
                      )
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // User info with improved layout
              Expanded(
                child: Row(
                  children: [
                    // User avatar with improved styling
                    Stack(
                      children: [
                        Hero(
                          tag: 'list-avatar-${user.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: UserAvatar(
                              imageUrl: user.photoUrl,
                              displayName: user.displayName,
                              email: user.email,
                              radius: 20,
                            ),
                          ),
                        ),
                        // Top performer badge
                        if (isTopPerformer)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.amber[700]!, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.star,
                                size: 10,
                                color: Colors.amber[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // User name and badges with improved layout
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User name with real name support
                          Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: isCurrentUser || rank <= 3 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 15,
                              color: isCurrentUser ? colorScheme.primary : colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Task completion info with badges
                          Row(
                            children: [
                              // Badges row with improved styling
                              if (hasHighPoints)
                                _buildBadgeIcon(Icons.workspace_premium, Colors.amber[700]!),
                              if (hasCompletedTasks)
                                _buildBadgeIcon(Icons.task_alt, Colors.green[600]!),
                              if (hasStreak)
                                _buildBadgeIcon(Icons.local_fire_department, Colors.deepOrange[400]!),

                              // Task count
                              if (user.completedTasks > 0)
                                Expanded(
                                  child: Text(
                                    '${user.completedTasks} tasks',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              // Achievement count badge
                              if (hasAchievements)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${achievements.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right side with points and actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Points display with improved styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.auraPoints}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Challenge button (only for non-current users)
                  if (!isCurrentUser && _auth.currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showChallengeDialog(user);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Challenge',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Current user indicator
                  if (isCurrentUser)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'YOU',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build badge icons
  Widget _buildBadgeIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }





  // Build the current user's rank widget at the bottom of the screen
  Widget _buildCurrentUserRank(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '#$_currentUserRank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      ' out of $_totalUsers users',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _scrollToCurrentUser,
            icon: const Icon(Icons.visibility),
            label: const Text('Find Me'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    ).animate(autoPlay: true).slide(
      duration: const Duration(milliseconds: 400),
      delay: const Duration(milliseconds: 300),
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    );
  }

  // Generate a consistent color based on the email
  Color _getAvatarColor(String email) {
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

  void _showChallengeDialog(UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user.displayName ?? _truncateEmail(user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber[700],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('Challenge $displayName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: UserAvatar(
                    imageUrl: user.photoUrl,
                    displayName: user.displayName,
                    email: user.email,
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.auraPoints} points',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Challenge description
            Text(
              'Create a challenge task that both of you will compete to complete. You\'ll both earn aura points when completed!',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            // Challenge types
            const SizedBox(height: 16),
            Text(
              'Choose a challenge type:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildChallengeTypeOption(
              icon: Icons.timer,
              title: 'Time Challenge',
              description: 'Who can complete the task faster',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _buildChallengeTypeOption(
              icon: Icons.fitness_center,
              title: 'Endurance Challenge',
              description: 'Who can maintain a streak longer',
              colorScheme: colorScheme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show a snackbar for now (this would be replaced with actual challenge creation)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Challenge sent to $displayName!'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      // This would navigate to the challenges screen in the future
                    },
                  ),
                ),
              );

              // Visual feedback
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Send Challenge'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeTypeOption({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Radio(
            value: title,
            groupValue: 'Time Challenge', // Default selected
            onChanged: (value) {
              // This would update the selected challenge type
            },
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }


}