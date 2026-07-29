import 'package:flutter/material.dart';

import 'biometric_lock_service.dart';

/// Full-screen lock overlay shown when [BiometricLockService.isLocked] is
/// `true`. Displays the VitalySync logo and prompts for authentication.
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Auto-prompt on cold start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptAuth();
    });
  }

  Future<void> _promptAuth() async {
    if (_isAuthenticating) return;
    
    setState(() => _isAuthenticating = true);
    
    // The unlock method handles the local_auth prompt.
    // If it succeeds, the ValueNotifier updates and this screen unmounts.
    await BiometricLockService.instance.unlock();
    
    if (mounted) {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF08131D) : const Color(0xFFF0F8FF),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1B4D5C), Color(0xFF1EAD83)]
                        : const [Color(0xFFDDF8EE), Color(0xFFEAF5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, e, s) => Icon(
                    Icons.spa_rounded,
                    size: 48,
                    color: isDark
                        ? const Color(0xFF1EAD83)
                        : const Color(0xFF1F9D63),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'VitalySync is locked',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please authenticate to continue',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isAuthenticating ? null : _promptAuth,
                icon: _isAuthenticating 
                  ? const SizedBox(
                      width: 18, 
                      height: 18, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF1EAD83)
                      : const Color(0xFF1F9D63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
