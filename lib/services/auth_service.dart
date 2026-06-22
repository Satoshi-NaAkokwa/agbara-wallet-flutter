import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Biometric + PIN authentication for sensitive operations
/// Handles all platforms gracefully with proper error codes
class AuthService {
  static final _auth = LocalAuthentication();

  /// Check if device supports biometric auth
  static Future<bool> canAuthenticate() async {
    try {
      final available = await _auth.canCheckBiometrics;
      final enrolled = await _auth.getAvailableBiometrics();
      return available && enrolled.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> availableMethods() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Trigger biometric authentication
  /// Returns true on success, false on failure/cancel
  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Auth error: ${e.code} - ${e.message}');
      return false;
    }
  }

  /// Stop any in-progress authentication
  static Future<bool> stopAuthentication() async {
    try {
      return await _auth.stopAuthentication();
    } on PlatformException catch (_) {
      return false;
    }
  }
}
