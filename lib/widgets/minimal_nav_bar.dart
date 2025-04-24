import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/theme/app_theme.dart';

class MinimalNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<MinimalNavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double height;
  final double iconSize;
  final bool showLabels;
  final bool showIndicator;
  final EdgeInsets padding;
  final double borderRadius;
  final Widget? floatingActionButton;
  final bool centerFloatingActionButton;

  const MinimalNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.height = 56.0,
    this.iconSize = 24.0,
    this.showLabels = false,
    this.showIndicator = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    this.borderRadius = 0,
    this.floatingActionButton,
    this.centerFloatingActionButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.cardColor;
    final selectedColor = selectedItemColor ?? AppTheme.accentColor;
    final unselectedColor = unselectedItemColor ?? AppTheme.textSecondaryColor;

    // Calculate the width for the FAB space
    final hasFab = floatingActionButton != null && centerFloatingActionButton;
    final fabSpaceWidth = hasFab ? 80.0 : 0.0;

    return Container(
      height: height + padding.vertical,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main navigation bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == selectedIndex;

              // If we have a centered FAB and this is the middle item, add a spacer
              if (hasFab && index == items.length ~/ 2) {
                return SizedBox(width: fabSpaceWidth);
              }

              return Expanded(
                child: _buildNavItem(
                  item: items[index],
                  isSelected: isSelected,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  iconSize: iconSize,
                  showLabel: showLabels,
                  showIndicator: showIndicator,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onItemSelected(index);
                  },
                ),
              );
            }),
          ),

          // Floating Action Button (if provided and centered)
          if (hasFab)
            Positioned(
              top: -20,
              child: floatingActionButton!,
            ),

          // Floating Action Button (if provided but not centered)
          if (floatingActionButton != null && !centerFloatingActionButton)
            Positioned(
              right: 16,
              top: -20,
              child: floatingActionButton!,
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required MinimalNavBarItem item,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required double iconSize,
    required bool showLabel,
    required bool showIndicator,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final icon = isSelected ? item.activeIcon ?? item.icon : item.icon;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicator dot at the top
            if (showIndicator) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],

            // Icon
            Icon(
              icon,
              color: color,
              size: iconSize,
            ),

            // Label
            if (showLabel) ...[
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MinimalNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const MinimalNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
