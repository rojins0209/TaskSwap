import 'dart:io';
import 'package:flutter/foundation.dart';

/// A utility class for handling security provider installation and related warnings
/// This helps address the "Failed to load providerinstaller module" and
/// "Failed to report request stats" warnings
class SecurityProvider {
  // Note: A method channel could be used for a more comprehensive solution
  // that calls native Android code to update the security provider
  static bool _hasLogged = false;

  /// Initialize the security provider
  /// This is a no-op on platforms other than Android
  static Future<void> initialize() async {
    // Only needed on Android
    if (!Platform.isAndroid) {
      return;
    }

    try {
      // Log a message about these warnings (only once)
      if (!_hasLogged) {
        debugPrint('Note: "ProviderInstaller" and "Failed to report request stats" warnings can be safely ignored');
        debugPrint('These warnings are related to Google Play Services security provider updates');
        debugPrint('They do not affect app functionality, especially on newer Android versions');
        _hasLogged = true;
      }

      // For a more comprehensive solution in a production app, you could:
      // 1. Add a dependency on 'play_services_security' package
      // 2. Use native code via method channel to call ProviderInstaller.installIfNeeded()
      // 3. Handle security provider updates properly

      // However, for most modern apps targeting Android 7.0+, this is unnecessary
      // as the system's security provider is already up-to-date

    } catch (e) {
      debugPrint('Error initializing security provider: $e');
    }
  }

  /// Suppress security provider warnings in logs (for debugging purposes)
  /// This method doesn't actually do anything functional, but documents the issue
  static void suppressWarnings() {
    // This method exists purely for documentation purposes
    // The warnings:
    // - "Failed to load providerinstaller module"
    // - "Failed to report request stats: com.google.android.gms.common.security.ProviderInstallerImpl.reportRequestStats"
    //
    // These warnings are harmless and can be safely ignored, especially on:
    // - Emulators
    // - Devices with outdated Google Play Services
    // - Modern Android versions (7.0+) which have better built-in security providers
  }
}
