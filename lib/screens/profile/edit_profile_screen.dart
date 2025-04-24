import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/screens/profile/profile_picture_screen.dart';
import 'package:taskswap/services/user_service.dart';

import 'package:taskswap/widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final TextEditingController _displayNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.userProfile.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _openProfilePictureScreen() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePictureScreen(
          userId: widget.userProfile.id,
          currentPhotoUrl: widget.userProfile.photoUrl,
        ),
      ),
    );

    // Refresh the profile after returning from profile picture screen
    if (result == true) {
      // Refresh user profile
      final updatedUser = await _userService.getUserById(widget.userProfile.id);
      if (updatedUser != null && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update user profile (just the display name)
      await _userService.updateUserProfile(
        widget.userProfile.id,
        displayName: displayName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Profile Avatar (editable)
            GestureDetector(
              onTap: _openProfilePictureScreen,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  UserAvatar(
                    imageUrl: widget.userProfile.photoUrl,
                    displayName: widget.userProfile.displayName,
                    email: widget.userProfile.email,
                    radius: 60,
                    showShadow: true,
                    showBorder: true,
                    borderColor: theme.brightness == Brightness.dark ? colorScheme.surfaceContainerHighest : Colors.white,
                    borderWidth: 3,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.photo_camera,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Display Name Field
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        'Save Profile',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
