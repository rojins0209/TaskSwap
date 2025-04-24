import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/theme/app_theme.dart';
import 'package:taskswap/utils/performance_utils.dart';

/// A reusable widget for displaying user avatars with proper error handling
class UserAvatar extends StatelessWidget {
  /// The URL of the avatar image
  final String? imageUrl;

  /// The display name of the user (used for fallback)
  final String? displayName;

  /// The email of the user (used for fallback if displayName is null)
  final String? email;

  /// The radius of the avatar
  final double radius;

  /// Whether to show a border around the avatar
  final bool showBorder;

  /// The color of the border
  final Color borderColor;

  /// The width of the border
  final double borderWidth;

  /// Whether to show a shadow around the avatar
  final bool showShadow;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.email,
    this.radius = 40,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder ? Border.all(color: borderColor, width: borderWidth) : null,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty && imageUrl!.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  backgroundImage: imageProvider,
                  radius: radius,
                ),
                placeholder: (context, url) => CircleAvatar(
                  backgroundColor: Colors.grey.withAlpha(51),
                  radius: radius,
                  child: SizedBox(
                    width: radius * 0.5,
                    height: radius * 0.5,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildFallbackAvatar(),
                memCacheWidth: (radius * 2 * MediaQuery.of(context).devicePixelRatio).toInt(),
                memCacheHeight: (radius * 2 * MediaQuery.of(context).devicePixelRatio).toInt(),
                fadeInDuration: const Duration(milliseconds: 200),
              )
            : _buildFallbackAvatar(),
      ),
    );
  }

  /// Builds an avatar with initials
  Widget _buildFallbackAvatar() {
    // Get initials from display name or email username
    String initials;
    if (displayName?.isNotEmpty == true) {
      // Use first letter of first name and last name if available
      final nameParts = displayName!.split(' ');
      if (nameParts.length > 1) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        initials = displayName![0].toUpperCase();
      }
    } else if (email?.isNotEmpty == true) {
      // Use first letter of email username
      initials = email!.split('@')[0][0].toUpperCase();
    } else {
      initials = '?';
    }

    // Generate a consistent color based on the initials or email
    final int colorSeed = (email ?? displayName ?? initials).hashCode;
    final List<Color> avatarColors = [
      Colors.blue[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.amber[600]!,
      Colors.deepOrange[400]!,
      Colors.indigo[400]!,
      Colors.pink[400]!,
      Colors.green[500]!,
    ];
    final Color avatarColor = avatarColors[colorSeed.abs() % avatarColors.length];

    return CircleAvatar(
      backgroundColor: avatarColor,
      radius: radius,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
