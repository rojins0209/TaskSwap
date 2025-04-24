import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double? titleFontSize;
  final IconData? leadingIcon;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.subtitle,
    this.showBackButton = false,
    this.onBackPressed,
    this.centerTitle = false,
    this.titleFontSize,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withAlpha(100),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button or leading icon
          if (showBackButton) ...[
            IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 24),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ] else if (leadingIcon != null) ...[
            Icon(leadingIcon, color: colorScheme.primary, size: 24),
            const SizedBox(width: 16),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: titleFontSize ?? 38,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  subtitle!,
                ],
              ],
            ),
          ),

          // Action buttons with consistent spacing
          if (actions != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final action in actions!)
                  if (action is IconButton)
                    IconButton(
                      icon: action.icon,
                      onPressed: action.onPressed,
                      tooltip: action.tooltip,
                      iconSize: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    action,
              ],
            ),
          ],
        ],
      ),
    );
  }
}
