import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A utility class for providing consistent haptic feedback throughout the app
class HapticFeedbackUtil {
  /// Provides very light haptic feedback for small UI interactions
  static Future<void> lightImpact() async {
    try {
      // Use the lightest possible feedback
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing light haptic feedback: $e');
    }
  }

  /// Provides medium haptic feedback for more significant UI interactions
  /// (Reduced to selection click to decrease overall intensity)
  static Future<void> mediumImpact() async {
    try {
      // Use selection click instead of light impact for reduced intensity
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing medium haptic feedback: $e');
    }
  }

  /// Provides heavy haptic feedback for major UI interactions
  /// (Reduced to selection click to decrease overall intensity)
  static Future<void> heavyImpact() async {
    try {
      // Use selection click instead of medium impact for reduced intensity
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing heavy haptic feedback: $e');
    }
  }

  /// Provides vibration feedback for selection events
  static Future<void> selectionClick() async {
    try {
      // Use the lightest possible feedback
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing selection click feedback: $e');
    }
  }

  /// Provides vibration feedback for task completion
  static Future<void> taskCompleted() async {
    try {
      // Use selection click instead of light impact for reduced intensity
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing task completed feedback: $e');
    }
  }

  /// Provides vibration feedback for error states
  static Future<void> error() async {
    try {
      // Use selection click instead of light impact for reduced intensity
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing error feedback: $e');
    }
  }

  /// Provides vibration feedback for success states
  static Future<void> success() async {
    try {
      // Use selection click instead of light impact for reduced intensity
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing success feedback: $e');
    }
  }
}
