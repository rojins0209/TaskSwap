import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskswap/theme/app_theme.dart';

class ElegantNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<ElegantNavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? indicatorColor;
  final double height;
  final double iconSize;
  final bool showLabels;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  final EdgeInsets padding;
  final double indicatorHeight;
  final double indicatorWidth;

  const ElegantNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.indicatorColor,
    this.height = 60.0,
    this.iconSize = 24.0,
    this.showLabels = true,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
    this.indicatorHeight = 3.0,
    this.indicatorWidth = 32.0,
  });

  @override
  State<ElegantNavBar> createState() => _ElegantNavBarState();
}

class _ElegantNavBarState extends State<ElegantNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<GlobalKey> _navItemKeys = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Initialize keys for each nav item
    _navItemKeys.clear();
    for (int i = 0; i < widget.items.length; i++) {
      _navItemKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(ElegantNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the number of items changed, update the keys
    if (oldWidget.items.length != widget.items.length) {
      _navItemKeys.clear();
      for (int i = 0; i < widget.items.length; i++) {
        _navItemKeys.add(GlobalKey());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bgColor = widget.backgroundColor ?? AppTheme.cardColor;
    final selectedColor = widget.selectedItemColor ?? AppTheme.accentColor;
    final unselectedColor = widget.unselectedItemColor ?? AppTheme.textSecondaryColor;
    final indicatorColor = widget.indicatorColor ?? selectedColor;

    return Container(
      height: widget.height + widget.padding.vertical,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: widget.padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(widget.items.length, (index) {
            final isSelected = index == widget.selectedIndex;
            final showLabel = widget.showLabels && 
              (isSelected ? widget.showSelectedLabels : widget.showUnselectedLabels);
            
            return _buildNavItem(
              key: _navItemKeys[index],
              item: widget.items[index],
              isSelected: isSelected,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              indicatorColor: indicatorColor,
              iconSize: widget.iconSize,
              showLabel: showLabel,
              indicatorHeight: widget.indicatorHeight,
              indicatorWidth: widget.indicatorWidth,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onItemSelected(index);
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
    required ElegantNavBarItem item,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required Color indicatorColor,
    required double iconSize,
    required double indicatorHeight,
    required double indicatorWidth,
    required bool showLabel,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    final icon = isSelected ? item.activeIcon ?? item.icon : item.icon;

    return Expanded(
      key: key,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            
            const SizedBox(height: 4),
            
            // Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? indicatorWidth : 0,
              height: indicatorHeight,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(indicatorHeight / 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ElegantNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const ElegantNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
