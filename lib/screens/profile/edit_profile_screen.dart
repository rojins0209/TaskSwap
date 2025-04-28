import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/models/user_model.dart';
import 'package:taskswap/screens/profile/profile_picture_screen.dart';
import 'package:taskswap/services/user_service.dart';

// Custom UserAvatar Widget
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? displayName;
  final String? email;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  final bool showShadow;

  const UserAvatar({
    Key? key,
    this.imageUrl,
    this.displayName,
    this.email,
    this.radius = 40,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.showShadow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get initials from display name or email
    String initials = '';
    if (displayName != null && displayName!.isNotEmpty) {
      final nameParts = displayName!.trim().split(' ');
      if (nameParts.length > 1) {
        initials = nameParts[0][0] + nameParts[1][0];
      } else if (nameParts.isNotEmpty) {
        initials = nameParts[0][0];
      }
    } else if (email != null && email!.isNotEmpty) {
      initials = email![0].toUpperCase();
    }

    final avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: borderColor ?? colorScheme.primary,
                width: borderWidth ?? 2,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius * 2),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(initials, colorScheme),
              )
            : _buildInitialsAvatar(initials, colorScheme),
      ),
    );

    return avatarWidget;
  }

  Widget _buildInitialsAvatar(String initials, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary,
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

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

    // Validate display name
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    // Check for special characters that might cause issues
    final RegExp validNameRegex = RegExp(r'^[a-zA-Z0-9 ._-]+$');
    if (!validNameRegex.hasMatch(displayName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name can only contain letters, numbers, spaces, and basic punctuation (._-)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check length
    if (displayName.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name must be 30 characters or less'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate user ID
      final String userId = widget.userProfile.id;
      if (userId.isEmpty) {
        throw ArgumentError('User ID is empty. Cannot update profile.');
      }

      // Update user profile (just the display name)
      await _userService.updateUserProfile(
        userId,
        displayName: displayName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return true to indicate successful update
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');

      if (mounted) {
        String errorMessage = 'Error updating profile';

        // Provide more specific error messages
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'You don\'t have permission to update this profile';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again';
        } else if (e.toString().contains('User ID')) {
          errorMessage = 'Invalid user ID. Please try logging out and back in.';
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'User profile not found. Please try logging out and back in.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
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
