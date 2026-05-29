import 'package:flutter/material.dart';

import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import 'app_preferences_page.dart';
import 'assistant_settings.dart';
import 'about_page.dart';
import 'clear_account_data_page.dart';
import 'delete_account_page.dart';
import 'help_support_page.dart';
import 'location_settings_page.dart';
import 'notification_settings_page.dart';
import 'privacy_security_page.dart';
import 'terms_privacy_page.dart';
import 'version_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoadingReminderSummary = true;
  String _notificationSubtitle = 'Loading your saved reminder preferences...';
  UserSessionSnapshot _session = UserSessionSnapshot.empty;

  @override
  void initState() {
    super.initState();
    _loadReminderSummary();
  }

  Future<void> _loadReminderSummary() async {
    final session = await UserSessionController.instance.load();

    if (!mounted) {
      return;
    }

    if (session.userId == null) {
      final prefs = AppPreferencesController.instance.notifier.value;
      setState(() {
        _session = session;
        _notificationSubtitle = _buildLocalNotificationSummary(prefs);
        _isLoadingReminderSummary = false;
      });
      return;
    }

    try {
      final summary = await OnboardingApi.fetchSummary(session.userId!);
      final preferences = Map<String, dynamic>.from(
        summary['preferences'] as Map? ?? {},
      );

      final dailyReminder = preferences['prefers_daily_reminder'] == true;
      final hydrationReminder =
          preferences['prefers_hydration_reminder'] == true;
      final sleepReminder = preferences['prefers_sleep_reminder'] == true;
      final mealReminder =
          AppPreferencesController.instance.notifier.value.mealReminderEnabled;
      final reminderTime = (preferences['reminder_time'] ?? '')
          .toString()
          .trim();

      await AppPreferencesController.instance.syncNotificationPreferences(
        notificationsEnabled: dailyReminder,
        bedtimeReminderEnabled: sleepReminder,
        hydrationReminderEnabled: hydrationReminder,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _session = session;
        _notificationSubtitle = _buildAccountNotificationSummary(
          dailyReminder: dailyReminder,
          hydrationReminder: hydrationReminder,
          mealReminder: mealReminder,
          sleepReminder: sleepReminder,
          reminderTime: reminderTime,
        );
        _isLoadingReminderSummary = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      final prefs = AppPreferencesController.instance.notifier.value;
      setState(() {
        _session = session;
        _notificationSubtitle = _buildLocalNotificationSummary(prefs);
        _isLoadingReminderSummary = false;
      });
    }
  }

  String _buildLocalNotificationSummary(AppPreferencesState prefs) {
    if (!prefs.notificationsEnabled) {
      return 'Reminders are currently turned off on this device';
    }

    final enabled = <String>[
      if (prefs.bedtimeReminderEnabled) 'sleep',
      if (prefs.hydrationReminderEnabled) 'hydration',
      if (prefs.mealReminderEnabled) 'meal',
    ];

    if (enabled.isEmpty) {
      return 'Notifications are enabled with no specific reminder types selected';
    }

    return '${enabled.join(' and ')} reminders are enabled on this device';
  }

  String _buildAccountNotificationSummary({
    required bool dailyReminder,
    required bool hydrationReminder,
    required bool mealReminder,
    required bool sleepReminder,
    required String reminderTime,
  }) {
    final enabled = <String>[
      if (dailyReminder) 'daily',
      if (hydrationReminder) 'hydration',
      if (mealReminder) 'meal',
      if (sleepReminder) 'sleep',
    ];

    if (enabled.isEmpty) {
      return 'Account reminders are currently turned off';
    }

    final joined = enabled.join(', ');
    final timeSuffix = reminderTime.isEmpty ? '' : ' around $reminderTime';
    return '${joined[0].toUpperCase()}${joined.substring(1)} reminders are enabled$timeSuffix';
  }

  String get _accountActionSubtitle {
    if (!_session.isLoggedIn) {
      return 'Sign in to manage account actions';
    }

    return 'Password required before continuing';
  }

  Future<void> _openProtectedAccountPage({
    required String actionTitle,
    required Widget Function(String verifiedPassword) builder,
  }) async {
    final session = await UserSessionController.instance.load();

    if (!mounted) {
      return;
    }

    if (!session.isLoggedIn || session.email?.trim().isEmpty != false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to manage account settings.'),
        ),
      );
      return;
    }

    final verifiedPassword = await _promptForPasswordVerification(
      actionTitle: actionTitle,
      email: session.email!.trim(),
    );

    if (!mounted || verifiedPassword == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => builder(verifiedPassword)),
    );
  }

  Future<String?> _promptForPasswordVerification({
    required String actionTitle,
    required String email,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _PasswordVerificationDialog(actionTitle: actionTitle, email: email),
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
                "Settings",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              centerTitle: false,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  pageBottomContentPadding(context),
                ),
                child: Column(
                  children: [
                    _buildHeaderCard(context: context, prefs: prefs),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: "Floating Assistant",
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.bubble_chart_rounded,
                          iconBg: const Color(0xFFE5F7F0),
                          iconColor: const Color(0xFF1F9D63),
                          title: "Assistant",
                          subtitle: "Manage outside-app assistant access",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssistantSettings(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: "App Settings",
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.notifications_none_rounded,
                          iconBg: const Color(0xFFFFF3CD),
                          iconColor: const Color(0xFFD79B00),
                          title: "Notifications",
                          subtitle: _isLoadingReminderSummary
                              ? 'Loading reminder preferences...'
                              : _notificationSubtitle,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationSettingsPage(),
                              ),
                            );
                            await _loadReminderSummary();
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.phone_android_rounded,
                          iconBg: const Color(0xFFE3E7FF),
                          iconColor: const Color(0xFF5B5FEF),
                          title: "App Preferences",
                          subtitle:
                              "${prefs.themeMode == ThemeMode.dark ? 'Dark' : 'Light'} mode, ${prefs.languageLabel}, ${prefs.fontSizeLabel} text",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppPreferencesPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: "Privacy & Security",
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.shield_outlined,
                          iconBg: const Color(0xFFFFE3E3),
                          iconColor: const Color(0xFFFF2D2D),
                          title: "Privacy Settings",
                          subtitle:
                              prefs.hideSensitiveContent ||
                                  prefs.biometricLockEnabled
                              ? "Local privacy controls are active"
                              : "Data control and privacy preferences",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacySecurityPage(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.location_on_outlined,
                          iconBg: const Color(0xFFE2F7EC),
                          iconColor: const Color(0xFF1F9D63),
                          title: "Location Settings",
                          subtitle: "Current: ${prefs.locationPermissionLabel}",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LocationSettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: "Account Settings",
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.cleaning_services_outlined,
                          iconBg: const Color(0xFFFFF2E2),
                          iconColor: const Color(0xFFCC7A00),
                          title: "Clear Data for This Account",
                          subtitle: _accountActionSubtitle,
                          onTap: () {
                            _openProtectedAccountPage(
                              actionTitle:
                                  'Confirm password to clear local data',
                              builder: (_) => const ClearAccountDataPage(),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.person_remove_outlined,
                          iconBg: const Color(0xFFFFE3E3),
                          iconColor: const Color(0xFFD14343),
                          title: "Delete Account",
                          subtitle: _accountActionSubtitle,
                          onTap: () {
                            _openProtectedAccountPage(
                              actionTitle: 'Confirm password to delete account',
                              builder: (verifiedPassword) => DeleteAccountPage(
                                verifiedPassword: verifiedPassword,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: "Support & App Info",
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.help_outline_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          title: "Help & Support",
                          subtitle: "Contact channels and support details",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpSupportPage(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.article_outlined,
                          iconBg: const Color(0xFFF0FDFA),
                          iconColor: const Color(0xFF0F766E),
                          title: "Terms & Privacy Policy",
                          subtitle: "Review app terms and data practices",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsPrivacyPage(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.info_outline_rounded,
                          iconBg: const Color(0xFFF5F3FF),
                          iconColor: const Color(0xFF7C3AED),
                          title: "About",
                          subtitle: "Project overview and team credits",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AboutPage(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.verified_outlined,
                          iconBg: const Color(0xFFFFF7ED),
                          iconColor: const Color(0xFFEA580C),
                          title: "Version",
                          subtitle: "Current build and release notes",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VersionPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard({
    required BuildContext context,
    required AppPreferencesState prefs,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsLabel = prefs.notificationsEnabled ? 'On' : 'Off';
    final accountLabel = _session.isLoggedIn ? 'Signed in' : 'Local mode';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1B4D5C), Color(0xFF1EAD83)]
                        : const [Color(0xFFDDF8EE), Color(0xFFEAF5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: pageBorderColor(context)),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.spa_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings Center',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalize your VitalySync experience from one place.',
                      style: TextStyle(
                        height: 1.35,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatusPill(
                context: context,
                icon: Icons.palette_outlined,
                label: prefs.themeMode == ThemeMode.dark ? 'Dark' : 'Light',
              ),
              _buildStatusPill(
                context: context,
                icon: Icons.notifications_active_outlined,
                label: 'Notifications $notificationsLabel',
              ),
              _buildStatusPill(
                context: context,
                icon: Icons.account_circle_outlined,
                label: accountLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF6FBFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (title.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: isDark ? iconBg.withValues(alpha: 0.16) : iconBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: isDark ? 0.18 : 0.08),
                ),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? pagePrimaryTextColor(context)
                          : pageSecondaryTextColor(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: enabled ? Color(0xFF9CA3AF) : Color(0xFFCBD5E1),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: pageBorderColor(context),
      indent: 18,
      endIndent: 18,
    );
  }
}

class _PasswordVerificationDialog extends StatefulWidget {
  final String actionTitle;
  final String email;

  const _PasswordVerificationDialog({
    required this.actionTitle,
    required this.email,
  });

  @override
  State<_PasswordVerificationDialog> createState() =>
      _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState
    extends State<_PasswordVerificationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String _errorText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final password = _controller.text.trim();

    if (password.isEmpty) {
      setState(() {
        _errorText = 'Enter your password to continue.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = '';
    });

    try {
      await UserSessionController.instance.reauthenticateWithPassword(
        password: password,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(password);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Text(widget.actionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the password for ${widget.email} before continuing.'),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              obscureText: _obscurePassword,
              autofocus: true,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _errorText.isEmpty ? null : _errorText,
                suffixIcon: IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              onSubmitted: (_) {
                if (!_isSubmitting) {
                  _verifyPassword();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _verifyPassword,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
