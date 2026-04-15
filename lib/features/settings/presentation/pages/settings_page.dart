import 'package:flutter/material.dart';

import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../log/data/log_api.dart';
import 'app_preferences_page.dart';
import 'help_support_page.dart';
import 'notification_settings_page.dart';
import 'privacy_security_page.dart';
import 'terms_privacy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoadingReminderSummary = true;
  String _notificationSubtitle =
      'Loading your saved reminder preferences...';

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

    if (session.isDemoMode || session.userId == null) {
      final prefs = AppPreferencesController.instance.notifier.value;
      setState(() {
        _notificationSubtitle = _buildLocalNotificationSummary(prefs);
        _isLoadingReminderSummary = false;
      });
      return;
    }

    try {
      final summary = await OnboardingApi.fetchSummary(session.userId!);
      final preferences =
          Map<String, dynamic>.from(summary['preferences'] as Map? ?? {});

      final dailyReminder = preferences['prefers_daily_reminder'] == true;
      final hydrationReminder =
          preferences['prefers_hydration_reminder'] == true;
      final sleepReminder = preferences['prefers_sleep_reminder'] == true;
      final reminderTime =
          (preferences['reminder_time'] ?? '').toString().trim();

      await AppPreferencesController.instance.syncNotificationPreferences(
        notificationsEnabled: dailyReminder,
        bedtimeReminderEnabled: sleepReminder,
        hydrationReminderEnabled: hydrationReminder,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _notificationSubtitle = _buildAccountNotificationSummary(
          dailyReminder: dailyReminder,
          hydrationReminder: hydrationReminder,
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
    ];

    if (enabled.isEmpty) {
      return 'Notifications are enabled with no specific reminder types selected';
    }

    return '${enabled.join(' and ')} reminders are enabled on this device';
  }

  String _buildAccountNotificationSummary({
    required bool dailyReminder,
    required bool hydrationReminder,
    required bool sleepReminder,
    required String reminderTime,
  }) {
    final enabled = <String>[
      if (dailyReminder) 'daily',
      if (hydrationReminder) 'hydration',
      if (sleepReminder) 'sleep',
    ];

    if (enabled.isEmpty) {
      return 'Account reminders are currently turned off';
    }

    final joined = enabled.join(', ');
    final timeSuffix = reminderTime.isEmpty ? '' : ' around $reminderTime';
    return '${joined[0].toUpperCase()}${joined.substring(1)} reminders are enabled$timeSuffix';
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
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
                          subtitle: prefs.hideSensitiveContent ||
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: "",
                      children: [
                        _buildSettingsTile(
                          context: context,
                          icon: Icons.help_outline_rounded,
                          iconBg: const Color(0xFFF1F3F5),
                          iconColor: const Color(0xFF4B5563),
                          title: "Help & Support",
                          subtitle: null,
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
                          iconBg: const Color(0xFFF1F3F5),
                          iconColor: const Color(0xFF4B5563),
                          title: "Terms & Privacy Policy",
                          subtitle: null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsPrivacyPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDeleteButton(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.04,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
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
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
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

  Widget _buildDeleteButton(BuildContext context) { 
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFC9C9),
        ),
        color: pageSurfaceColor(context),
      ),
      child: TextButton.icon(
        onPressed: () => _showClearDataDialog(context),
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.red,
        ),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            "Clear Local App Data",
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear local data?'),
          content: const Text(
            'This will remove saved preferences, demo data, and the local session on this device. Your server account will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final preferences = AppPreferencesController.instance;
    await preferences.resetToDefaults();
    await LogApi.clearLocalDemoData();
    await UserSessionController.instance.clearSession();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
