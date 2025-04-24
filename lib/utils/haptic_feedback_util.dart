import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A utility class for providing consistent haptic feedback throughout the app
class HapticFeedbackUtil {
  /// Provides light haptic feedback for small UI interactions
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error providing light haptic feedback: $e');
    }
  }
  
  /// Provides medium haptic feedback for more significant UI interactions
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error providing medium haptic feedback: $e');
    }
  }
  
  /// Provides heavy haptic feedback for major UI interactions
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error providing heavy haptic feedback: $e');
    }
  }
  
  /// Provides vibration feedback for selection events
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Error providing selection click feedback: $e');
    }
  }
  
  /// Provides vibration feedback for task completion
  static Future<void> taskCompleted() async {
    try {
      // Provide a sequence of haptic feedback for a more satisfying experience
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error providing task completed feedback: $e');
    }
  }
  
  /// Provides vibration feedback for error states
  static Future<void> error() async {
    try {
      // Provide a sequence of haptic feedback for error indication
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error providing error feedback: $e');
    }
  }
  
  /// Provides vibration feedback for success states
  static Future<void> success() async {
    try {
      // Provide a sequence of haptic feedback for success indication
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 70));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error providing success feedback: $e');
    }
  }
}
