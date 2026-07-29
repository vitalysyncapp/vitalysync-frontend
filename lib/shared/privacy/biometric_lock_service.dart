import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../preferences/app_preferences.dart';

class BiometricAvailability {
  final bool isAvailable;
  final String reason;

  const BiometricAvailability(this.isAvailable, this.reason);
}

class BiometricNotAvailableException implements Exception {
  const BiometricNotAvailableException();
}

/// Tracks whether the app should be "locked" behind a biometric/passcode gate.
///
/// This uses `local_auth` to authenticate the user on cold start.
class BiometricLockService {
  BiometricLockService._();

  static final BiometricLockService instance = BiometricLockService._();
  final LocalAuthentication _auth = LocalAuthentication();

  /// `true` when the app is locked and should show the lock screen.
  final ValueNotifier<bool> isLocked = ValueNotifier<bool>(false);

  /// Called on fresh app launch. If the user has the lock enabled, lock it.
  void lockOnColdStart() {
    final prefs = AppPreferencesController.instance.notifier.value;
    if (prefs.biometricLockEnabled) {
      isLocked.value = true;
      unlock();
    }
  }

  /// Checks if the device has biometric or device passcode credentials set up.
  Future<BiometricAvailability> checkBiometricAvailability() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();

      if (!isAvailable) {
        return const BiometricAvailability(
          false,
          'This device does not support biometric or passcode authentication.',
        );
      }

      final availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        // Technically they could still use a PIN, but usually local_auth
        // considers the device unsupported if nothing is set up. Let's just
        // rely on a test auth to see if it works.
      }

      return const BiometricAvailability(true, '');
    } on PlatformException catch (e) {
      return BiometricAvailability(false, e.message ?? 'Unknown error');
    }
  }

  /// Prompts the user to authenticate. Returns true on success.
  Future<bool> unlock() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to access VitalySync',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        isLocked.value = false;
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable || e.code == auth_error.passcodeNotSet || e.code == auth_error.notEnrolled) {
         throw const BiometricNotAvailableException();
      }
      return false;
    }
  }

  void openSecuritySettings() {
    // Open settings is not available out of the box in local_auth.
    // The dialog provides text instructions instead.
  }
}
