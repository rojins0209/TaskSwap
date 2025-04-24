import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:taskswap/theme/app_theme.dart';

class CurvedNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<CurvedNavBarItem> items;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? indicatorColor;
  final double height;
  final double iconSize;
  final double elevation;
  final EdgeInsets margin;
  final bool showLabels;
  final bool enableAnimation;

  const CurvedNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.floatingActionButton,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.indicatorColor,
    this.height = 70.0,
    this.iconSize = 24.0,
    this.elevation = 8.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
    this.showLabels = true,
    this.enableAnimation = true,
  });

  @override
  State<CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<CurvedNavBar> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indicatorXAnimation;
  int _previousIndex = 0;
  final List<GlobalKey> _navItemKeys = [];

  // Animation for the FAB
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    _fabRotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
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
  void didUpdateWidget(CurvedNavBar oldWidget) {
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
    _fabController.dispose();
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
    final indicatorColor = widget.indicatorColor ?? selectedColor;

    // Calculate the width for the FAB space
    final hasFab = widget.floatingActionButton != null;
    final fabSpaceWidth = hasFab ? 80.0 : 0.0;

    // Calculate the width for each nav item
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - widget.margin.horizontal;
    final itemCount = widget.items.length;
    final itemWidth = availableWidth / itemCount;

    return Container(
      height: widget.height + widget.margin.vertical,
      padding: widget.margin,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Main navigation bar with curved shape
          CustomPaint(
            size: Size(screenWidth, widget.height),
            painter: _NavBarPainter(
              color: bgColor,
              elevation: widget.elevation,
              hasFab: hasFab,
            ),
          ),

          // Nav items
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: widget.height,
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
          ),

          // Floating indicator
          if (widget.enableAnimation)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  bottom: widget.showLabels ? 30 : 20,
                  left: _indicatorXAnimation.value - 20,
                  child: Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              },
            ),

          // Floating Action Button with animation
          if (hasFab)
            Positioned(
              bottom: widget.height - 25,
              child: MouseRegion(
                onEnter: (_) => _fabController.forward(),
                onExit: (_) => _fabController.reverse(),
                child: GestureDetector(
                  onTapDown: (_) => _fabController.forward(),
                  onTapUp: (_) => _fabController.reverse(),
                  onTapCancel: () => _fabController.reverse(),
                  child: AnimatedBuilder(
                    animation: _fabController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _fabScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _fabRotateAnimation.value,
                          child: widget.floatingActionButton,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
    required CurvedNavBarItem item,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the curved navigation bar
class _NavBarPainter extends CustomPainter {
  final Color color;
  final double elevation;
  final bool hasFab;

  _NavBarPainter({
    required this.color,
    required this.elevation,
    required this.hasFab,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation);

    final path = Path();

    if (hasFab) {
      // Start from the left bottom corner
      path.moveTo(0, 0);

      // Draw the left side
      path.lineTo(0, size.height);

      // Draw the bottom side with a curve for the FAB
      path.lineTo(size.width / 2 - 30, size.height);

      // Draw the curve for the FAB
      path.quadraticBezierTo(
        size.width / 2, size.height,
        size.width / 2, size.height - 25,
      );

      // Draw the right side of the curve
      path.quadraticBezierTo(
        size.width / 2, size.height,
        size.width / 2 + 30, size.height,
      );

      // Draw the rest of the bottom side
      path.lineTo(size.width, size.height);

      // Draw the right side
      path.lineTo(size.width, 0);

      // Close the path
      path.close();
    } else {
      // Simple rectangle if no FAB
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    // Draw shadow first
    canvas.drawPath(path, shadowPaint);

    // Then draw the actual navigation bar
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CurvedNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const CurvedNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
