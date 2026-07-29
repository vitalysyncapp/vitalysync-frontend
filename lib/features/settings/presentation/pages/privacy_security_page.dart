import 'package:flutter/material.dart';

import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/preferences/user_settings_api.dart';
import '../../../../shared/privacy/biometric_lock_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/validation_dialog.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  UserSessionSnapshot _session = UserSessionSnapshot.empty;
  bool _isLoadingSession = true;
  bool _isResendingVerification = false;
  bool _isSyncingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await UserSessionController.instance.load();
    if (!mounted) return;

    setState(() {
      _session = session;
      _isLoadingSession = false;
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResendingVerification) {
      return;
    }

    setState(() => _isResendingVerification = true);

    try {
      final message = await UserSessionController.instance
          .resendEmailVerification();
      if (!mounted) return;

      await ValidationDialog.show(
        context,
        title: 'Verification email sent',
        message: message,
        type: ValidationDialogType.success,
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');
      await ValidationDialog.show(
        context,
        title: 'Unable to send email',
        message: message,
        type: ValidationDialogType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isResendingVerification = false);
      }
    }
  }

  Future<void> _handleLeaderboardToggle(bool value) async {
    final preferences = AppPreferencesController.instance;

    // Update local preference immediately for responsiveness.
    await preferences.updateHideProfileFromLeaderboard(value);

    setState(() => _isSyncingLeaderboard = true);

    try {
      await UserSettingsApi.updateHideFromLeaderboard(value);
    } catch (error) {
      if (!mounted) return;

      // Revert local preference on failure.
      await preferences.updateHideProfileFromLeaderboard(!value);

      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update: $message'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncingLeaderboard = false);
      }
    }
  }

  Future<void> _handleBiometricToggle(bool value) async {
    final preferences = AppPreferencesController.instance;

    if (value) {
      // Enabling: check availability first.
      final availability =
          await BiometricLockService.instance.checkBiometricAvailability();

      if (!mounted) return;

      if (!availability.isAvailable) {
        _showBiometricUnavailableDialog(availability.reason);
        return;
      }

      // Verify biometric works with a one-time prompt.
      bool verified = false;
      try {
        verified = await BiometricLockService.instance.unlock();
      } on BiometricNotAvailableException {
        if (mounted) {
          _showBiometricUnavailableDialog(
              'This device does not have a secure lock screen set up.');
        }
        return;
      }
      
      if (!mounted) return;

      if (!verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric verification failed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      await preferences.updateBiometricLockEnabled(true);
    } else {
      await preferences.updateBiometricLockEnabled(false);
    }
  }

  void _showBiometricUnavailableDialog(String reason) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          backgroundColor: isDark
              ? const Color(0xFF1A2332)
              : Colors.white,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Biometric not available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason,
                style: TextStyle(
                  height: 1.45,
                  color: pageSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'To use biometric lock, set up a fingerprint, face '
                'unlock, or screen lock in your device settings:',
                style: TextStyle(
                  height: 1.45,
                  color: pageSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              _BiometricGuideStep(
                step: '1',
                text: 'Open your device Settings app',
              ),
              _BiometricGuideStep(
                step: '2',
                text: 'Go to Security & privacy (or Biometrics)',
              ),
              _BiometricGuideStep(
                step: '3',
                text: 'Set up fingerprint, face unlock, or PIN',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                BiometricLockService.instance.openSecuritySettings();
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesController.instance;

    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: preferences.notifier,
      builder: (context, prefs, _) {
        return Container(
          decoration: buildPageDecoration(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: pagePrimaryTextColor(context),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Privacy and security',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
            ),
            body: SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  pageBottomContentPadding(context),
                ),
                children: [
                  // ── Content privacy ──────────────────────────────
                  _SectionCard(
                    title: 'Content privacy',
                    children: [
                      _PrivacySwitchTile(
                        title: 'Hide sensitive content',
                        subtitle:
                            'Blurs wellness scores, analytics, and stat values across the app',
                        value: prefs.hideSensitiveContent,
                        onChanged: preferences.updateHideSensitiveContent,
                      ),
                      _divider(context),
                      _PrivacySwitchTile(
                        title: 'Do not show in leaderboard',
                        subtitle:
                            'Your name won\'t appear on any streak leaderboard',
                        value: prefs.hideProfileFromLeaderboard,
                        onChanged: _handleLeaderboardToggle,
                        isSyncing: _isSyncingLeaderboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Device security ──────────────────────────────
                  _SectionCard(
                    title: 'Device security',
                    children: [
                      _PrivacySwitchTile(
                        title: 'Biometric lock',
                        subtitle:
                            'Requires biometric or device passcode when the app is opened',
                        value: prefs.biometricLockEnabled,
                        onChanged: _handleBiometricToggle,
                      ),
                      _divider(context),
                      _DataRetentionTile(
                        currentDays: prefs.dataRetentionDays,
                        onChanged: preferences.updateDataRetentionDays,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Account security ─────────────────────────────
                  _SectionCard(
                    title: 'Account security',
                    children: [
                      _EmailVerificationTile(
                        email: _session.email,
                        isLoading: _isLoadingSession,
                        isVerified: _session.emailVerified,
                        isSending: _isResendingVerification,
                        onResend: _resendVerificationEmail,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── About ────────────────────────────────────────
                  _SectionCard(
                    title: 'About this section',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Text(
                          'Most privacy controls are stored on this device. '
                          'The leaderboard setting syncs to the server so '
                          'your profile is hidden for all users.',
                          style: TextStyle(
                            height: 1.45,
                            color: pageSecondaryTextColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: pageBorderColor(context),
      indent: 18,
      endIndent: 18,
    );
  }
}

class _BiometricGuideStep extends StatelessWidget {
  final String step;
  final String text;

  const _BiometricGuideStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: pageSecondaryTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _EmailVerificationTile extends StatelessWidget {
  final String? email;
  final bool isLoading;
  final bool isVerified;
  final bool isSending;
  final VoidCallback onResend;

  const _EmailVerificationTile({
    required this.email,
    required this.isLoading,
    required this.isVerified,
    required this.isSending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedEmail = email?.trim() ?? '';
    final statusText = isLoading
        ? 'Checking'
        : isVerified
        ? 'Verified'
        : 'Not verified';
    final statusColor = isVerified
        ? const Color(0xFF1EAD83)
        : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isVerified
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email verification',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  normalizedEmail.isEmpty
                      ? statusText
                      : '$statusText - $normalizedEmail',
                  style: TextStyle(
                    height: 1.4,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (!isLoading && !isVerified && normalizedEmail.isNotEmpty) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              key: const ValueKey('resend-email-verification-button'),
              onPressed: isSending ? null : onResend,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(isSending ? 'Sending' : 'Resend'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrivacySwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;
  final bool isSyncing;

  const _PrivacySwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.4,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DataRetentionTile extends StatelessWidget {
  final int currentDays;
  final Future<void> Function(int) onChanged;

  const _DataRetentionTile({
    required this.currentDays,
    required this.onChanged,
  });

  static const _options = <int, String>{
    0: 'Unlimited',
    30: '30 days',
    60: '60 days',
    90: '90 days',
  };

  @override
  Widget build(BuildContext context) {
    final label = _options[currentDays] ?? '$currentDays days';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local data retention',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How long offline cached logs are kept on this device',
                  style: TextStyle(
                    height: 1.4,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<int>(
            initialValue: currentDays,
            onSelected: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: pageBorderColor(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: pageSecondaryTextColor(context),
                  ),
                ],
              ),
            ),
            itemBuilder: (_) => _options.entries
                .map(
                  (entry) => PopupMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
