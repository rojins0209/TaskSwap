import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/theme/app_theme.dart';

class Material3NavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<Material3NavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? indicatorColor;
  final double height;
  final double iconSize;
  final bool showLabels;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  final double indicatorHeight;
  final double indicatorWidth;
  final Widget? floatingActionButton;
  final bool useMaterial3Style;

  const Material3NavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.indicatorColor,
    this.height = 80.0,
    this.iconSize = 24.0,
    this.showLabels = true,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    this.indicatorHeight = 32.0,
    this.indicatorWidth = 64.0,
    this.floatingActionButton,
    this.useMaterial3Style = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bgColor = backgroundColor ?? AppTheme.cardColor;
    final selectedColor = selectedItemColor ?? AppTheme.accentColor;
    final unselectedColor = unselectedItemColor ?? AppTheme.textSecondaryColor;
    final indColor = indicatorColor ?? selectedColor.withOpacity(0.1);

    return Container(
      height: height,
      color: bgColor,
      child: Stack(
        children: [
          // Navigation items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == selectedIndex;
              final showLabel = showLabels && 
                (isSelected ? showSelectedLabels : showUnselectedLabels);
              
              return Expanded(
                child: _buildNavItem(
                  item: items[index],
                  isSelected: isSelected,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  indicatorColor: indColor,
                  iconSize: iconSize,
                  showLabel: showLabel,
                  indicatorHeight: indicatorHeight,
                  indicatorWidth: indicatorWidth,
                  useMaterial3Style: useMaterial3Style,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onItemSelected(index);
                  },
                ),
              );
            }),
          ),
          
          // Floating Action Button (if provided)
          if (floatingActionButton != null)
            Positioned(
              right: 16,
              bottom: height - 28,
              child: floatingActionButton!,
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required Material3NavBarItem item,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required Color indicatorColor,
    required double iconSize,
    required double indicatorHeight,
    required double indicatorWidth,
    required bool showLabel,
    required bool useMaterial3Style,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final icon = isSelected ? item.activeIcon ?? item.icon : item.icon;
    
    if (useMaterial3Style) {
      // Material 3 style with pill indicator
      return InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              
              // Animated indicator and icon
              Stack(
                alignment: Alignment.center,
                children: [
                  // Animated indicator background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? indicatorWidth : 0,
                    height: indicatorHeight,
                    decoration: BoxDecoration(
                      color: isSelected ? indicatorColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  
                  // Icon
                  Icon(
                    icon,
                    color: color,
                    size: iconSize,
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Label
              if (showLabel)
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Classic style with top indicator
      return InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 32 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              
              // Icon
              Icon(
                icon,
                color: color,
                size: iconSize,
              ),
              
              const SizedBox(height: 4),
              
              // Label
              if (showLabel)
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }
  }
}

class Material3NavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const Material3NavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
