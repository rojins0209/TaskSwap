import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Priority levels for scheduled tasks
enum TaskPriority {
  /// Lowest priority, for background tasks
  idle,

  /// Medium priority, for animation-related tasks
  animation,

  /// Highest priority, for touch-related tasks
  touch,
}

/// A utility class for performance optimizations
class PerformanceUtil {
  /// Debounces a function call to prevent excessive executions
  ///
  /// [callback] - The function to debounce
  /// [duration] - The duration to wait before executing the function
  /// Returns a function that can be called repeatedly, but will only execute
  /// the callback after the specified duration has passed since the last call
  static Function debounce(Function callback, {Duration duration = const Duration(milliseconds: 300)}) {
    Timer? timer;

    return () {
      if (timer != null) {
        timer!.cancel();
      }

      timer = Timer(duration, () {
        callback();
      });
    };
  }

  /// Throttles a function call to limit the rate of execution
  ///
  /// [callback] - The function to throttle
  /// [duration] - The minimum duration between executions
  /// Returns a function that can be called repeatedly, but will only execute
  /// the callback at most once per specified duration
  static Function throttle(Function callback, {Duration duration = const Duration(milliseconds: 300)}) {
    DateTime? lastExecution;

    return () {
      final now = DateTime.now();
      if (lastExecution == null || now.difference(lastExecution!) > duration) {
        callback();
        lastExecution = now;
      }
    };
  }

  /// Schedules a task to run during an idle period
  ///
  /// [task] - The task to run
  /// [priority] - The priority of the task
  static void scheduleTask(VoidCallback task, {TaskPriority priority = TaskPriority.idle}) {
    Priority schedulerPriority = Priority.idle; // Default value

    switch (priority) {
      case TaskPriority.idle:
        schedulerPriority = Priority.idle;
        break;
      case TaskPriority.animation:
        schedulerPriority = Priority.animation;
        break;
      case TaskPriority.touch:
        schedulerPriority = Priority.touch;
        break;
    }

    SchedulerBinding.instance.scheduleTask(task, schedulerPriority);
  }

  /// Runs a task in a separate isolate for CPU-intensive operations
  ///
  /// [computation] - The computation to run
  /// [message] - The input message for the computation
  static Future<R> computeAsync<Q, R>(ComputeCallback<Q, R> computation, Q message) {
    return compute(computation, message);
  }

  /// Measures the execution time of a function
  ///
  /// [name] - A name to identify the measurement
  /// [function] - The function to measure
  /// Returns the result of the function
  static Future<T> measureExecutionTime<T>(String name, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    final result = await function();
    stopwatch.stop();

    debugPrint('$name executed in ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }

  /// Measures the execution time of a synchronous function
  ///
  /// [name] - A name to identify the measurement
  /// [function] - The function to measure
  /// Returns the result of the function
  static T measureExecutionTimeSync<T>(String name, T Function() function) {
    final stopwatch = Stopwatch()..start();
    final result = function();
    stopwatch.stop();

    debugPrint('$name executed in ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }
}
