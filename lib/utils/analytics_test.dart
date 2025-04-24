import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:taskswap/services/analytics_service.dart';

/// A utility class to test Firebase Analytics functionality
class AnalyticsTest {
  /// Test if Firebase Analytics is working properly
  static Future<bool> testAnalytics(BuildContext context) async {
    // Show initial message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testing analytics...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      // Try to log a simple test event with a timeout
      bool success = false;

      try {
        await AnalyticsService.instance.logEvent(
          name: 'analytics_test',
          parameters: {
            'timestamp': DateTime.now().toIso8601String(),
            'test_result': 'success',
          },
        );
        success = true;
      } catch (analyticsError) {
        debugPrint('Analytics test error: $analyticsError');
        success = false;
      }

      // Show appropriate message based on result
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analytics test event logged successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analytics test completed with warnings - check logs'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      return success;
    } catch (e) {
      // Show error message for unexpected errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analytics test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }
}
