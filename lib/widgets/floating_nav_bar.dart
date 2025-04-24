import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/theme/app_theme.dart';

class FloatingNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<FloatingNavBarItem> items;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double height;
  final double iconSize;
  final double elevation;
  final double borderRadius;
  final EdgeInsets margin;
  final bool showLabels;
  final bool enableAnimation;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.floatingActionButton,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.height = 64.0,
    this.iconSize = 24.0,
    this.elevation = 8.0,
    this.borderRadius = 24.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.showLabels = true,
    this.enableAnimation = true,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indicatorXAnimation;
  int _previousIndex = 0;
  final List<GlobalKey> _navItemKeys = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _previousIndex = widget.selectedIndex;

    // Initialize keys for each nav item
    _navItemKeys.clear();
    for (int i = 0; i < widget.items.length; i++) {
      _navItemKeys.add(GlobalKey());
    }

    // Initialize animation with a default value
    _indicatorXAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // We'll update the animation values after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorAnimation(widget.selectedIndex, animate: false);
    });
  }

  @override
  void didUpdateWidget(FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the selected index changed, update the animation
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _updateIndicatorAnimation(widget.selectedIndex);
    }

    // If the number of items changed, update the keys
    if (oldWidget.items.length != widget.items.length) {
      _navItemKeys.clear();
      for (int i = 0; i < widget.items.length; i++) {
        _navItemKeys.add(GlobalKey());
      }

      // Update the animation after the frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateIndicatorAnimation(widget.selectedIndex, animate: false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateIndicatorAnimation(int newIndex, {bool animate = true}) {
    if (!widget.enableAnimation) return;

    // Get the positions of the previous and new nav items
    final previousKey = _navItemKeys[_previousIndex];
    final newKey = _navItemKeys[newIndex];

    // Get the render boxes for the nav items
    final RenderBox? previousBox = previousKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? newBox = newKey.currentContext?.findRenderObject() as RenderBox?;

    if (previousBox != null && newBox != null) {
      // Get the positions of the nav items
      final previousPos = previousBox.localToGlobal(Offset.zero).dx + previousBox.size.width / 2;
      final newPos = newBox.localToGlobal(Offset.zero).dx + newBox.size.width / 2;

      // Update the animation
      _indicatorXAnimation = Tween<double>(
        begin: previousPos,
        end: newPos,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );

      // Reset and run the animation
      if (animate) {
        _controller.reset();
        _controller.forward();
      } else {
        _controller.value = 1.0;
      }

      // Update the previous index
      _previousIndex = newIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = widget.backgroundColor ?? AppTheme.cardColor;
    final selectedColor = widget.selectedItemColor ?? AppTheme.accentColor;
    final unselectedColor = widget.unselectedItemColor ?? AppTheme.textSecondaryColor;

    // Calculate the width for the FAB space
    final hasFab = widget.floatingActionButton != null;
    final fabSpaceWidth = hasFab ? 80.0 : 0.0;

    // Calculate the width for each nav item
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - widget.margin.horizontal - fabSpaceWidth;
    final itemCount = widget.items.length;
    final itemWidth = availableWidth / itemCount;

    return Container(
      height: widget.height + widget.margin.vertical,
      padding: widget.margin,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main navigation bar
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: widget.elevation,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.items.length, (index) {
                final isSelected = index == widget.selectedIndex;

                // If we have a FAB and this is the middle item, add a spacer
                if (hasFab && index == widget.items.length ~/ 2) {
                  return SizedBox(width: fabSpaceWidth);
                }

                return SizedBox(
                  width: itemWidth,
                  child: _buildNavItem(
                    key: _navItemKeys[index],
                    item: widget.items[index],
                    isSelected: isSelected,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    iconSize: widget.iconSize,
                    showLabel: widget.showLabels,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onItemSelected(index);
                    },
                  ),
                );
              }),
            ),
          ),

          // Floating indicator
          if (widget.enableAnimation)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  top: 4,
                  left: _indicatorXAnimation.value - 24,
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),

          // Floating Action Button
          if (hasFab)
            Positioned(
              bottom: widget.height / 2,
              child: widget.floatingActionButton!,
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
    required FloatingNavBarItem item,
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
      key: key,
      onTap: onTap,
      customBorder: const StadiumBorder(),
      splashColor: selectedColor.withOpacity(0.1),
      highlightColor: selectedColor.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animation
            Icon(
              icon,
              color: color,
              size: iconSize,
            )
            .animate(target: isSelected ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
              duration: const Duration(milliseconds: 200),
            ),

            if (showLabel) ...[
              const SizedBox(height: 4),
              // Text with animation
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
              .animate(target: isSelected ? 1 : 0)
              .fadeIn(duration: const Duration(milliseconds: 200)),
            ],
          ],
        ),
      ),
    );
  }
}

class FloatingNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const FloatingNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
