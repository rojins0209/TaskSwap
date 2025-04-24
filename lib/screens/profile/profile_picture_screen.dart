import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/user_avatar.dart';
import 'package:path/path.dart' as path;

class ProfilePictureScreen extends StatefulWidget {
  final String userId;
  final String? currentPhotoUrl;

  const ProfilePictureScreen({
    super.key,
    required this.userId,
    this.currentPhotoUrl,
  });

  @override
  State<ProfilePictureScreen> createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UserService _userService = UserService();

  File? _imageFile;
  bool _isUploading = false;
  String? _uploadError;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Profile Picture',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          if (_imageFile != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadImage,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _isUploading ? colorScheme.onSurfaceVariant : colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Current or selected profile picture
              Center(
                child: _buildProfileImage(),
              ),

              const SizedBox(height: 32),

              // Image selection options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.photo_camera,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildOptionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  if (widget.currentPhotoUrl != null)
                    _buildOptionButton(
                      icon: Icons.delete,
                      label: 'Remove',
                      onTap: _removeCurrentPhoto,
                    ),
                ],
              ),

              // Upload progress indicator
              if (_isUploading) ...[
                const SizedBox(height: 32),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: theme.brightness == Brightness.dark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // Error message
              if (_uploadError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _uploadError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;

    if (_imageFile != null) {
      // Show selected image
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 20 : 40),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              image: DecorationImage(
                image: FileImage(_imageFile!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 20 : 40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.edit,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
        ],
      );
    } else {
      // Show current profile picture or fallback
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          UserAvatar(
            imageUrl: widget.currentPhotoUrl,
            radius: 80,
            showBorder: true,
            borderColor: borderColor,
            borderWidth: 4,
            showShadow: true,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 20 : 40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.add_a_photo,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppTheme.accentColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error picking image: $e';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
    });

    try {
      // Create a unique filename
      final String fileName = 'profile_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_imageFile!.path)}';

      // Create a reference to the location you want to upload to in Firebase Storage
      final Reference storageRef = _storage.ref().child('profile_pictures/$fileName');

      // Upload the file to Firebase Storage
      final UploadTask uploadTask = storageRef.putFile(_imageFile!);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      // Wait for the upload to complete
      await uploadTask.whenComplete(() {});

      // Get the download URL
      final String downloadUrl = await storageRef.getDownloadURL();

      // Update the user's profile with the new photo URL
      await _userService.updateUserProfile(
        widget.userId,
        photoUrl: downloadUrl,
      );

      // Return to the previous screen with success
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Error uploading image: $e';
      });
    }
  }

  Future<void> _removeCurrentPhoto() async {
    if (widget.currentPhotoUrl == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
    });

    try {
      // Update the user's profile to remove the photo URL
      await _userService.updateUserProfile(
        widget.userId,
        photoUrl: '',
      );

      setState(() {
        _isUploading = false;
      });

      // Return to the previous screen with success
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Error removing profile picture: $e';
      });
    }
  }
}
