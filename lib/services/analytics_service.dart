import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  late final FirebaseAnalytics _analytics;

  // Private constructor
  AnalyticsService._internal() {
    _analytics = FirebaseAnalytics.instance;
  }

  // Initialize analytics
  Future<void> init() async {
    // Analytics disabled due to platform issues
    debugPrint('Analytics initialization skipped');
    return;
  }

  // Get the analytics instance
  FirebaseAnalytics get analytics => _analytics;

  // Get the observer for navigation
  FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // Log app open event
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('Error logging app open: $e');
    }
  }

  // Log login event
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }

  // Log sign up event
  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method ?? 'email');
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }

  // Log task creation
  Future<void> logTaskCreated({
    required String taskId,
    required String taskTitle,
    required bool isChallenge,
    String? category,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'task_created',
        parameters: {
          'task_id': taskId,
          'task_title': taskTitle,
          'is_challenge': isChallenge,
          'category': category,
        },
      );
    } catch (e) {
      debugPrint('Error logging task creation: $e');
    }
  }

  // Log task completion
  Future<void> logTaskCompleted({
    required String taskId,
    required String taskTitle,
    required bool isChallenge,
    String? category,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'task_completed',
        parameters: {
          'task_id': taskId,
          'task_title': taskTitle,
          'is_challenge': isChallenge,
          'category': category,
        },
      );
    } catch (e) {
      debugPrint('Error logging task completion: $e');
    }
  }

  // Log challenge sent
  Future<void> logChallengeSent({
    required String challengeId,
    required String toUserId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_sent',
        parameters: {
          'challenge_id': challengeId,
          'to_user_id': toUserId,
        },
      );
    } catch (e) {
      debugPrint('Error logging challenge sent: $e');
    }
  }

  // Log challenge accepted
  Future<void> logChallengeAccepted({
    required String challengeId,
    required String fromUserId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'challenge_accepted',
        parameters: {
          'challenge_id': challengeId,
          'from_user_id': fromUserId,
        },
      );
    } catch (e) {
      debugPrint('Error logging challenge accepted: $e');
    }
  }

  // Log aura points given
  Future<void> logAuraPointsGiven({
    required String toUserId,
    required int points,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'aura_points_given',
        parameters: {
          'to_user_id': toUserId,
          'points': points,
        },
      );
    } catch (e) {
      debugPrint('Error logging aura points given: $e');
    }
  }

  // Log friend request sent
  Future<void> logFriendRequestSent({
    required String toUserId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'friend_request_sent',
        parameters: {
          'to_user_id': toUserId,
        },
      );
    } catch (e) {
      debugPrint('Error logging friend request sent: $e');
    }
  }

  // Log friend request accepted
  Future<void> logFriendRequestAccepted({
    required String fromUserId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'friend_request_accepted',
        parameters: {
          'from_user_id': fromUserId,
        },
      );
    } catch (e) {
      debugPrint('Error logging friend request accepted: $e');
    }
  }

  // Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  // Log user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  // Log user ID
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  // Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    // Analytics disabled due to platform issues
    debugPrint('Analytics disabled: Would have logged event "$name"');
    return;
  }
}
