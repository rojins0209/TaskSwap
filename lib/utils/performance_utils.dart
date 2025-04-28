import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Utility class for performance optimizations and haptic feedback
class PerformanceUtils {
  // Singleton instance
  static final PerformanceUtils _instance = PerformanceUtils._internal();
  factory PerformanceUtils() => _instance;
  PerformanceUtils._internal();

  // Get the singleton instance
  static PerformanceUtils get instance => _instance;

  // Map to store debounce timers
  final Map<String, Timer> _debounceTimers = {};

  // Map to store throttle timestamps
  final Map<String, DateTime> _throttleTimestamps = {};

  // Map to store memoized function results
  final Map<String, dynamic> _memoizedResults = {};

  // Flag to track if we're in a low-performance mode
  bool _isLowPerformanceMode = false;
  bool get isLowPerformanceMode => _isLowPerformanceMode;

  // Initialize performance monitoring
  void init() {
    // Check device capabilities to determine if we should use low-performance mode
    _checkDeviceCapabilities();

    // Listen for frame timing to detect jank
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  // Check device capabilities
  void _checkDeviceCapabilities() {
    // This is a simple heuristic - in a real app, you'd want to do more sophisticated detection
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final refreshRate = SchedulerBinding.instance.currentSystemFrameTimeStamp;

    // If the device has a low pixel ratio or refresh rate, enable low-performance mode
    if (devicePixelRatio < 2.0 || refreshRate == null) {
      _isLowPerformanceMode = true;
      debugPrint('Low-performance mode enabled');
    }
  }

  // Monitor frame timings to detect jank
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      // If a frame takes more than 16ms (60fps), it's considered jank
      final totalFrameTime = timing.totalSpan.inMicroseconds / 1000;

      if (totalFrameTime > 16.0) {
        // If we detect jank, we might want to reduce animations or other expensive operations
        if (!_isLowPerformanceMode && totalFrameTime > 32.0) {
          _isLowPerformanceMode = true;
          debugPrint('Low-performance mode enabled due to jank detection');
        }
      }
    }
  }

  /// Debounce a function call with an identifier
  /// This will delay the execution of [callback] until [duration] has passed
  /// If the function is called again before [duration] has passed, the timer will be reset
  void debounce(String id, Duration duration, VoidCallback callback) {
    if (_debounceTimers.containsKey(id)) {
      _debounceTimers[id]?.cancel();
    }

    _debounceTimers[id] = Timer(duration, () {
      callback();
      _debounceTimers.remove(id);
    });
  }

  /// Legacy debounce function (for backward compatibility)
  static Function debounceFunction(Function function, Duration duration) {
    DateTime? lastCall;
    return () {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) > duration) {
        lastCall = now;
        function();
      }
    };
  }

  /// Throttle a function call with an identifier
  /// This will ensure that [callback] is not called more than once in [duration]
  bool throttle(String id, Duration duration, VoidCallback callback) {
    final now = DateTime.now();

    if (_throttleTimestamps.containsKey(id)) {
      final lastRun = _throttleTimestamps[id]!;
      final elapsed = now.difference(lastRun);

      if (elapsed < duration) {
        // Not enough time has passed, don't run the callback
        return false;
      }
    }

    // Update the timestamp and run the callback
    _throttleTimestamps[id] = now;
    callback();
    return true;
  }

  /// Legacy throttle function (for backward compatibility)
  static Function throttleFunction(Function function, Duration duration) {
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

  /// Memoize a function result
  /// This will cache the result of [computation] for [key] and return it on subsequent calls
  /// The cache will be invalidated after [duration] has passed
  Future<T> memoize<T>(String key, Future<T> Function() computation, {Duration? duration}) async {
    // Check if we have a cached result
    if (_memoizedResults.containsKey(key)) {
      final cachedResult = _memoizedResults[key];

      if (cachedResult is _MemoizedResult<T>) {
        // Check if the cache is still valid
        if (duration == null || DateTime.now().difference(cachedResult.timestamp) < duration) {
          return cachedResult.value;
        }
      }
    }

    // Compute the result
    final result = await computation();

    // Cache the result
    _memoizedResults[key] = _MemoizedResult<T>(
      value: result,
      timestamp: DateTime.now(),
    );

    return result;
  }

  /// Clear all memoized results
  void clearMemoizedResults() {
    _memoizedResults.clear();
  }

  /// Clear a specific memoized result
  void clearMemoizedResult(String key) {
    _memoizedResults.remove(key);
  }

  /// Optimize an image URL for the current device
  String optimizeImageUrl(String url, {int? width, int? height, int quality = 80}) {
    // This is a placeholder implementation
    // In a real app, you'd want to use a CDN or image service that supports dynamic resizing

    // If the URL is already optimized, return it as is
    if (url.contains('w=') || url.contains('h=') || url.contains('q=')) {
      return url;
    }

    // If the URL doesn't contain a query string, add one
    final separator = url.contains('?') ? '&' : '?';

    // Build the query parameters
    final params = <String>[];

    if (width != null) {
      params.add('w=$width');
    }

    if (height != null) {
      params.add('h=$height');
    }

    params.add('q=$quality');

    // Return the optimized URL
    return '$url$separator${params.join('&')}';
  }

  /// Provide light haptic feedback for minor interactions
  static void lightHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Provide medium haptic feedback for important actions
  /// (Reduced to selection click to decrease overall intensity)
  static void mediumHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Provide heavy haptic feedback for significant events
  /// (Reduced to selection click to decrease overall intensity)
  static void heavyHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Provide success haptic feedback
  static void successHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Provide error haptic feedback
  /// (Changed to selection click to decrease intensity)
  static void errorHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Optimize image loading with proper error handling and caching
  static Widget optimizedNetworkImage({
    required String? imageUrl,
    required double size,
    required Widget placeholder,
    required Widget errorWidget,
    BoxFit fit = BoxFit.cover,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return errorWidget;
    }

    // Calculate cache dimensions based on device pixel ratio
    final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final effectiveCacheWidth = cacheWidth ?? (size * pixelRatio).round();
    final effectiveCacheHeight = cacheHeight ?? (size * pixelRatio).round();

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      cacheWidth: effectiveCacheWidth,
      cacheHeight: effectiveCacheHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $error');
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

  /// Dispose resources
  void dispose() {
    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    // Clear all throttle timestamps
    _throttleTimestamps.clear();

    // Clear all memoized results
    _memoizedResults.clear();
  }
}

/// Internal class to represent a memoized result
class _MemoizedResult<T> {
  final T value;
  final DateTime timestamp;

  _MemoizedResult({
    required this.value,
    required this.timestamp,
  });
}
