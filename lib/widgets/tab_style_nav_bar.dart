import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/theme/app_theme.dart';

class TabStyleNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<TabStyleNavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double height;
  final double iconSize;
  final bool showLabels;
  final EdgeInsets padding;
  final Widget? floatingActionButton;
  final bool showDivider;
  final double dividerThickness;
  final Color? dividerColor;

  const TabStyleNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.height = 60.0,
    this.iconSize = 26.0,
    this.showLabels = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    this.floatingActionButton,
    this.showDivider = true,
    this.dividerThickness = 0.5,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.cardColor;
    final selectedColor = selectedItemColor ?? AppTheme.accentColor;
    final unselectedColor = unselectedItemColor ?? AppTheme.textSecondaryColor;
    final divColor = dividerColor ?? Colors.grey.withOpacity(0.2);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top divider
        if (showDivider)
          Divider(
            height: dividerThickness,
            thickness: dividerThickness,
            color: divColor,
          ),
        
        // Main navigation bar
        Container(
          height: height,
          padding: padding,
          color: bgColor,
          child: Stack(
            children: [
              // Navigation items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final isSelected = index == selectedIndex;
                  
                  return Expanded(
                    child: _buildNavItem(
                      item: items[index],
                      isSelected: isSelected,
                      selectedColor: selectedColor,
                      unselectedColor: unselectedColor,
                      iconSize: iconSize,
                      showLabel: showLabels,
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
                  bottom: height / 2 - 28,
                  child: floatingActionButton!,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required TabStyleNavBarItem item,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required double iconSize,
    required bool showLabel,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final icon = isSelected ? item.activeIcon ?? item.icon : item.icon;
    
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Selected indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 24 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 6),
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
          
          // Label
          if (showLabel) ...[
            const SizedBox(height: 4),
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
          ],
        ],
      ),
    );
  }
}

class TabStyleNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const TabStyleNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
