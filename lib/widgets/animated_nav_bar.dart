import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/theme/app_theme.dart';

class AnimatedNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double height;
  final double iconSize;
  final TextStyle? labelStyle;
  final bool showLabels;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;

  const AnimatedNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.height = 64.0,
    this.iconSize = 24.0,
    this.labelStyle,
    this.showLabels = true,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bgColor = backgroundColor ?? colorScheme.surface;
    final selectedColor = selectedItemColor ?? colorScheme.primary;
    final unselectedColor = unselectedItemColor ?? colorScheme.onSurfaceVariant;
    final defaultLabelStyle = labelStyle ?? AppTheme.labelSmall;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          final showLabel = showLabels && (isSelected ? showSelectedLabels : showUnselectedLabels);
          
          return _buildNavItem(
            context: context,
            item: items[index],
            isSelected: isSelected,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            iconSize: iconSize,
            labelStyle: defaultLabelStyle,
            showLabel: showLabel,
            onTap: () => onItemSelected(index),
          );
        }),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required NavBarItem item,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required double iconSize,
    required TextStyle labelStyle,
    required bool showLabel,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final icon = isSelected ? item.activeIcon ?? item.icon : item.icon;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      splashColor: selectedColor.withOpacity(0.1),
      highlightColor: selectedColor.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with scale effect
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 8 : 0),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              )
              .animate(target: isSelected ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: const Duration(milliseconds: 200),
              ),
            ),
            
            if (showLabel) ...[
              const SizedBox(height: 4),
              // Animated text with fade effect
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: labelStyle.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(item.label)
                .animate(target: isSelected ? 1 : 0)
                .fadeIn(duration: const Duration(milliseconds: 200)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
