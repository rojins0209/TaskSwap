import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/auth_service.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/screens/profile/edit_profile_screen.dart';
import 'package:taskswap/screens/settings/theme_settings_screen.dart';
import 'package:taskswap/screens/settings/privacy_settings_screen.dart';
import 'package:taskswap/screens/settings/help_support_screen.dart';
import 'package:taskswap/screens/settings/notification_settings_screen.dart';
import 'package:taskswap/screens/profile/aura_share_screen.dart';
import 'package:taskswap/widgets/user_avatar.dart';

class MinimalistProfileScreen extends StatefulWidget {
  const MinimalistProfileScreen({super.key});

  @override
  State<MinimalistProfileScreen> createState() => _MinimalistProfileScreenState();
}

class _MinimalistProfileScreenState extends State<MinimalistProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // Navigation will be handled by the auth state listener in main.dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  Future<void> _navigateToEditProfile(String userId) async {
    final userProfile = await _userService.getUserById(userId);
    if (userProfile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(userProfile: userProfile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.onSurface),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not signed in'))
          : StreamBuilder<UserModel?>(
              stream: _userService.getUserStream(user.uid),
              builder: (context, snapshot) {
                bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                UserModel? userProfile = snapshot.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      _buildProfileHeader(userProfile, user),
                      
                      const SizedBox(height: 32),
                      
                      // Stats section
                      _buildStatsSection(isLoading, userProfile),
                      
                      const SizedBox(height: 32),
                      
                      // Level progress
                      if (userProfile != null)
                        _buildLevelProgress(userProfile.auraPoints),
                      
                      const SizedBox(height: 32),
                      
                      // Settings section
                      _buildSettingsSection(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(UserModel? userProfile, User? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            if (user != null) {
              _navigateToEditProfile(user.uid);
            }
          },
          child: UserAvatar(
            imageUrl: userProfile?.photoUrl,
            displayName: userProfile?.displayName,
            email: userProfile?.email ?? user?.email,
            radius: 40,
            showBorder: true,
            borderColor: colorScheme.primary.withAlpha(50),
            borderWidth: 2,
          ),
        ),
        const SizedBox(width: 16),
        
        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userProfile?.displayName ?? user?.email?.split('@')[0] ?? 'Unknown User',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Unknown Email',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Joined ${user?.metadata.creationTime?.toString().split(' ')[0] ?? 'Unknown'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildStatsSection(bool isLoading, UserModel? userProfile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stats',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.auto_awesome,
              title: 'Aura',
              value: isLoading ? '...' : '${userProfile?.auraPoints ?? 0}',
              color: colorScheme.primary,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.local_fire_department,
              title: 'Streak',
              value: isLoading ? '...' : '${userProfile?.streakCount ?? 0} days',
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              icon: Icons.check_circle_outline,
              title: 'Tasks',
              value: isLoading ? '...' : '${userProfile?.completedTasks ?? 0}',
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelProgress(int auraPoints) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate level based on aura points
    // This is a simple formula, you might want to adjust it
    final level = (auraPoints / 100).floor() + 1;
    final pointsForNextLevel = level * 100;
    final progress = (auraPoints % 100) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level Progress',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $level',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$auraPoints / $pointsForNextLevel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.primary.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Keep completing tasks to level up!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.color_lens_outlined,
                title: 'Theme Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSettingsScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.lock_outline,
                title: 'Privacy & Security',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacySettingsScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildSettingsItem(
                icon: Icons.share_outlined,
                title: 'Share Aura Card',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuraShareScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 0,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
