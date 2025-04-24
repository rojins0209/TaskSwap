import 'package:flutter/material.dart';

class AuthButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) {
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (!widget.isLoading) {
          _controller.reverse();
        }
      },
      onTapCancel: () {
        if (!widget.isLoading) {
          _controller.reverse();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isPrimary ? colorScheme.primary : Colors.transparent,
              foregroundColor: widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary,
              disabledBackgroundColor: widget.isPrimary
                  ? isDark ? Colors.grey.shade800 : Colors.grey.shade300
                  : Colors.transparent,
              disabledForegroundColor: widget.isPrimary
                  ? isDark ? Colors.grey.shade400 : Colors.grey.shade700
                  : isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: widget.isPrimary
                    ? BorderSide.none
                    : BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.text,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: widget.isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
