import 'package:flutter/material.dart';
import 'package:taskswap/constants/gamification_constants.dart';

/// A progress indicator that pulses when progress is made
class PulsingProgressIndicator extends StatefulWidget {
  final double value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final bool animate;
  final bool showPercentage;
  final String? label;
  final TextStyle? labelStyle;

  const PulsingProgressIndicator({
    super.key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.height = 8.0,
    this.animate = true,
    this.showPercentage = false,
    this.label,
    this.labelStyle,
  });

  @override
  State<PulsingProgressIndicator> createState() => _PulsingProgressIndicatorState();
}

class _PulsingProgressIndicatorState extends State<PulsingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _animationController = AnimationController(
      vsync: this,
      duration: GamificationConstants.mediumAnimationDuration,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(PulsingProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > _previousValue && widget.animate) {
      _animationController.forward(from: 0.0);
    }
    _previousValue = widget.value;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerLow;
    final valueColor = widget.valueColor ?? Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: widget.labelStyle ?? Theme.of(context).textTheme.bodyMedium,
              ),
              if (widget.showPercentage)
                Text(
                  '${(widget.value * 100).toInt()}%',
                  style: widget.labelStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              height: widget.height * _pulseAnimation.value,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(widget.height),
              ),
              child: FractionallySizedBox(
                widthFactor: widget.value,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: valueColor,
                    borderRadius: BorderRadius.circular(widget.height),
                    boxShadow: [
                      if (_animationController.value > 0)
                        BoxShadow(
                          color: valueColor.withAlpha((128 * _animationController.value).toInt()),
                          blurRadius: 4 * _animationController.value,
                          spreadRadius: 1 * _animationController.value,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
