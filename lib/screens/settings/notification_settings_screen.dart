import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taskswap/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  bool _isLoading = true;
  bool _pushNotificationsEnabled = true;
  bool _auraNotificationsEnabled = true;
  bool _challengeNotificationsEnabled = true;
  bool _friendNotificationsEnabled = true;
  bool _milestoneNotificationsEnabled = true;
  bool _systemNotificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }
  
  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final notificationSettings = userData['notificationSettings'] as Map<String, dynamic>? ?? {};
      
      setState(() {
        _pushNotificationsEnabled = notificationSettings['pushEnabled'] ?? true;
        _auraNotificationsEnabled = notificationSettings['auraEnabled'] ?? true;
        _challengeNotificationsEnabled = notificationSettings['challengeEnabled'] ?? true;
        _friendNotificationsEnabled = notificationSettings['friendEnabled'] ?? true;
        _milestoneNotificationsEnabled = notificationSettings['milestoneEnabled'] ?? true;
        _systemNotificationsEnabled = notificationSettings['systemEnabled'] ?? true;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading notification settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Prepare notification settings map
      final notificationSettings = {
        'pushEnabled': _pushNotificationsEnabled,
        'auraEnabled': _auraNotificationsEnabled,
        'challengeEnabled': _challengeNotificationsEnabled,
        'friendEnabled': _friendNotificationsEnabled,
        'milestoneEnabled': _milestoneNotificationsEnabled,
        'systemEnabled': _systemNotificationsEnabled,
      };
      
      // Update user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'notificationSettings': notificationSettings,
      });
      
      // If push notifications are enabled, request permission and save token
      if (_pushNotificationsEnabled) {
        await _notificationService.initNotifications();
        await _notificationService.saveFCMToken();
      }
      
      _showSuccessSnackBar('Notification settings saved successfully');
    } catch (e) {
      _showErrorSnackBar('Error saving notification settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info card
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Preferences',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Customize which notifications you want to receive. You can enable or disable different types of notifications based on your preferences.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Push notifications toggle
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive notifications on your device'),
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                    },
                    secondary: Icon(
                      Icons.notifications,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                
                // Notification types
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Notification Types',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Aura Points'),
                        subtitle: const Text('When you receive aura points from friends'),
                        value: _auraNotificationsEnabled,
                        onChanged: _pushNotificationsEnabled
                            ? (value) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _auraNotificationsEnabled = value;
                                });
                              }
                            : null,
                        secondary: Icon(
                          Icons.auto_awesome,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Challenges'),
                        subtitle: const Text('When you receive or complete challenges'),
                        value: _challengeNotificationsEnabled,
                        onChanged: _pushNotificationsEnabled
                            ? (value) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _challengeNotificationsEnabled = value;
                                });
                              }
                            : null,
                        secondary: Icon(
                          Icons.emoji_events_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Friend Requests'),
                        subtitle: const Text('When you receive friend requests or updates'),
                        value: _friendNotificationsEnabled,
                        onChanged: _pushNotificationsEnabled
                            ? (value) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _friendNotificationsEnabled = value;
                                });
                              }
                            : null,
                        secondary: Icon(
                          Icons.people_outline,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('Milestones'),
                        subtitle: const Text('When you reach streaks or achievements'),
                        value: _milestoneNotificationsEnabled,
                        onChanged: _pushNotificationsEnabled
                            ? (value) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _milestoneNotificationsEnabled = value;
                                });
                              }
                            : null,
                        secondary: Icon(
                          Icons.star_outline,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        title: const Text('System Updates'),
                        subtitle: const Text('Important app updates and announcements'),
                        value: _systemNotificationsEnabled,
                        onChanged: _pushNotificationsEnabled
                            ? (value) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _systemNotificationsEnabled = value;
                                });
                              }
                            : null,
                        secondary: Icon(
                          Icons.system_update_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveNotificationSettings,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
    );
  }
}
