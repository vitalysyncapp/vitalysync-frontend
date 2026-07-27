import 'package:flutter/foundation.dart';

import '../preferences/app_preferences.dart';

/// Tracks whether the app should be "locked" behind a biometric/passcode gate.
///
/// Phase 1 (current): The service records lock state transitions and auto‐
/// unlocks because `local_auth` is not yet integrated. The UI scaffold
/// ([BiometricLockScreen]) is functional and ready for the real biometric
/// prompt in a follow‐up.
class BiometricLockService {
  BiometricLockService._();

  static final BiometricLockService instance = BiometricLockService._();

  /// `true` when the app is locked and should show the lock screen.
  final ValueNotifier<bool> isLocked = ValueNotifier<bool>(false);

  /// Called when the app lifecycle transitions to `resumed`. If the biometric
  /// lock preference is enabled, the app enters the locked state.
  void onAppResumed() {
    final prefs = AppPreferencesController.instance.notifier.value;
    if (!prefs.biometricLockEnabled) {
      return;
    }

    // Only lock if we were previously backgrounded (not on first launch).
    if (!_hasBeenBackgrounded) {
      return;
    }

    isLocked.value = true;
  }

  /// Called when the app lifecycle transitions to paused/hidden/inactive.
  void onAppBackgrounded() {
    final prefs = AppPreferencesController.instance.notifier.value;
    if (!prefs.biometricLockEnabled) {
      return;
    }

    _hasBeenBackgrounded = true;
  }

  /// Attempts to unlock the app. In Phase 1 this always succeeds.
  /// In a follow‐up, this will invoke `local_auth` to authenticate.
  Future<bool> unlock() async {
    // Phase 1: auto‐unlock.
    isLocked.value = false;
    return true;
  }

  bool _hasBeenBackgrounded = false;
}
