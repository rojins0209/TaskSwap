import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:taskswap/services/user_service.dart';
import 'package:taskswap/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the user document in Firestore
      if (userCredential.user != null) {
        await _userService.createUser(userCredential.user!.uid, email);

        // Try to save FCM token, but don't let it fail the signup process
        try {
          await _notificationService.saveFCMToken();
        } catch (fcmError) {
          // Just log the error but don't let it affect the signup process
          debugPrint('Non-critical error saving FCM token during signup: $fcmError');
        }
      }

      return userCredential;
    } catch (e) {
      // Rethrow the original error for proper handling in the UI
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password, {bool rememberMe = false}) async {
    try {
      // First authenticate the user
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save email if remember me is checked
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('remembered_email', email);
      }

      // Try to save FCM token, but don't let it fail the login process
      try {
        await _notificationService.saveFCMToken();
      } catch (fcmError) {
        // Just log the error but don't let it affect the login process
        debugPrint('Non-critical error saving FCM token: $fcmError');
      }

      return userCredential;
    } catch (e) {
      // Rethrow the original error for proper handling in the UI
      rethrow;
    }
  }

  // Get remembered email
  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('remembered_email');
  }

  // Clear remembered email
  Future<void> clearRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remembered_email');
  }

  // Sign out
  Future<void> signOut() async {
    // Remove FCM token before signing out
    await _notificationService.removeFCMToken();

    // Sign out from Firebase Auth
    return await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }
}