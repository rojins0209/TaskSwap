import 'package:flutter/material.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/follower_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/screens/profile/user_profile_screen.dart';

enum FollowerTab { followers, following }

class FollowersScreen extends StatefulWidget {
  final String userId;
  final FollowerTab initialTab;
  final String? userName;

  const FollowersScreen({
    super.key,
    required this.userId,
    this.initialTab = FollowerTab.followers,
    this.userName,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> with SingleTickerProviderStateMixin {
  final FollowerService _followerService = FollowerService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == FollowerTab.followers ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.userName ?? 'User';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '$userName\'s Connections',
          style: theme.textTheme.headlineSmall,
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Followers tab
          _buildFollowersTab(),

          // Following tab
          _buildFollowingTab(),
        ],
      ),
    );
  }

  Widget _buildFollowersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _followerService.getUserFollowers(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading followers: ${snapshot.error}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
          );
        }

        final followers = snapshot.data ?? [];

        if (followers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: AppTheme.accentColor.withAlpha(128),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Followers Yet',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'When people follow this user, they\'ll appear here',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: followers.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final follower = followers[index];
            return _buildUserListItem(follower);
          },
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _followerService.getUserFollowing(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading following: ${snapshot.error}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
          );
        }

        final following = snapshot.data ?? [];

        if (following.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_disabled,
                  size: 80,
                  color: AppTheme.accentColor.withAlpha(128),
                ),
                const SizedBox(height: 24),
                Text(
                  'Not Following Anyone',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'When this user follows people, they\'ll appear here',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: following.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final followedUser = following[index];
            return _buildUserListItem(followedUser);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
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
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentColor.withAlpha(51),
          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty && user.photoUrl!.startsWith('http') ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null || user.photoUrl!.isEmpty || !user.photoUrl!.startsWith('http')
              ? Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName![0].toUpperCase()
                      : user.email[0].toUpperCase(),
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.displayName ?? 'User',
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${user.auraPoints} points',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.local_fire_department,
              size: 14,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              '${user.streakCount} day streak',
              style: AppTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
