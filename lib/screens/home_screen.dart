import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/screens/tasks/enhanced_add_task_screen.dart';
import 'package:taskswap/screens/tasks/tasks_screen.dart';
import 'package:taskswap/screens/profile/profile_screen.dart';
import 'package:taskswap/screens/friends/friends_screen.dart';
import 'package:taskswap/widgets/pill_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // No need for these fields as we're using StreamBuilder
  // UserModel? _userProfile;
  // bool _isLoadingProfile = true;

  // No need for tab titles as each screen has its own AppBar

  // Temporarily disabled for testing
  // final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Save FCM token for push notifications - temporarily disabled for testing
    // _notificationService.saveFCMToken();
  }

  // We're using StreamBuilder instead of this method
  // Future<void> _loadUserProfile() async {
  //   final userId = _authService.currentUser?.uid;
  //   if (userId != null) {
  //     setState(() {
  //       _isLoadingProfile = true;
  //     });
  //
  //     try {
  //       final userProfile = await _userService.getUserById(userId);
  //       setState(() {
  //         _userProfile = userProfile;
  //         _isLoadingProfile = false;
  //       });
  //     } catch (e) {
  //       debugPrint('Error loading user profile: $e');
  //       setState(() {
  //         _isLoadingProfile = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _buildBody(),
      // We'll use a Stack to position the FAB in the body instead
      bottomNavigationBar: PillNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          // Add haptic feedback for better user experience
          HapticFeedback.selectionClick();
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        pillColor: colorScheme.primary.withAlpha(38),
        height: 64,
        iconSize: 24,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 30,
        elevation: 4,
        items: const [
          PillNavBarItem(
            icon: Icons.check_circle_outline,
            activeIcon: Icons.check_circle,
            label: 'Tasks',
          ),
          PillNavBarItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Friends',
          ),
          PillNavBarItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildTasksTab();
      case 1:
        return const FriendsScreen();
      case 2:
        return _buildProfileTab();
      default:
        return _buildTasksTab();
    }
  }

  Widget _buildTasksTab() {
    return Stack(
      fit: StackFit.expand, // Make the stack fill the available space
      children: [
        const TasksScreen(),
        // Position the FAB just above the nav bar
        Positioned(
          bottom: 16, // Position just above the nav bar
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              // Add haptic feedback for better user experience
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EnhancedAddTaskScreen()),
              ).then((value) {
                if (value == true) {
                  // Refresh tasks if a new task was added
                  setState(() {});
                }
              });
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  // Removed _buildExploreTab and _buildFloatingActionButton as they're no longer used

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }
}