import 'package:flutter/material.dart';
import 'package:taskswap/models/challenge_model.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/widgets/competitive_challenge_card.dart';
import 'package:taskswap/widgets/empty_state.dart';

class CompetitiveChallengesScreen extends StatefulWidget {
  const CompetitiveChallengesScreen({Key? key}) : super(key: key);

  @override
  State<CompetitiveChallengesScreen> createState() => _CompetitiveChallengesScreenState();
}

class _CompetitiveChallengesScreenState extends State<CompetitiveChallengesScreen> {
  final ChallengeService _challengeService = ChallengeService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Competitive Challenges',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Challenge>>(
          stream: _challengeService.getCompetitiveChallenges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading challenges: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }

            final challenges = snapshot.data ?? [];

            if (challenges.isEmpty) {
              return EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No Competitive Challenges',
                description: 'Create a challenge with a friend to compete on completing tasks together.',
                actionLabel: 'Create Challenge',
                onAction: () {
                  Navigator.pushNamed(context, '/add-task', arguments: {'isChallenge': true});
                },
              );
            }

            // Separate active and completed challenges
            final activeChallenges = challenges.where((c) => c.status == ChallengeStatus.accepted).toList();
            final completedChallenges = challenges.where((c) => c.status == ChallengeStatus.completed).toList();

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active challenges section
                    if (activeChallenges.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Row(
                          children: [
                            Text(
                              'Active Challenges',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${activeChallenges.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...activeChallenges.map((challenge) => CompetitiveChallengeCard(
                        challenge: challenge,
                        onProgressUpdated: () {
                          setState(() {});
                        },
                      )),
                    ],

                    // Completed challenges section
                    if (completedChallenges.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 24, bottom: 16),
                        child: Row(
                          children: [
                            Text(
                              'Completed Challenges',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${completedChallenges.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...completedChallenges.map((challenge) => CompetitiveChallengeCard(
                        challenge: challenge,
                      )),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-task', arguments: {'isChallenge': true, 'challengeYourself': true});
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
