import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for performance optimizations and haptic feedback
class PerformanceUtils {
  /// Debounce function to prevent rapid firing of events
  static Function debounce(Function function, Duration duration) {
    DateTime? lastCall;
    return () {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) > duration) {
        lastCall = now;
        function();
      }
    };
  }

  /// Throttle function to limit the rate at which a function can fire
  static Function throttle(Function function, Duration duration) {
    bool isThrottled = false;
    return () {
      if (!isThrottled) {
        function();
        isThrottled = true;
        Future.delayed(duration, () {
          isThrottled = false;
        });
      }
    };
  }

  /// Provide light haptic feedback for minor interactions
  static void lightHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Provide medium haptic feedback for important actions
  static void mediumHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  /// Provide heavy haptic feedback for significant events
  static void heavyHapticFeedback() {
    HapticFeedback.heavyImpact();
  }

  /// Provide success haptic feedback
  static void successHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Provide error haptic feedback
  static void errorHapticFeedback() {
    HapticFeedback.vibrate();
  }

  /// Optimize image loading with proper error handling
  static Widget optimizedNetworkImage({
    required String? imageUrl,
    required double size,
    required Widget placeholder,
    required Widget errorWidget,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return errorWidget;
    }

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget;
      },
    );
  }

  /// Create a repaint boundary for complex widgets to improve performance
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Add a scroll physics configuration for better scrolling feel
  static ScrollPhysics get optimizedScrollPhysics {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
