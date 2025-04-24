import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/models/activity_model.dart';
import 'package:taskswap/services/activity_service.dart';
import 'package:taskswap/widgets/modern_activity_card.dart';
import 'package:taskswap/widgets/app_header.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ActivityService _activityService = ActivityService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool _isRefreshing = false;
  String _filterType = 'All';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Consistent app header
            AppHeader(
              title: 'Activity Feed',
              titleFontSize: 32,
              subtitle: Text(
                'See what your friends are up to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              actions: [
                // Filter button
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      _filterType == 'All' ? Icons.filter_list : _getFilterIcon(),
                      color: _filterType == 'All' ? colorScheme.onSurfaceVariant : colorScheme.primary,
                    ),
                    tooltip: 'Filter activities',
                    onSelected: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _filterType = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'All',
                        child: Row(
                          children: [
                            Icon(
                              Icons.feed_outlined,
                              color: _filterType == 'All' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('All Activities'),
                            if (_filterType == 'All')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: colorScheme.primary, size: 16),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Tasks',
                        child: Row(
                          children: [
                            Icon(
                              Icons.task_alt,
                              color: _filterType == 'Tasks' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Tasks Completed'),
                            if (_filterType == 'Tasks')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: colorScheme.primary, size: 16),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Challenges',
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              color: _filterType == 'Challenges' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Challenges'),
                            if (_filterType == 'Challenges')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: colorScheme.primary, size: 16),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Aura',
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: _filterType == 'Aura' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Aura Points'),
                            if (_filterType == 'Aura')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: colorScheme.primary, size: 16),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Friends',
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: _filterType == 'Friends' ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Friend Activity'),
                            if (_filterType == 'Friends')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: colorScheme.primary, size: 16),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Refresh button
                IconButton(
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
                  tooltip: 'Refresh feed',
                  onPressed: _isRefreshing
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        _refreshIndicatorKey.currentState?.show();
                      },
                ),
              ],
            ),

            // Filter chip (when filter is active)
            if (_filterType != 'All')
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    Chip(
                      avatar: Icon(_getFilterIcon(), size: 16, color: colorScheme.primary),
                      label: Text('Filtered by: $_filterType'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _filterType = 'All';
                        });
                      },
                      backgroundColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: StreamBuilder<List<Activity>>(
                stream: _activityService.getFeedActivities(),
                builder: (context, snapshot) {
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
                            size: 80,
                            color: colorScheme.error.withAlpha(179),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Error loading feed: ${snapshot.error}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
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

                  var activities = snapshot.data ?? [];

                  // Apply filters
                  if (_filterType != 'All') {
                    activities = activities.where((activity) {
                      switch (_filterType) {
                        case 'Tasks':
                          return activity.type == ActivityType.taskCompleted;
                        case 'Challenges':
                          return activity.type == ActivityType.challengeCompleted;
                        case 'Aura':
                          return activity.type == ActivityType.auraGiven ||
                                 activity.type == ActivityType.auraReceived;
                        case 'Friends':
                          return activity.type == ActivityType.friendAdded;
                        default:
                          return true;
                      }
                    }).toList();
                  }

                  if (activities.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _filterType == 'All' ? Icons.feed_outlined : _getFilterIcon(),
                              size: 80,
                              color: colorScheme.primary.withAlpha(128),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _filterType == 'All' ? 'No Activity Yet' : 'No $_filterType Activity',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _getEmptyMessage(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (_filterType != 'All')
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _filterType = 'All';
                                  });
                                },
                                icon: const Icon(Icons.filter_alt_off),
                                label: const Text('Clear Filter'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: () async {
                      setState(() {
                        _isRefreshing = true;
                      });

                      // Add a small delay for better UX
                      await Future.delayed(const Duration(milliseconds: 800));

                      setState(() {
                        _isRefreshing = false;
                      });
                    },
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    child: ListView.builder(
                      itemCount: activities.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return ModernActivityCard(
                          activity: activity,
                          showUserInfo: true,
                          onActivityUpdated: () {
                            // Force a complete refresh of the feed
                            setState(() {
                              _isRefreshing = true;
                            });

                            // Add a small delay to ensure Firestore updates are reflected
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                setState(() {
                                  _isRefreshing = false;
                                });
                              }
                            });
                          },
                        );
                      },
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

  IconData _getFilterIcon() {
    switch (_filterType) {
      case 'Tasks':
        return Icons.task_alt;
      case 'Challenges':
        return Icons.emoji_events_outlined;
      case 'Aura':
        return Icons.auto_awesome;
      case 'Friends':
        return Icons.people_outline;
      default:
        return Icons.feed_outlined;
    }
  }

  String _getEmptyMessage() {
    switch (_filterType) {
      case 'Tasks':
        return 'No completed tasks to show. Complete some tasks to see them here.';
      case 'Challenges':
        return 'No challenges completed yet. Complete challenges from your friends to see them here.';
      case 'Aura':
        return 'No aura activity yet. Give or receive aura points to see them here.';
      case 'Friends':
        return 'No friend activity yet. Add friends to see their activity here.';
      default:
        return 'Your feed shows activities from you and your friends. Add friends to see their activities here.';
    }
  }
}
