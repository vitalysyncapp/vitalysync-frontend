import 'package:flutter/material.dart';

import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
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
                        title: 'Pause wellness insights',
                        subtitle:
                            'Suppresses AI nudges and adaptive insight cards',
                        value: prefs.pauseWellnessInsights,
                        onChanged: preferences.updatePauseWellnessInsights,
                      ),
                      _divider(context),
                      _PrivacySwitchTile(
                        title: 'Hide profile from leaderboard',
                        subtitle:
                            'Removes your entry from the streak leaderboard display',
                        value: prefs.hideProfileFromLeaderboard,
                        onChanged:
                            preferences.updateHideProfileFromLeaderboard,
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
                            'Shows a lock screen when the app is reopened. Biometric prompt will be added in a future update.',
                        value: prefs.biometricLockEnabled,
                        onChanged: preferences.updateBiometricLockEnabled,
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
                          'Privacy controls are stored on this device only and '
                          'do not sync to the server. They help you manage '
                          'what is visible on-screen and in the app switcher.',
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

  const _PrivacySwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
