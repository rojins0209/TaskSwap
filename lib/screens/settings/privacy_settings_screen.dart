import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/services/user_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  UserModel? _userProfile;
  List<UserModel> _blockedUsers = [];
  
  // Current settings
  AuraVisibility _auraVisibility = AuraVisibility.public;
  AllowAuraFrom _allowAuraFrom = AllowAuraFrom.everyone;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Load user profile
        final userProfile = await _userService.getUserById(userId);
        if (userProfile != null) {
          setState(() {
            _userProfile = userProfile;
            _auraVisibility = userProfile.auraVisibility;
            _allowAuraFrom = userProfile.allowAuraFrom;
          });
        }
        
        // Load blocked users
        final blockedUsers = await _userService.getBlockedUsers(userId);
        setState(() {
          _blockedUsers = blockedUsers;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updatePrivacySettings() async {
    if (_userProfile == null || _auth.currentUser == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _userService.updatePrivacySettings(
        _auth.currentUser!.uid,
        auraVisibility: _auraVisibility,
        allowAuraFrom: _allowAuraFrom,
      );
      
      _showSuccessSnackBar('Privacy settings updated successfully');
    } catch (e) {
      _showErrorSnackBar('Error updating privacy settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _unblockUser(UserModel user) async {
    if (_auth.currentUser == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _userService.unblockUser(_auth.currentUser!.uid, user.id);
      
      // Refresh blocked users list
      final blockedUsers = await _userService.getBlockedUsers(_auth.currentUser!.uid);
      setState(() {
        _blockedUsers = blockedUsers;
      });
      
      _showSuccessSnackBar('${user.displayName ?? user.email} has been unblocked');
    } catch (e) {
      _showErrorSnackBar('Error unblocking user: $e');
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Aura Visibility Settings
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aura Visibility',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Control who can see your aura points and activities',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildVisibilityOption(
                          context,
                          AuraVisibility.public,
                          Icons.public,
                          'Public',
                          'Everyone can see your aura points and activities',
                        ),
                        const Divider(),
                        _buildVisibilityOption(
                          context,
                          AuraVisibility.friends,
                          Icons.people,
                          'Friends Only',
                          'Only your friends can see your aura points and activities',
                        ),
                        const Divider(),
                        _buildVisibilityOption(
                          context,
                          AuraVisibility.private,
                          Icons.lock_outline,
                          'Private',
                          'Only you can see your aura points and activities',
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Allow Aura From Settings
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allow Aura From',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Control who can give you aura points',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildAllowAuraOption(
                          context,
                          AllowAuraFrom.everyone,
                          Icons.public,
                          'Everyone',
                          'Anyone can give you aura points',
                        ),
                        const Divider(),
                        _buildAllowAuraOption(
                          context,
                          AllowAuraFrom.friends,
                          Icons.people,
                          'Friends Only',
                          'Only your friends can give you aura points',
                        ),
                        const Divider(),
                        _buildAllowAuraOption(
                          context,
                          AllowAuraFrom.none,
                          Icons.block,
                          'No One',
                          'No one can give you aura points',
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Blocked Users
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blocked Users',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage users you have blocked',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        if (_blockedUsers.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'You haven\'t blocked any users',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _blockedUsers.length,
                            itemBuilder: (context, index) {
                              final user = _blockedUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primary,
                                  child: Text(
                                    user.displayName?[0].toUpperCase() ?? 
                                    user.email[0].toUpperCase(),
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(user.displayName ?? user.email),
                                subtitle: Text(user.email),
                                trailing: TextButton(
                                  onPressed: () => _unblockUser(user),
                                  child: const Text('Unblock'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePrivacySettings,
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
  
  Widget _buildVisibilityOption(
    BuildContext context,
    AuraVisibility visibility,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _auraVisibility == visibility;
    
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _auraVisibility = visibility;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<AuraVisibility>(
              value: visibility,
              groupValue: _auraVisibility,
              onChanged: (value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _auraVisibility = value;
                  });
                }
              },
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAllowAuraOption(
    BuildContext context,
    AllowAuraFrom allowFrom,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _allowAuraFrom == allowFrom;
    
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _allowAuraFrom = allowFrom;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<AllowAuraFrom>(
              value: allowFrom,
              groupValue: _allowAuraFrom,
              onChanged: (value) {
                if (value != null) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _allowAuraFrom = value;
                  });
                }
              },
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
