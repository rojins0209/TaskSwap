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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/widgets/app_header.dart';
import 'package:taskswap/widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Consistent app header
            AppHeader(
              title: 'Profile',
              titleFontSize: 32,
              leadingIcon: Icons.person,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Profile',
                  onPressed: () {
                    _navigateToEditProfile(user!.uid);
                  },
                ),
              ],
            ),

            // Main content
            Expanded(
              child: StreamBuilder<UserModel?>(
                stream: user != null ? _userService.getUserStream(user.uid) : null,
                builder: (context, snapshot) {
                  bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                  UserModel? userProfile = snapshot.data;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Profile Avatar
                        _buildProfileAvatar(userProfile, user),
                        const SizedBox(height: 16),

                        // User Name and Email
                        Text(
                          userProfile?.displayName ?? user?.email?.split('@')[0] ?? 'Unknown User',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'Unknown Email',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Member since ${user?.metadata.creationTime?.toString().split(' ')[0] ?? 'Unknown'}',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),

                        const SizedBox(height: 32),

                        // Stats Cards
                        _buildStatsSection(isLoading, userProfile),

                        const SizedBox(height: 32),

                        // Streak Card
                        if (userProfile != null)
                          _buildStreakCard(userProfile),

                        const SizedBox(height: 32),

                        // Level Progress
                        if (userProfile != null)
                          _buildLevelProgress(userProfile.auraPoints),

                        const SizedBox(height: 32),

                        // Share Aura Button
                        if (userProfile != null)
                          _buildShareAuraButton(),

                        const SizedBox(height: 32),

                        // Achievements Section
                        if (userProfile != null && (userProfile.achievements?.isNotEmpty ?? false))
                          _buildAchievementsSection(userProfile),

                        const SizedBox(height: 32),

                        // Settings Options
                        _buildSettingsSection(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel? userProfile, User? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Avatar
        UserAvatar(
          imageUrl: userProfile?.photoUrl,
          displayName: userProfile?.displayName,
          email: user?.email,
          radius: 60,
        ),

        // Aura Points Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(40),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: colorScheme.onPrimary,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                userProfile != null ? '${userProfile.auraPoints}' : '...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn(
              'Tasks',
              isLoading ? '...' : '${userProfile?.totalTasks ?? 0}'
            ),
            _buildStatColumn(
              'Completed',
              isLoading ? '...' : '${userProfile?.completedTasks ?? 0}'
            ),
            _buildStatColumn(
              'Aura',
              isLoading ? '...' : '${userProfile?.auraPoints ?? 0}',
              iconData: Icons.auto_awesome,
              iconColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(UserModel userProfile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final streakCount = userProfile.streakCount;
    final hasStreak = streakCount > 0;
    final streakColor = hasStreak ? Colors.orange : colorScheme.onSurfaceVariant;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: streakColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Streak',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$streakCount',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: streakColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'days',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: streakColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasStreak
                  ? 'Keep going! Complete a task today to maintain your streak.'
                  : 'Complete a task today to start your streak!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
    int level = (auraPoints / 100).floor() + 1;
    int pointsForCurrentLevel = (level - 1) * 100;
    int pointsForNextLevel = level * 100;
    double progress = (auraPoints - pointsForCurrentLevel) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              '$auraPoints / $pointsForNextLevel',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: colorScheme.primary.withAlpha(50),
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(UserModel userProfile) {
    final theme = Theme.of(context);
    final achievements = userProfile.achievements ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements.map((achievement) => _buildAchievementChip(achievement)).toList(),
        ),
      ],
    );
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

  Widget _buildShareAuraButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AuraShareScreen(),
            ),
          );
        },
        icon: const Icon(Icons.share),
        label: const Text('Share My Aura'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 300))
      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Widget _buildAchievementChip(String achievement) {
    final theme = Theme.of(context);
    IconData iconData;
    Color color;

    // Determine icon and color based on achievement type
    switch (achievement) {
      case 'Streak Master':
        iconData = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case 'Challenge Champion':
        iconData = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 'Early Bird':
        iconData = Icons.wb_sunny;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.star;
        color = Colors.purple;
    }

    return Chip(
      avatar: Icon(
        iconData,
        color: color,
        size: 18,
      ),
      label: Text(achievement, style: theme.textTheme.bodyMedium),
      backgroundColor: color.withAlpha(25),
      side: BorderSide(color: color.withAlpha(75)),
    );
  }

  Widget _buildSettingsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use the correct dark mode colors from the app theme
    final backgroundColor = theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest // Dark mode container - using the same color as cards
        : colorScheme.surfaceContainerLowest; // Light mode container

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.brightness == Brightness.dark
            ? colorScheme.outline // Use outline instead of outlineVariant for better contrast
            : colorScheme.outlineVariant.withAlpha(51)),
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
        _buildSettingsItem(
          icon: Icons.healing,
          title: 'Data Recovery',
          onTap: () {
            Navigator.pushNamed(context, '/data_recovery');
          },
        ),
        _buildSettingsItem(
          icon: Icons.logout,
          title: 'Sign Out',
          onTap: () async {
            await _authService.signOut();
          },
          textColor: colorScheme.error,
        ),
      ],
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, {IconData? iconData, Color? iconColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null) ...[
              Icon(iconData, size: 16, color: iconColor ?? colorScheme.primary),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Ensure text color respects theme
    final effectiveTextColor = textColor ?? colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: effectiveTextColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: effectiveTextColor),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      onTap: onTap,
      tileColor: Colors.transparent, // Ensure transparent background
    );
  }
}
