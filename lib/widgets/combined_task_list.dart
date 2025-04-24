import 'package:flutter/material.dart';
import 'package:taskswap/models/challenge_model.dart';
import 'package:taskswap/models/task_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/services/task_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/modern_task_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';

class CombinedTaskList extends StatefulWidget {
  const CombinedTaskList({super.key});

  @override
  State<CombinedTaskList> createState() => _CombinedTaskListState();
}

class _CombinedTaskListState extends State<CombinedTaskList> with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final ChallengeService _challengeService = ChallengeService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Helper method to show loading overlay
  OverlayEntry _showLoadingOverlay(String message) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withAlpha(128), // opacity 0.5
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withAlpha(26), // opacity 0.1
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    return overlayEntry;
  }

  // Helper method to show success animation
  void _showSuccessAnimation({
    required IconData icon,
    required String message,
    required String description,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    icon,
                    size: 80,
                    color: effectiveIconColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show completion confirmation dialog
  Future<bool> _showCompletionConfirmationDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Text('Complete Challenge?', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to mark this challenge as completed? This will earn you aura points!',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed
  }

  // Enhanced celebration animation with detailed reward information
  void _showEnhancedCelebrationAnimation({
    required int pointsEarned,
    required int bonusPoints,
    required String challengerName,
    required String challengeDescription,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: colorScheme.surface,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  // Trophy icon with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: const Icon(
                          Icons.emoji_events,
                          size: 80,
                          color: Colors.amber,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Challenge completed heading
                  Text(
                    'Challenge Completed!',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Challenge description
                  Text(
                    '"$challengeDescription"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Points earned container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Base points
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Base Points:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '+${pointsEarned - bonusPoints}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (bonusPoints > 0) ...[
                          const SizedBox(height: 8),
                          // Bonus points for quick completion
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Speed Bonus:',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                '+$bonusPoints',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                        Divider(height: 16, color: colorScheme.outline),
                        // Total points
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Earned:',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '+$pointsEarned',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Friend also earned points message
                  Text(
                    '$challengerName also earned ${pointsEarned ~/ 2} points!',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      // View Leaderboard button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to leaderboard tab
                            Navigator.of(context).pushNamed('/leaderboard');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('View Leaderboard'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Continue button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Confetti animation
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.1,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.amber,
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Start confetti animation
    _confettiController.play();
  }

  Future<void> _acceptChallenge(String challengeId) async {
    // Show loading indicator
    final loadingOverlay = _showLoadingOverlay('Accepting challenge...');

    try {
      await _challengeService.acceptChallenge(challengeId);

      // Remove loading indicator
      loadingOverlay.remove();

      if (mounted) {
        // Show success animation and message
        _showSuccessAnimation(
          icon: Icons.check_circle_outline,
          message: 'Challenge accepted!',
          description: 'The challenge has been added to your active challenges.',
        );
      }
    } catch (e) {
      // Remove loading indicator
      loadingOverlay.remove();

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

  Future<void> _rejectChallenge(String challengeId) async {
    // Show loading indicator
    final loadingOverlay = _showLoadingOverlay('Rejecting challenge...');

    try {
      await _challengeService.rejectChallenge(challengeId);

      // Remove loading indicator
      loadingOverlay.remove();

      if (mounted) {
        // Show success animation and message
        _showSuccessAnimation(
          icon: Icons.cancel_outlined,
          message: 'Challenge rejected',
          description: 'The challenge has been removed from your list.',
          iconColor: Colors.orange,
        );
      }
    } catch (e) {
      // Remove loading indicator
      loadingOverlay.remove();

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

  // Update task counts in Firestore to match actual data
  Future<void> _updateTaskCounts(int incompleteCount, int completedCount) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get the total count
      final totalCount = incompleteCount + completedCount;

      // Update the user document with the correct counts
      await _firestore.collection('users').doc(currentUser.uid).update({
        'totalTasks': totalCount,
        'completedTasks': completedCount,
      });
    } catch (e) {
      debugPrint('Error updating task counts: $e');
    }
  }

  Future<void> _completeChallenge(String challengeId) async {
    // First, show a confirmation dialog
    final bool confirmed = await _showCompletionConfirmationDialog();
    if (!confirmed) return; // User canceled the completion

    // Show loading indicator
    final loadingOverlay = _showLoadingOverlay('Completing challenge...');

    try {
      // Complete the challenge and get the reward details
      final rewardDetails = await _challengeService.completeChallenge(challengeId);

      // Remove loading indicator
      loadingOverlay.remove();

      if (mounted) {
        // Show celebration animation with the reward details
        _showEnhancedCelebrationAnimation(
          pointsEarned: rewardDetails['pointsEarned'],
          bonusPoints: rewardDetails['bonusPoints'],
          challengerName: rewardDetails['challengerName'],
          challengeDescription: rewardDetails['challengeDescription'],
        );
      }
    } catch (e) {
      // Remove loading indicator
      loadingOverlay.remove();

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
    return SizedBox(
      height: MediaQuery.of(context).size.height - 220, // Adjusted height to prevent overflow
      child: Column(
        children: [
          // Modern tab bar with enhanced design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(51),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'My Tasks'),
                Tab(text: 'Challenges'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Tasks tab
                _buildPersonalTasksTab(),

                // Challenges tab
                _buildEnhancedChallengesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTasksTab() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Please sign in to view your tasks'),
      );
    }

    // Use a more efficient approach with caching
    return StreamBuilder<List<Task>>(
      stream: _taskService.getUserTasks(currentUser.uid),
      builder: (context, snapshot) {
        // Show shimmer loading effect instead of spinner for better UX
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading tasks: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern empty state illustration
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withAlpha(26),
                              Theme.of(context).colorScheme.primary.withAlpha(13),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withAlpha(26),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withAlpha(51),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'No Tasks Yet',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Add your first task by tapping the + button below',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Add a hint arrow pointing to the FAB
                  Icon(
                    Icons.arrow_downward,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          );
        }

        // Separate tasks into completed and incomplete
        final incompleteTasks = tasks.where((task) => !task.isCompleted).toList();
        final completedTasks = tasks.where((task) => task.isCompleted).toList();

        // Update task counts in Firestore to match actual data
        _updateTaskCounts(incompleteTasks.length, completedTasks.length);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          strokeWidth: 2.5,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Completed tasks section
                  if (completedTasks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            'Completed',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${completedTasks.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: completedTasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final task = completedTasks[index];
                        return ModernTaskCard(
                          task: task,
                          onTaskUpdated: () {
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ],

                  // Incomplete tasks section
                  if (incompleteTasks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 24, bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            'To Do',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${incompleteTasks.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: incompleteTasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final task = incompleteTasks[index];
                        return ModernTaskCard(
                          task: task,
                          onTaskUpdated: () {
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ],
                ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedChallengesTab() {
    return DefaultTabController(
      length: 3,
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 250, // Adjust this value as needed
        child: Column(
          children: [
            // Sub-tabs for challenges with improved design
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(30),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
                tabs: const [
                  Tab(text: 'Received'),
                  Tab(text: 'Sent'),
                  Tab(text: 'Active'),
                ],
              ),
            ),

            // Challenge sub-tabs content
            Expanded(
              child: TabBarView(
                children: [
                  // Received challenges tab
                  _buildReceivedChallengesTab(),

                  // Sent challenges tab
                  _buildSentChallengesTab(),

                  // Active challenges tab
                  _buildActiveChallengesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedChallengesTab() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getPendingReceivedChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading challenges: ${snapshot.error}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
          );
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: AppTheme.accentColor.withAlpha(51),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Pending Challenges',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'When friends challenge you, they will appear here',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: challenges.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _buildPendingChallengeCard(challenge);
          },
        );
      },
    );
  }

  // Shimmer loading effect for better UX during loading
  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: AppTheme.shimmerBaseColor,
        highlightColor: AppTheme.shimmerHighlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title shimmer
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Task card shimmers
            for (int i = 0; i < 5; i++) ...[
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentChallengesTab() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getPendingSentChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading challenges: ${snapshot.error}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
          );
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_outlined,
                    size: 80,
                    color: AppTheme.accentColor.withAlpha(51),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Sent Challenges',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Challenge your friends to complete tasks',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: challenges.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _buildSentChallengeCard(challenge);
          },
        );
      },
    );
  }

  Widget _buildActiveChallengesTab() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getAcceptedChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading challenges: ${snapshot.error}',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
          );
        }

        final challenges = snapshot.data ?? [];

        if (challenges.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: AppTheme.accentColor.withAlpha(51),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Active Challenges',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Challenges you\'ve accepted will appear here',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: challenges.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _buildActiveChallengeCard(challenge);
          },
        );
      },
    );
  }

  Widget _buildPendingChallengeCard(Challenge challenge) {
    return FutureBuilder<UserModel?>(
      future: _friendService.getUserById(challenge.fromUserId),
      builder: (context, snapshot) {
        final challenger = snapshot.data;
        final challengerName = challenger?.email ?? 'Unknown User';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getAvatarColor(challengerName),
                      child: Text(
                        challengerName.isNotEmpty ? challengerName[0].toUpperCase() : '?',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge from $challengerName',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (challenge.createdAt != null)
                            Text(
                              DateFormat('MMM dd, yyyy').format(challenge.createdAt!),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PENDING',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.taskDescription,
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${challenge.points} points',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _rejectChallenge(challenge.id!),
                      child: Text(
                        'Decline',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _acceptChallenge(challenge.id!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveChallengeCard(Challenge challenge) {
    return FutureBuilder<UserModel?>(
      future: _friendService.getUserById(challenge.fromUserId),
      builder: (context, snapshot) {
        final challenger = snapshot.data;
        final challengerName = challenger?.email ?? 'Unknown User';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getAvatarColor(challengerName),
                      child: Text(
                        challengerName.isNotEmpty ? challengerName[0].toUpperCase() : '?',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge from $challengerName',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (challenge.createdAt != null)
                            Text(
                              DateFormat('MMM dd, yyyy').format(challenge.createdAt!),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  challenge.taskDescription,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.points} points',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeChallenge(challenge.id!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mark as Completed'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentChallengeCard(Challenge challenge) {
    return FutureBuilder<UserModel?>(
      future: _friendService.getUserById(challenge.toUserId),
      builder: (context, snapshot) {
        final recipient = snapshot.data;
        final recipientName = recipient?.email ?? 'Unknown User';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getAvatarColor(recipientName),
                      child: Text(
                        recipientName.isNotEmpty ? recipientName[0].toUpperCase() : '?',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge to $recipientName',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (challenge.createdAt != null)
                            Text(
                              DateFormat('MMM dd, yyyy').format(challenge.createdAt!),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SENT',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  challenge.taskDescription,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.points} points',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
}
