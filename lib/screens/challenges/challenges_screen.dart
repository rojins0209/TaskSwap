import 'package:flutter/material.dart';
import 'package:taskswap/models/challenge_model.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/screens/challenges/create_challenge_screen.dart';
import 'package:taskswap/widgets/celebration_overlay.dart';
import 'package:intl/intl.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  final ChallengeService _challengeService = ChallengeService();
  final FriendService _friendService = FriendService();
  late TabController _tabController;

  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptChallenge(String challengeId) async {
    try {
      await _challengeService.acceptChallenge(challengeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge accepted'),
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

  Future<void> _rejectChallenge(String challengeId) async {
    try {
      await _challengeService.rejectChallenge(challengeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge rejected'),
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

  Future<void> _completeChallenge(String challengeId) async {
    try {
      final result = await _challengeService.completeChallenge(challengeId);

      if (mounted) {
        // Show celebration animation
        setState(() {
          _showCelebration = true;
        });
      }

      // Snackbar will be shown after animation completes
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

  Future<void> _completeChallengeAsSender(String challengeId) async {
    try {
      final result = await _challengeService.completeChallengeAsSender(challengeId);

      if (mounted) {
        // Show celebration animation
        setState(() {
          _showCelebration = true;
        });
      }

      // Snackbar will be shown after animation completes
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
    return Stack(
      children: [
        Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Challenges',
          style: AppTheme.headingSmall,
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.accentColor,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending challenges tab
          _buildPendingChallengesTab(),

          // Active challenges tab
          _buildActiveChallengesTab(),

          // Completed challenges tab
          _buildCompletedChallengesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateChallengeScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.accentColor,
        heroTag: 'challengesScreenFab', // Add unique hero tag
        child: const Icon(Icons.add),
      ),
    ),

    // Celebration overlay
    if (_showCelebration)
      CelebrationOverlay(
        onAnimationComplete: () {
          setState(() {
            _showCelebration = false;
          });

          // Show snackbar after animation completes
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge completed! You earned aura points!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    ],
    );
  }

  Widget _buildPendingChallengesTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub-tabs for received and sent challenges
          TabBar(
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.accentColor,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),

          // Challenge sub-tabs content
          Expanded(
            child: TabBarView(
              children: [
                // Received challenges tab
                _buildReceivedChallengesContent(),

                // Sent challenges tab
                _buildSentChallengesContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedChallengesContent() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getPendingReceivedChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 80,
                  color: AppTheme.accentColor.withAlpha(128),
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

  Widget _buildSentChallengesContent() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getPendingSentChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 50,
                  color: AppTheme.accentColor.withAlpha(128),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Sent Challenges',
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Challenge your friends to complete tasks',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub-tabs for received and sent challenges
          TabBar(
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.accentColor,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'To Complete'),
              Tab(text: 'My Challenges'),
            ],
          ),

          // Challenge sub-tabs content
          Expanded(
            child: TabBarView(
              children: [
                // Challenges to complete
                _buildChallengesReceivedContent(),

                // Challenges I sent that I need to complete
                _buildChallengesSentContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesReceivedContent() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getAcceptedChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 80,
                  color: AppTheme.accentColor.withAlpha(128),
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

  Widget _buildCompletedChallengesTab() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getCompletedChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.celebration_outlined,
                  size: 80,
                  color: AppTheme.accentColor.withAlpha(128),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Completed Challenges',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Completed challenges will appear here',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: challenges.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _buildCompletedChallengeCard(challenge);
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
                        color: Colors.orange.withAlpha(30),
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

                // Due date if available
                if (challenge.dueDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _getDueDateColor(challenge.dueDate!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(challenge.dueDate!)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: _getDueDateColor(challenge.dueDate!),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],

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

                // Challenge status section
                if (challenge.bothUsersComplete) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Both users need to complete this challenge',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    challenge.senderCompleted ? Icons.check_circle : Icons.circle_outlined,
                                    color: challenge.senderCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      challengerName,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: challenge.senderCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    challenge.receiverCompleted ? Icons.check_circle : Icons.circle_outlined,
                                    color: challenge.receiverCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: challenge.receiverCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: challenge.receiverCompleted ? null : () => _completeChallenge(challenge.id!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.textSecondaryColor.withAlpha(76),
                    ),
                    child: Text(challenge.receiverCompleted ? 'Completed' : 'Mark as Completed'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      // Past due
      return Colors.red;
    } else if (difference <= 1) {
      // Due today or tomorrow
      return Colors.orange;
    } else {
      // Due in the future
      return Colors.green;
    }
  }

  Widget _buildChallengesSentContent() {
    return StreamBuilder<List<Challenge>>(
      stream: _challengeService.getSenderChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 80,
                  color: AppTheme.accentColor.withAlpha(128),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Challenges to Complete',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Challenges you\'ve sent that require your completion will appear here',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: challenges.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return _buildSenderChallengeCard(challenge);
          },
        );
      },
    );
  }

  Widget _buildSenderChallengeCard(Challenge challenge) {
    return FutureBuilder<UserModel?>(
      future: _friendService.getUserById(challenge.toUserId),
      builder: (context, snapshot) {
        final recipient = snapshot.data;
        final recipientName = recipient?.email ?? 'Unknown User';

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
                            'Challenge with $recipientName',
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
                        color: Colors.purple.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'YOUR TURN',
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

                // Due date if available
                if (challenge.dueDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _getDueDateColor(challenge.dueDate!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(challenge.dueDate!)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: _getDueDateColor(challenge.dueDate!),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],

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

                // Challenge status section
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Both users need to complete this challenge',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  challenge.senderCompleted ? Icons.check_circle : Icons.circle_outlined,
                                  color: challenge.senderCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: challenge.senderCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  challenge.receiverCompleted ? Icons.check_circle : Icons.circle_outlined,
                                  color: challenge.receiverCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recipientName,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: challenge.receiverCompleted ? Colors.green : AppTheme.textSecondaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: challenge.senderCompleted ? null : () => _completeChallengeAsSender(challenge.id!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.textSecondaryColor.withAlpha(76),
                    ),
                    child: Text(challenge.senderCompleted ? 'Completed' : 'Mark as Completed'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedChallengeCard(Challenge challenge) {
    return FutureBuilder<UserModel?>(
      future: _friendService.getUserById(
        challenge.fromUserId,
      ),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userName = user?.email ?? 'Unknown User';

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
                      backgroundColor: _getAvatarColor(userName),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
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
                            'Challenge from $userName',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (challenge.completedAt != null)
                            Text(
                              'Completed on ${DateFormat('MMM dd, yyyy').format(challenge.completedAt!)}',
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
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'COMPLETED',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.green,
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
                      '${challenge.points} points earned',
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

  Widget _buildSentChallengeCard(Challenge challenge) {
    return FutureBuilder<UserModel?>(
      future: _friendService.getUserById(challenge.toUserId),
      builder: (context, snapshot) {
        final recipient = snapshot.data;
        final recipientName = recipient?.email ?? 'Unknown User';

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
                        color: Colors.purple.withAlpha(30),
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
