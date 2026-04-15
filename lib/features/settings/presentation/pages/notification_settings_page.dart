import 'package:flutter/material.dart';

import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDemoMode = false;
  int? _userId;

  String _preferredLogTime = '20:30';
  String _defaultWakeTime = '06:30';
  String _defaultSleepTime = '22:30';
  String _defaultWorkStart = '09:00';
  String _defaultWorkEnd = '18:00';
  String _reminderTime = '20:00';
  String _preferredNudgeStyle = 'Gentle';
  String _primaryGoal = 'Reduce stress';
  List<int> _busyDays = const [1, 3, 5];

  bool _prefersDailyReminder = true;
  bool _prefersHydrationReminder = true;
  bool _prefersExerciseReminder = true;
  bool _prefersSleepReminder = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final session = await UserSessionController.instance.load();
    final localPrefs = AppPreferencesController.instance.notifier.value;

    if (!mounted) {
      return;
    }

    _isDemoMode = session.isDemoMode || session.userId == null;
    _userId = session.userId;

    if (_isDemoMode) {
      setState(() {
        _prefersDailyReminder = localPrefs.notificationsEnabled;
        _prefersHydrationReminder = localPrefs.hydrationReminderEnabled;
        _prefersSleepReminder = localPrefs.bedtimeReminderEnabled;
        _isLoading = false;
      });
      return;
    }

    try {
      final summary = await OnboardingApi.fetchSummary(session.userId!);
      final accountPreferences =
          Map<String, dynamic>.from(summary['preferences'] as Map? ?? {});
      final busyDays = (summary['busy_days'] as List?)
              ?.map((value) => int.tryParse('$value'))
              .whereType<int>()
              .toList() ??
          const <int>[];

      await AppPreferencesController.instance.syncNotificationPreferences(
        notificationsEnabled:
            accountPreferences['prefers_daily_reminder'] == true,
        bedtimeReminderEnabled:
            accountPreferences['prefers_sleep_reminder'] == true,
        hydrationReminderEnabled:
            accountPreferences['prefers_hydration_reminder'] == true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _preferredLogTime =
            _stringOrFallback(accountPreferences['preferred_log_time'], '20:30');
        _defaultWakeTime =
            _stringOrFallback(accountPreferences['default_wake_time'], '06:30');
        _defaultSleepTime =
            _stringOrFallback(accountPreferences['default_sleep_time'], '22:30');
        _defaultWorkStart =
            _stringOrFallback(accountPreferences['default_work_start'], '09:00');
        _defaultWorkEnd =
            _stringOrFallback(accountPreferences['default_work_end'], '18:00');
        _reminderTime =
            _stringOrFallback(accountPreferences['reminder_time'], '20:00');
        _preferredNudgeStyle = _stringOrFallback(
          accountPreferences['preferred_nudge_style'],
          'Gentle',
        );
        _primaryGoal =
            _stringOrFallback(accountPreferences['primary_goal'], 'Reduce stress');
        _prefersDailyReminder =
            accountPreferences['prefers_daily_reminder'] == true;
        _prefersHydrationReminder =
            accountPreferences['prefers_hydration_reminder'] == true;
        _prefersExerciseReminder =
            accountPreferences['prefers_exercise_reminder'] == true;
        _prefersSleepReminder =
            accountPreferences['prefers_sleep_reminder'] == true;
        _busyDays = busyDays;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _prefersDailyReminder = localPrefs.notificationsEnabled;
        _prefersHydrationReminder = localPrefs.hydrationReminderEnabled;
        _prefersSleepReminder = localPrefs.bedtimeReminderEnabled;
        _isLoading = false;
      });
    }
  }

  String _stringOrFallback(dynamic value, String fallback) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  Future<void> _syncLocalNotificationState() {
    return AppPreferencesController.instance.syncNotificationPreferences(
      notificationsEnabled: _prefersDailyReminder,
      bedtimeReminderEnabled: _prefersSleepReminder,
      hydrationReminderEnabled: _prefersHydrationReminder,
    );
  }

  Future<void> _saveRemotePreferences() async {
    if (_isDemoMode || _userId == null) {
      await _syncLocalNotificationState();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await OnboardingApi.upsertPreferences(
        userId: _userId!,
        preferences: {
          'preferred_log_time': _preferredLogTime,
          'default_wake_time': _defaultWakeTime,
          'default_sleep_time': _defaultSleepTime,
          'default_work_start': _defaultWorkStart,
          'default_work_end': _defaultWorkEnd,
          'prefers_daily_reminder': _prefersDailyReminder,
          'reminder_time': _reminderTime,
          'prefers_hydration_reminder': _prefersHydrationReminder,
          'prefers_exercise_reminder': _prefersExerciseReminder,
          'prefers_sleep_reminder': _prefersSleepReminder,
          'preferred_nudge_style': _preferredNudgeStyle,
          'primary_goal': _primaryGoal,
          'busy_days': _busyDays,
        },
      );
      await _syncLocalNotificationState();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder settings saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save reminder settings: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _SettingsBlock(
                      title: 'Reminder Preferences',
                      child: Column(
                        children: [
                          _SwitchTile(
                            title: 'Daily Reminder',
                            subtitle:
                                'Controls your main account reminder schedule',
                            value: _prefersDailyReminder,
                            onChanged: (value) async {
                              setState(() {
                                _prefersDailyReminder = value;
                              });
                              await _saveRemotePreferences();
                            },
                          ),
                          _divider(context),
                          _SwitchTile(
                            title: 'Sleep Reminder',
                            subtitle: 'Show a nightly prompt to wind down',
                            value:
                                _prefersDailyReminder && _prefersSleepReminder,
                            enabled: _prefersDailyReminder,
                            onChanged: (value) async {
                              setState(() {
                                _prefersSleepReminder = value;
                              });
                              await _saveRemotePreferences();
                            },
                          ),
                          _divider(context),
                          _SwitchTile(
                            title: 'Hydration Reminder',
                            subtitle: 'Show a prompt when hydration is low',
                            value: _prefersDailyReminder &&
                                _prefersHydrationReminder,
                            enabled: _prefersDailyReminder,
                            onChanged: (value) async {
                              setState(() {
                                _prefersHydrationReminder = value;
                              });
                              await _saveRemotePreferences();
                            },
                          ),
                          _divider(context),
                          _SwitchTile(
                            title: 'Exercise Reminder',
                            subtitle:
                                'Keep movement prompts aligned with your account preferences',
                            value: _prefersDailyReminder &&
                                _prefersExerciseReminder,
                            enabled: _prefersDailyReminder,
                            onChanged: (value) async {
                              setState(() {
                                _prefersExerciseReminder = value;
                              });
                              await _saveRemotePreferences();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsBlock(
                      title: 'Synced Defaults',
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDemoMode
                                  ? 'This device is using demo reminder settings.'
                                  : 'These reminder defaults are synced from your onboarding preferences.',
                              style: TextStyle(
                                height: 1.45,
                                color: pageSecondaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Reminder time: $_reminderTime',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: pagePrimaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Preferred log time: $_preferredLogTime',
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Nudge style: $_preferredNudgeStyle',
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Primary goal: $_primaryGoal',
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isSaving) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
        ),
      ),
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

class _SettingsBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsBlock({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.05,
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
          child,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final Future<void> Function(bool) onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? pagePrimaryTextColor(context)
        : pageSecondaryTextColor(context);

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
                    color: titleColor,
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
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
