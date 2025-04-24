import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/theme/app_theme.dart';

class ModernNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? indicatorColor;
  final double height;
  final double iconSize;
  final TextStyle? labelStyle;
  final bool showLabels;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  final bool useFloatingIndicator;

  const ModernNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.indicatorColor,
    this.height = 72.0,
    this.iconSize = 24.0,
    this.labelStyle,
    this.showLabels = true,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    this.useFloatingIndicator = true,
  });

  @override
  State<ModernNavBar> createState() => _ModernNavBarState();
}

class _ModernNavBarState extends State<ModernNavBar> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(ModernNavBar oldWidget) {
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

    final bgColor = widget.backgroundColor ?? colorScheme.surface;
    final selectedColor = widget.selectedItemColor ?? colorScheme.primary;
    final unselectedColor = widget.unselectedItemColor ?? colorScheme.onSurfaceVariant;
    final indicatorColor = widget.indicatorColor ?? colorScheme.primary;
    final defaultLabelStyle = widget.labelStyle ?? AppTheme.labelSmall;

    return Container(
      height: widget.height,
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
      child: Stack(
        children: [
          // Nav items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              final isSelected = index == widget.selectedIndex;
              final showLabel = widget.showLabels &&
                (isSelected ? widget.showSelectedLabels : widget.showUnselectedLabels);

              return _buildNavItem(
                context: context,
                key: _navItemKeys[index],
                item: widget.items[index],
                isSelected: isSelected,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                iconSize: widget.iconSize,
                labelStyle: defaultLabelStyle,
                showLabel: showLabel,
                onTap: () => widget.onItemSelected(index),
              );
            }),
          ),

          // Floating indicator
          if (widget.useFloatingIndicator)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  top: 8,
                  left: _indicatorXAnimation.value - 24,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: indicatorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
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

    return Expanded(
      key: key,
      child: InkWell(
        onTap: onTap,
        splashColor: selectedColor.withOpacity(0.1),
        highlightColor: selectedColor.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.useFloatingIndicator
                      ? Colors.transparent
                      : (isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent),
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
                // Text with animation
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
