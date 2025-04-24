import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskswap/screens/notifications/notifications_screen.dart';
import 'package:taskswap/theme/app_theme.dart';

class NotificationBadge extends StatelessWidget {
  final Color? badgeColor;
  final Color? iconColor;

  const NotificationBadge({
    super.key,
    this.badgeColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final colorScheme = Theme.of(context).colorScheme;

    // Get the current user
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink(); // Don't show badge if not logged in
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading and error states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          debugPrint('Error loading notifications: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final unreadCount = snapshot.data?.docs.length ?? 0;

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: iconColor ?? colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppTheme.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: unreadCount > 9
                        ? Center(
                            child: Text(
                              '9+',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
          ],
        ),
      );
      },
    );
  }
}
