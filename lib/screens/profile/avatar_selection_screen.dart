import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taskswap/models/avatar_model.dart';
import 'package:taskswap/services/avatar_service.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/widgets/custom_button.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String userId;
  final String? currentAvatarUrl;
  final Function(String) onAvatarSelected;

  const AvatarSelectionScreen({
    Key? key,
    required this.userId,
    this.currentAvatarUrl,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> with SingleTickerProviderStateMixin {
  final AvatarService _avatarService = AvatarService();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;
  File? _selectedImage;
  bool _isLoading = false;
  String? _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AvatarData.categories.length + 1, // +1 for custom upload tab
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedAvatarId = null; // Clear any selected predefined avatar
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveSelectedAvatar() async {
    if (_selectedImage == null && _selectedAvatarId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an avatar first')),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedImage != null) {
        // Upload custom avatar
        final downloadUrl = await _avatarService.uploadCustomAvatar(
          widget.userId,
          _selectedImage!,
        );

        if (downloadUrl != null) {
          widget.onAvatarSelected(downloadUrl);
        }
      } else if (_selectedAvatarId != null) {
        // Select predefined avatar
        final success = await _avatarService.selectPredefinedAvatar(
          widget.userId,
          _selectedAvatarId!,
        );

        if (success) {
          final avatar = AvatarData.findAvatarById(_selectedAvatarId!);
          if (avatar != null) {
            widget.onAvatarSelected(avatar.url);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving avatar: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Avatar'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Upload'),
            ...AvatarData.categories.map((category) => Tab(text: category.name)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Custom upload tab
          _buildCustomUploadTab(),
          // Predefined avatar category tabs
          ...AvatarData.categories.map((category) => _buildAvatarCategoryTab(category)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            onPressed: _isLoading ? null : () => _saveSelectedAvatar(),
            text: 'Save Avatar',
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomUploadTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload Photo',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tap to select a photo from your gallery',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your profile picture will be visible to all users',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCategoryTab(AvatarCategory category) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: category.avatars.length,
      itemBuilder: (context, index) {
        final avatar = category.avatars[index];
        final isSelected = _selectedAvatarId == avatar.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedAvatarId = avatar.id;
              _selectedImage = null; // Clear any selected custom image
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.accentColor : AppTheme.dividerColor,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accentColor.withAlpha(50),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.network(
                      avatar.url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: AppTheme.shimmerBaseColor,
                          highlightColor: AppTheme.shimmerHighlightColor,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading avatar image: $error');
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, color: AppTheme.accentColor, size: 40),
                            const SizedBox(height: 4),
                            Text(
                              avatar.name,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    avatar.name,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.accentColor : AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
