import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskswap/models/challenge_model.dart';
import 'package:taskswap/models/task_category.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/auth_service.dart';
import 'package:taskswap/services/challenge_service.dart';
import 'package:taskswap/services/friend_service.dart';
import 'package:taskswap/utils/haptic_feedback_util.dart';

class CompetitiveChallengeCard extends StatefulWidget {
  final Challenge challenge;
  final Function? onProgressUpdated;

  const CompetitiveChallengeCard({
    super.key,
    required this.challenge,
    this.onProgressUpdated,
  });

  @override
  State<CompetitiveChallengeCard> createState() => _CompetitiveChallengeCardState();
}

class _CompetitiveChallengeCardState extends State<CompetitiveChallengeCard> {
  final AuthService _authService = AuthService();
  final FriendService _friendService = FriendService();
  final ChallengeService _challengeService = ChallengeService();

  bool _isUpdatingProgress = false;
  late double _myProgress;
  late double _friendProgress;
  late bool _amISender;
  late String _myUserId;
  late String _friendUserId;
  UserModel? _friendUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      _myUserId = currentUser.uid;
      _amISender = widget.challenge.fromUserId == _myUserId;
      _friendUserId = _amISender ? widget.challenge.toUserId : widget.challenge.fromUserId;

      // Load friend data
      _friendUser = await _friendService.getUserById(_friendUserId);

      // Set progress values
      _myProgress = _amISender ? (widget.challenge.senderProgress ?? 0.0) : (widget.challenge.receiverProgress ?? 0.0);
      _friendProgress = _amISender ? (widget.challenge.receiverProgress ?? 0.0) : (widget.challenge.senderProgress ?? 0.0);
    } catch (e) {
      debugPrint('Error loading challenge data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProgress(double progress) async {
    if (_isUpdatingProgress) return;

    setState(() {
      _isUpdatingProgress = true;
    });

    try {
      await _challengeService.updateChallengeProgress(
        widget.challenge.id!,
        progress,
      );

      // Update local state
      setState(() {
        _myProgress = progress;
      });

      // Notify parent
      if (widget.onProgressUpdated != null) {
        widget.onProgressUpdated!();
      }

      // Provide haptic feedback
      HapticFeedbackUtil.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating progress: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProgress = false;
        });
      }
    }
  }

  String _getTimeLeft() {
    if (widget.challenge.dueDate == null) return 'No deadline';

    final now = DateTime.now();
    final dueDate = widget.challenge.dueDate!;

    if (dueDate.isBefore(now)) {
      return 'Overdue';
    }

    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} left';
    }
  }

  String _getWinnerText() {
    if (widget.challenge.winnerUserId == null) return '';

    if (widget.challenge.winnerUserId == _myUserId) {
      return 'You won! 🏆';
    } else {
      return '${_friendUser?.displayName ?? 'Your friend'} won! 🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    final friendName = _friendUser?.displayName ?? _friendUser?.email ?? 'Your friend';
    final isCompleted = _myProgress >= 1.0 && _friendProgress >= 1.0;
    final hasWinner = widget.challenge.winnerUserId != null;
    final isOverdue = widget.challenge.dueDate != null &&
                      widget.challenge.dueDate!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with challenge info
            Row(
              children: [
                Icon(
                  widget.challenge.category.icon,
                  color: widget.challenge.category.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.challenge.taskDescription,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Competing with $friendName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withAlpha(30)
                        : isOverdue
                            ? Colors.red.withAlpha(30)
                            : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isCompleted
                        ? 'Completed'
                        : isOverdue
                            ? 'Overdue'
                            : _getTimeLeft(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCompleted
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Your progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Progress',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_myProgress * 100).toInt()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _myProgress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                    minHeight: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Friend's progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$friendName\'s Progress',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_friendProgress * 100).toInt()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _friendProgress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.secondary,
                    minHeight: 12,
                  ),
                ),
              ],
            ),

            // Winner badge if applicable
            if (hasWinner) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Text(
                  _getWinnerText(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Update progress buttons
            if (!isCompleted && _myProgress < 1.0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProgressButton(0.25, 'Add 25%'),
                  _buildProgressButton(0.5, 'Add 50%'),
                  _buildProgressButton(0.75, 'Add 75%'),
                  _buildProgressButton(1.0, 'Complete'),
                ],
              ),
            ],

            // Challenge details
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.challenge.points} points',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.challenge.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM d, yyyy').format(widget.challenge.dueDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOverdue ? Colors.red : colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressButton(double progressIncrement, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate the new progress if this button is pressed
    final newProgress = (_myProgress + progressIncrement).clamp(0.0, 1.0);

    // If this button wouldn't change the progress, disable it
    final isDisabled = newProgress <= _myProgress;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: isDisabled ? null : () => _updateProgress(newProgress),
          style: ElevatedButton.styleFrom(
            backgroundColor: progressIncrement == 1.0
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            foregroundColor: progressIncrement == 1.0
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            textStyle: theme.textTheme.bodySmall,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isUpdatingProgress
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: progressIncrement == 1.0
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
