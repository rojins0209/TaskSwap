import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:taskswap/models/friend_request_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/screens/profile/user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final UserService _userService = UserService();
  final ChallengeService _challengeService = ChallengeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Current user's rank (will be calculated)
  int? _currentUserRank;

  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  // Create broadcast streams to avoid "Stream has already been listened to" errors
  late Stream<List<UserModel>> _friendsStream;
  late Stream<List<FriendRequest>> _requestsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRank();

    // Initialize broadcast streams
    _friendsStream = _friendService.getFriends().asBroadcastStream();
    _requestsStream = _friendService.getPendingFriendRequests().asBroadcastStream();
  }

  Future<void> _loadUserRank() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final rank = await _userService.getUserRank(currentUser.uid);

      if (mounted) {
        setState(() {
          _currentUserRank = rank;
        });
      }
    } catch (e) {
      debugPrint('Error loading user rank: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _friendService.searchUsersByEmail(_searchController.text);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      await _friendService.sendFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  Future<void> _acceptFriendRequest(String userId) async {
    try {
      await _friendService.acceptFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  Future<void> _rejectFriendRequest(String userId) async {
    try {
      await _friendService.rejectFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request rejected'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  Future<void> _removeFriend(String userId) async {
    try {
      await _friendService.removeFriend(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend removed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Modern social header with stats
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Top section with title and actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.people_alt_rounded,
                                size: 24,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Friends',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ).animate()
                          .fade(duration: const Duration(milliseconds: 400))
                          .slideX(begin: -0.1, end: 0, duration: const Duration(milliseconds: 400)),

                        // Action buttons
                        Row(
                          children: [
                            // Notifications button
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Friend notifications coming soon!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'Notifications',
                            ),

                            // Add friend button
                            IconButton(
                              onPressed: () {
                                // Focus the search field
                                HapticFeedback.mediumImpact();
                                FocusScope.of(context).requestFocus(FocusNode());
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                                // Scroll to search field
                                // Create a focus node that we can use later
                                final focusNode = FocusNode();
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (mounted) {
                                    _searchController.text = '';
                                    focusNode.requestFocus();
                                  }
                                  // Dispose the focus node to avoid memory leaks
                                  focusNode.dispose();
                                });
                              },
                              icon: Icon(
                                Icons.person_add_alt_rounded,
                                color: colorScheme.primary,
                              ),
                              tooltip: 'Add new friend',
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.primaryContainer,
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ).animate()
                          .fade(duration: const Duration(milliseconds: 400))
                          .slideX(begin: 0.1, end: 0, duration: const Duration(milliseconds: 400)),
                      ],
                    ),
                  ),

                  // Stats cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: StreamBuilder<List<UserModel>>(
                      stream: _friendsStream,
                      builder: (context, snapshot) {
                        final friendCount = snapshot.data?.length ?? 0;

                        return Row(
                          children: [
                            // Friends count card
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.people_alt_rounded,
                                iconColor: Colors.blue,
                                title: '$friendCount',
                                subtitle: 'Friends',
                                delay: 100,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Rank card
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.emoji_events_rounded,
                                iconColor: Colors.amber.shade700,
                                title: _currentUserRank != null ? '#$_currentUserRank' : '-',
                                subtitle: 'Your Rank',
                                delay: 200,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Tasks count card (placeholder)
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.task_alt_rounded,
                                iconColor: Colors.teal,
                                title: '0',
                                subtitle: 'Tasks',
                                delay: 300,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task stats coming soon!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Elevated tab bar with animation
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                dividerColor: Colors.transparent,
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall,
                padding: const EdgeInsets.all(4),
                onTap: (index) {
                  HapticFeedback.selectionClick();
                },
                tabs: [
                  Tab(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.people_rounded, size: 20),
                        StreamBuilder<List<UserModel>>(
                          stream: _friendsStream,
                          builder: (context, snapshot) {
                            final friendCount = snapshot.data?.length ?? 0;
                            if (friendCount == 0) return const SizedBox.shrink();

                            return Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _tabController.index == 0
                                    ? colorScheme.onPrimary
                                    : colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$friendCount',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: _tabController.index == 0
                                      ? colorScheme.primary
                                      : colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Show friend request indicator if there are any
                        StreamBuilder<List<FriendRequest>>(
                          stream: _requestsStream,
                          builder: (context, snapshot) {
                            final requestCount = snapshot.data?.length ?? 0;
                            if (requestCount == 0) return const SizedBox.shrink();

                            return Positioned(
                              top: -4,
                              left: -8,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _tabController.index == 0
                                      ? colorScheme.primary
                                      : colorScheme.surfaceContainerLow,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    text: 'Friends',
                  ),
                  const Tab(
                    icon: Icon(Icons.leaderboard_rounded, size: 20),
                    text: 'Ranking',
                  ),
                ],
              ),
            ).animate()
              .fade(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200))
              .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400)),

            // Main content
            Expanded(
              child: Column(
                children: [
                  // Modern floating search bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Find friends by name or email',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: _searchController.text.isNotEmpty
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: colorScheme.onSurfaceVariant,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults = [];
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerLow,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value.isEmpty) {
                                    _searchResults = [];
                                  }
                                });
                              },
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  HapticFeedback.mediumImpact();
                                  _searchUsers();
                                }
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  _searchUsers();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search, size: 16),
                                    const SizedBox(width: 4),
                                    const Text('Search'),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fade(duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 300))
                    .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400)),

                  // Search results or tab content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _searchResults.isNotEmpty
                          ? Container(
                              key: const ValueKey('search_results'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Search results header
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Search Results',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${_searchResults.length}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            _searchController.clear();
                                            setState(() {
                                              _searchResults = [];
                                            });
                                          },
                                          icon: const Icon(Icons.close, size: 16),
                                          label: const Text('Clear'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: colorScheme.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Results list
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final user = _searchResults[index];
                                        return _buildUserListItem(user);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _isSearching
                              ? const Center(
                                  key: ValueKey('searching'),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Searching for users...'),
                                    ],
                                  ),
                                )
                              : TabBarView(
                                  key: const ValueKey('tab_content'),
                                  controller: _tabController,
                                  children: [
                                    // My Friends tab (now includes requests)
                                    _buildFriendsTab(),

                                    // Leaderboard tab
                                    _buildLeaderboardTab(),
                                  ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _requestsStream,
      builder: (context, requestsSnapshot) {
        final requests = requestsSnapshot.data ?? [];

        return StreamBuilder<List<UserModel>>(
          stream: _friendsStream,
          builder: (context, friendsSnapshot) {
            if (friendsSnapshot.connectionState == ConnectionState.waiting &&
                requestsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (friendsSnapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading friends: ${friendsSnapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final friends = friendsSnapshot.data ?? [];
            final hasContent = friends.isNotEmpty || requests.isNotEmpty;

            if (!hasContent) {
              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 60,
                        color: colorScheme.primary.withAlpha(180),
                      ),
                    ).animate()
                      .fade(duration: const Duration(milliseconds: 600))
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 500)),
                    const SizedBox(height: 24),
                    Text(
                      'Connect with Friends',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ).animate()
                      .fade(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200))
                      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Add friends to challenge each other and stay motivated together!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate()
                      .fade(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 300))
                      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Focus the search field
                        FocusScope.of(context).requestFocus(FocusNode());
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                        // Create a focus node that we can use later
                        final focusNode = FocusNode();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _searchController.text = '';
                            focusNode.requestFocus();
                          }
                          // Dispose the focus node to avoid memory leaks
                          focusNode.dispose();
                        });
                      },
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Find Friends'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ).animate()
                      .fade(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 400))
                      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
                  ],
                ),
              );
            }

            // Build a combined list of requests and friends
            return CustomScrollView(
              slivers: [
                // Friend Requests Section
                if (requests.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Friend Requests',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${requests.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Friend request items
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final request = requests[index];
                        // Pre-fetch user data to avoid FutureBuilder inside SliverList
                        return FutureBuilder<UserModel?>(
                          future: _userService.getUserById(request.fromUserId),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return SizedBox(
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            if (!userSnapshot.hasData || userSnapshot.data == null) {
                              return SizedBox(
                                height: 80,
                                child: Center(
                                  child: Text('User data not available'),
                                ),
                              );
                            }

                            final user = userSnapshot.data!;
                            return _buildFriendRequestItem(user);
                          },
                        );
                      },
                      childCount: requests.length,
                    ),
                  ),

                  // Divider between requests and friends
                  if (friends.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Divider(
                          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(80),
                        ),
                      ),
                    ),
                ],

                // Friends Section
                if (friends.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.people_alt_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'My Friends',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${friends.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Friend items
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final friend = friends[index];
                        return _buildFriendListItem(friend);
                      },
                      childCount: friends.length,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }



  Widget _buildUserListItem(UserModel user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _getAvatarColor(user.email),
          child: Text(
            user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.displayName ?? user.email,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.auto_awesome, size: 14, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(
              '${user.auraPoints} aura points',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _sendFriendRequest(user.id),
        ),
      ),
    );
  }

  Widget _buildFriendListItem(UserModel friend) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Simulate online status (in a real app, this would come from a backend)
    final bool isOnline = friend.id.hashCode % 3 == 0;

    // Determine last active time (simulated)
    final lastActive = friend.id.hashCode % 5 == 0
        ? 'Active now'
        : friend.id.hashCode % 4 == 0
            ? 'Active today'
            : friend.id.hashCode % 3 == 0
                ? 'Active yesterday'
                : 'Active 3 days ago';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isOnline
              ? Colors.green.withAlpha(50)
              : colorScheme.outlineVariant.withAlpha(40),
          width: isOnline ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Navigate to friend profile
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: friend.id,
                initialUserData: friend,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top row with avatar and main info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with online indicator
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withAlpha(20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: _getAvatarColor(friend.email),
                          child: Text(
                            friend.email.isNotEmpty ? friend.email[0].toUpperCase() : '?',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayName ?? friend.email,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isOnline ? Icons.circle : Icons.access_time,
                              size: 12,
                              color: isOnline ? Colors.green : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lastActive,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOnline ? Colors.green : colorScheme.onSurfaceVariant,
                                fontWeight: isOnline ? FontWeight.w500 : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Stats row
                        Row(
                          children: [
                            _buildStatBadge(
                              icon: Icons.auto_awesome,
                              iconColor: Colors.amber.shade700,
                              label: '${friend.auraPoints} aura',
                            ),
                            if (friend.streakCount > 0) ...[
                              const SizedBox(width: 8),
                              _buildStatBadge(
                                icon: Icons.local_fire_department,
                                iconColor: Colors.deepOrange.shade400,
                                label: '${friend.streakCount} day streak',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons row - simplified
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Challenge button
                  _buildActionButton(
                    icon: Icons.emoji_events_outlined,
                    label: 'Challenge',
                    onPressed: () {
                      _showChallengeDialog(friend);
                    },
                  ),

                  const SizedBox(width: 32),

                  // More options button
                  _buildActionButton(
                    icon: Icons.more_horiz,
                    label: 'Options',
                    onPressed: () {
                      _showFriendOptionsBottomSheet(friend);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fade(duration: const Duration(milliseconds: 400))
      .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 400));
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendOptionsBottomSheet(UserModel friend) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getAvatarColor(friend.email),
                    child: Text(
                      friend.email.isNotEmpty ? friend.email[0].toUpperCase() : '?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    friend.displayName ?? friend.email,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Options - simplified
              _buildOptionItem(
                icon: Icons.person,
                iconColor: colorScheme.primary,
                label: 'View Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: friend.id,
                        initialUserData: friend,
                      ),
                    ),
                  );
                },
              ),
              _buildOptionItem(
                icon: Icons.emoji_events_outlined,
                iconColor: colorScheme.primary,
                label: 'Challenge to Task',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Challenge ${friend.displayName ?? "friend"} feature coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildOptionItem(
                icon: Icons.person_remove,
                iconColor: colorScheme.error,
                label: 'Remove Friend',
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveFriendDialog(friend);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }

  // Show challenge dialog
  void _showChallengeDialog(UserModel friend) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Controllers for the form fields
    final taskController = TextEditingController();
    final pointsController = TextEditingController(text: '20');
    bool isLoading = false;
    bool bothUsersComplete = false;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Challenge ${friend.displayName ?? 'Friend'}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task description field
                TextField(
                  controller: taskController,
                  decoration: InputDecoration(
                    labelText: 'Task Description',
                    hintText: 'What do you want to challenge them to do?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.task_alt_rounded),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),

                const SizedBox(height: 16),

                // Points field
                TextField(
                  controller: pointsController,
                  decoration: InputDecoration(
                    labelText: 'Points',
                    hintText: 'How many points is this challenge worth?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.auto_awesome),
                  ),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // Both users complete checkbox
                Row(
                  children: [
                    Checkbox(
                      value: bothUsersComplete,
                      onChanged: (value) {
                        setState(() {
                          bothUsersComplete = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Both of us need to complete this task',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Due date picker
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );

                        if (selectedDate != null) {
                          setState(() {
                            dueDate = selectedDate;
                          });
                        }
                      },
                      child: Text(
                        dueDate != null
                            ? 'Due: ${DateFormat('MMM d, yyyy').format(dueDate!)}'
                            : 'Set Due Date (Optional)',
                      ),
                    ),
                    if (dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            dueDate = null;
                          });
                        },
                        iconSize: 16,
                      ),
                  ],
                ),
              ],
            ),
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
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate inputs
                      if (taskController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a task description'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final points = int.tryParse(pointsController.text) ?? 20;
                      if (points <= 0 || points > 100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Points must be between 1 and 100'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      // Show loading state
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // Send the challenge
                        await _challengeService.sendChallenge(
                          friend.id,
                          taskController.text,
                          points: points,
                          bothUsersComplete: bothUsersComplete,
                          dueDate: dueDate,
                        );

                        // Store context before async gap
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final dialogContext = context;

                        if (mounted) {
                          // Close the dialog
                          Navigator.pop(dialogContext);

                          // Show success message
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Challenge sent to ${friend.displayName ?? 'friend'}!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        // Store context before async gap
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });

                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.primary.withAlpha(128),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Challenge'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestItem(UserModel user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withAlpha(50),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with avatar and info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with notification badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withAlpha(20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: _getAvatarColor(user.email),
                        child: Text(
                          user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withAlpha(30),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_add,
                            size: 10,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? user.email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Friend Request',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stats row
                      Row(
                        children: [
                          _buildStatBadge(
                            icon: Icons.auto_awesome,
                            iconColor: Colors.amber.shade700,
                            label: '${user.auraPoints} aura',
                          ),
                          if (user.streakCount > 0) ...[
                            const SizedBox(width: 8),
                            _buildStatBadge(
                              icon: Icons.local_fire_department,
                              iconColor: Colors.deepOrange.shade400,
                              label: '${user.streakCount} day streak',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withAlpha(40),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Message',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'I\'d like to connect with you on TaskSwap! Let\'s motivate each other to complete tasks and build productive habits.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _acceptFriendRequest(user.id);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _rejectFriendRequest(user.id);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // View profile link
            TextButton.icon(
              onPressed: () {
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
              icon: Icon(
                Icons.person_outline,
                size: 16,
                color: colorScheme.primary,
              ),
              label: Text(
                'View Profile',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fade(duration: const Duration(milliseconds: 400))
      .slideY(begin: 0.1, end: 0, duration: const Duration(milliseconds: 400));
  }

  void _showRemoveFriendDialog(UserModel friend) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Remove Friend', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to remove ${friend.email} from your friends?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friend.id);
            },
            child: Text(
              'Remove',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    int delay = 0,
    bool showBadge = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(40),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon with optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fade(duration: const Duration(milliseconds: 600), delay: Duration(milliseconds: delay))
      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500), delay: Duration(milliseconds: delay));
  }

  Widget _buildLeaderboardTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getTopFriendsByAuraPoints(_auth.currentUser!.uid, 50),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
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
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading leaderboard',
                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.error),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 60,
                    color: Colors.amber.shade700,
                  ),
                ).animate()
                  .fade(duration: const Duration(milliseconds: 600))
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: const Duration(milliseconds: 500)),
                const SizedBox(height: 24),
                Text(
                  'Friend Ranking',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ).animate()
                  .fade(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200))
                  .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Connect with friends to see how you rank against each other based on aura points',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate()
                  .fade(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 300))
                  .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Focus the search field
                    HapticFeedback.mediumImpact();
                    FocusScope.of(context).requestFocus(FocusNode());
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                    // Scroll to search field and switch to friends tab
                    // Create a focus node that we can use later
                    final focusNode = FocusNode();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _searchController.text = '';
                        focusNode.requestFocus();
                        _tabController.animateTo(0); // Switch to friends tab
                      }
                      // Dispose the focus node to avoid memory leaks
                      focusNode.dispose();
                    });
                  },
                  icon: const Icon(Icons.people_alt_rounded),
                  label: const Text('Add Friends'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ).animate()
                  .fade(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 400))
                  .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadUserRank();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final rank = index + 1;
              final isCurrentUser = user.id == _auth.currentUser?.uid;

              return _buildLeaderboardItem(
                user: user,
                rank: rank,
                isCurrentUser: isCurrentUser,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardItem({
    required UserModel user,
    required int rank,
    required bool isCurrentUser,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    // Get display name (use real name if available)
    final displayName = user.displayName ?? user.email;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Rank
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: rankIcon != null
                    ? Icon(rankIcon, color: rankColor, size: 20)
                    : Text(
                        '$rank',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(user.email),
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.auraPoints} aura points',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (user.streakCount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.deepOrange[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.streakCount} day streak',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Badge for top performers
              if (rank <= 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rankColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: rankColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rank == 1
                            ? 'Champion'
                            : rank == 2
                                ? 'Silver'
                                : 'Bronze',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
