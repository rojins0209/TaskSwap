import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskswap/models/notification_model.dart';
import 'package:taskswap/services/notification_service.dart';
import 'package:taskswap/screens/profile/user_profile_screen.dart';
import 'package:taskswap/utils/firestore_index_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
          // Delete all button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Delete all',
            onPressed: _showDeleteAllConfirmation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.getUserNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final errorMessage = snapshot.error.toString();

                  // Check if this is a Firestore index error
                  if (errorMessage.contains('failed-precondition') &&
                      errorMessage.contains('requires an index')) {
                    // Extract the index URL if present
                    final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(errorMessage);
                    final indexUrl = urlMatch?.group(0);

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Missing Firestore Index',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The app needs a database index to display notifications properly.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                if (indexUrl != null) {
                                  FirestoreIndexHelper.openIndexCreationPage(context, indexUrl);
                                } else {
                                  FirestoreIndexHelper.showNotificationsIndexDialog(context);
                                }
                              },
                              child: const Text('Create Index'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Default error display
                  return Center(
                    child: Text(
                      'Error loading notifications: ${snapshot.error}',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'You\'ll see notifications here when you receive aura, complete challenges, or reach milestones.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Format timestamp
    final timestamp = notification.timestamp;
    final formattedTime = timestamp != null
        ? DateFormat.yMMMd().add_jm().format(timestamp)
        : 'Just now';

    // Get icon based on notification type
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.auraReceived:
        iconData = Icons.auto_awesome;
        iconColor = colorScheme.primary;
        break;
      case NotificationType.challengeCompleted:
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case NotificationType.challengeExpired:
        iconData = Icons.timer_off;
        iconColor = Colors.red;
        break;
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case NotificationType.friendAccepted:
        iconData = Icons.people;
        iconColor = Colors.green;
        break;
      case NotificationType.milestone:
        iconData = Icons.star;
        iconColor = Colors.purple;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = colorScheme.onSurfaceVariant;
        break;
      case NotificationType.taskCompleted:
        iconData = Icons.task_alt;
        iconColor = Colors.green;
        break;
    }

    return Dismissible(
      key: Key(notification.id ?? ''),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification.id!);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: colorScheme.surfaceTint.withAlpha(20),
        color: notification.read ? null : colorScheme.primaryContainer.withAlpha(76), // 0.3 * 255 = 76
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Use the lightest possible feedback
            HapticFeedback.selectionClick();
            if (!notification.read) {
              _markAsRead(notification.id!);
            }
            _handleNotificationTap(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.read)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle different notification types
    switch (notification.type) {
      case NotificationType.auraReceived:
        if (notification.fromUserId != null) {
          _navigateToUserProfile(notification.fromUserId!);
        }
        break;
      case NotificationType.challengeCompleted:
        if (notification.fromUserId != null) {
          _navigateToUserProfile(notification.fromUserId!);
        }
        break;
      case NotificationType.challengeExpired:
        // Navigate to the related task if available
        if (notification.relatedTaskId != null) {
          // Navigate to task details screen
          // This would require implementing a navigation method to the task details screen
          // For now, just mark as read
        }
        break;
      case NotificationType.friendRequest:
        if (notification.fromUserId != null) {
          _navigateToUserProfile(notification.fromUserId!);
        }
        break;
      case NotificationType.friendAccepted:
        if (notification.fromUserId != null) {
          _navigateToUserProfile(notification.fromUserId!);
        }
        break;
      case NotificationType.milestone:
      case NotificationType.system:
        // Just mark as read, no navigation
        break;
      case NotificationType.taskCompleted:
        if (notification.fromUserId != null) {
          _navigateToUserProfile(notification.fromUserId!);
        }
        break;
    }
  }

  void _navigateToUserProfile(String userId) async {
    try {
      // Check if the user exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && mounted) {
        // User exists, navigate to their profile

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: userId,
              // We're not passing initialUserData since it would require importing UserModel
              // which could potentially create another circular dependency
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to user profile: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notification as read: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.markAllNotificationsAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications marked as read'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking all notifications as read: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteAllConfirmation() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete All Notifications',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              // Use the lightest possible feedback
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Use the lightest possible feedback even for destructive actions
              HapticFeedback.selectionClick();
              Navigator.pop(context);
              _deleteAllNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllNotifications() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.deleteAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications deleted'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting all notifications: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
