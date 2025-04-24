import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PillNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<PillNavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? pillColor;
  final double height;
  final double iconSize;
  final EdgeInsets margin;
  final double borderRadius;
  final double elevation;
  final Widget? floatingActionButton;

  const PillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.pillColor,
    this.height = 64.0,
    this.iconSize = 24.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.borderRadius = 30.0,
    this.elevation = 4.0,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final selectedColor = selectedItemColor ?? colorScheme.primary;
    final unselectedColor = unselectedItemColor ?? colorScheme.onSurfaceVariant;
    final pillBgColor = pillColor ?? selectedColor.withAlpha(25);

    return Container(
      height: height + margin.vertical,
      padding: margin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main navigation bar
          Container(
            height: height,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withAlpha(13),
                  blurRadius: elevation,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = index == selectedIndex;

                return Expanded(
                  child: _buildNavItem(
                    item: items[index],
                    isSelected: isSelected,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    pillColor: pillBgColor,
                    iconSize: iconSize,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onItemSelected(index);
                    },
                  ),
                );
              }),
            ),
          ),

          // Floating Action Button (if provided)
          if (floatingActionButton != null)
            Positioned(
              right: 16,
              bottom: height + 16, // Position above the nav bar
              child: floatingActionButton!,
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required PillNavBarItem item,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required Color pillColor,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final icon = isSelected ? item.activeIcon ?? item.icon : item.icon;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with pill background when selected
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 12 : 0,
                vertical: isSelected ? 6 : 0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? pillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
            ),

            // Label (only show if selected)
            if (isSelected) ...[
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
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

class PillNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const PillNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
