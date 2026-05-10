import 'package:flutter/material.dart';

import '../../../../features/adaptive/data/adaptive_reminder_api.dart';
import '../../../../features/onboarding/data/onboarding_api.dart';
import '../../../../shared/notifications/local_notification_service.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';

part 'notification_settings_widgets.dart';

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
  String _dailyLogReminderTime = '20:00';
  String _hydrationStartTime = '07:00';
  String _hydrationEndTime = '21:00';
  int _hydrationIntervalMinutes = 120;
  String _sleepWindDownTime = '21:30';
  int _nudgeCooldownHours = 6;
  int _maxDailyNudges = 3;
  String _preferredNudgeStyle = 'Gentle';
  String _primaryGoal = 'Reduce stress';
  List<int> _busyDays = const [1, 3, 5];

  bool _prefersDailyReminder = true;
  bool _prefersHydrationReminder = true;
  bool _prefersMealReminder = true;
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
        _prefersMealReminder = localPrefs.mealReminderEnabled;
        _prefersSleepReminder = localPrefs.bedtimeReminderEnabled;
        _dailyLogReminderTime = localPrefs.dailyLogReminderTime;
        _hydrationStartTime = localPrefs.hydrationStartTime;
        _hydrationEndTime = localPrefs.hydrationEndTime;
        _hydrationIntervalMinutes = localPrefs.hydrationIntervalMinutes;
        _sleepWindDownTime = localPrefs.sleepWindDownTime;
        _isLoading = false;
      });
      return;
    }

    try {
      final summary = await OnboardingApi.fetchSummary(session.userId!);
      final accountPreferences = Map<String, dynamic>.from(
        summary['preferences'] as Map? ?? {},
      );
      final busyDays =
          (summary['busy_days'] as List?)
              ?.map((value) => int.tryParse('$value'))
              .whereType<int>()
              .toList() ??
          const <int>[];
      final reminderPreferences = await AdaptiveReminderApi.fetchPreferences();

      await AppPreferencesController.instance.syncNotificationPreferences(
        notificationsEnabled:
            accountPreferences['prefers_daily_reminder'] == true,
        bedtimeReminderEnabled: reminderPreferences.sleepWindDownEnabled,
        hydrationReminderEnabled: reminderPreferences.hydrationReminderEnabled,
        mealReminderEnabled: localPrefs.mealReminderEnabled,
        dailyLogReminderTime: reminderPreferences.dailyLogReminderTime,
        hydrationStartTime: reminderPreferences.hydrationStartTime,
        hydrationEndTime: reminderPreferences.hydrationEndTime,
        hydrationIntervalMinutes: reminderPreferences.hydrationIntervalMinutes,
        sleepWindDownTime: reminderPreferences.sleepWindDownTime,
      );
      await LocalNotificationService.instance
          .refreshReminderScheduleFromPreferences();

      if (!mounted) {
        return;
      }

      setState(() {
        _preferredLogTime = _stringOrFallback(
          accountPreferences['preferred_log_time'],
          '20:30',
        );
        _defaultWakeTime = _stringOrFallback(
          accountPreferences['default_wake_time'],
          '06:30',
        );
        _defaultSleepTime = _stringOrFallback(
          accountPreferences['default_sleep_time'],
          '22:30',
        );
        _defaultWorkStart = _stringOrFallback(
          accountPreferences['default_work_start'],
          '09:00',
        );
        _defaultWorkEnd = _stringOrFallback(
          accountPreferences['default_work_end'],
          '18:00',
        );
        _reminderTime = _stringOrFallback(
          accountPreferences['reminder_time'],
          '20:00',
        );
        _dailyLogReminderTime = reminderPreferences.dailyLogReminderTime;
        _hydrationStartTime = reminderPreferences.hydrationStartTime;
        _hydrationEndTime = reminderPreferences.hydrationEndTime;
        _hydrationIntervalMinutes =
            reminderPreferences.hydrationIntervalMinutes;
        _sleepWindDownTime = reminderPreferences.sleepWindDownTime;
        _nudgeCooldownHours = reminderPreferences.nudgeCooldownHours;
        _maxDailyNudges = reminderPreferences.maxDailyNudges;
        _preferredNudgeStyle = _stringOrFallback(
          accountPreferences['preferred_nudge_style'],
          'Gentle',
        );
        _primaryGoal = _stringOrFallback(
          accountPreferences['primary_goal'],
          'Reduce stress',
        );
        _prefersDailyReminder =
            accountPreferences['prefers_daily_reminder'] == true;
        _prefersHydrationReminder =
            reminderPreferences.hydrationReminderEnabled;
        _prefersMealReminder = localPrefs.mealReminderEnabled;
        _prefersExerciseReminder =
            accountPreferences['prefers_exercise_reminder'] == true;
        _prefersSleepReminder = reminderPreferences.sleepWindDownEnabled;
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
        _prefersMealReminder = localPrefs.mealReminderEnabled;
        _prefersSleepReminder = localPrefs.bedtimeReminderEnabled;
        _dailyLogReminderTime = localPrefs.dailyLogReminderTime;
        _hydrationStartTime = localPrefs.hydrationStartTime;
        _hydrationEndTime = localPrefs.hydrationEndTime;
        _hydrationIntervalMinutes = localPrefs.hydrationIntervalMinutes;
        _sleepWindDownTime = localPrefs.sleepWindDownTime;
        _isLoading = false;
      });
    }
  }

  String _stringOrFallback(dynamic value, String fallback) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  Future<void> _pickReminderTime({
    required String currentValue,
    required ValueChanged<String> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDayFromString(currentValue),
    );
    if (picked == null || !mounted) {
      return;
    }

    onPicked(_formatTimeOfDay(picked));
    await _saveRemotePreferences();
  }

  TimeOfDay _timeOfDayFromString(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return TimeOfDay(
      hour: (hour ?? 0).clamp(0, 23).toInt(),
      minute: (minute ?? 0).clamp(0, 59).toInt(),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _hydrationIntervalLabel(int minutes) {
    if (minutes == 60) {
      return 'Every hour';
    }
    if (minutes % 60 == 0) {
      return 'Every ${minutes ~/ 60} hours';
    }

    return 'Every $minutes min';
  }

  Future<void> _syncLocalNotificationState() async {
    await AppPreferencesController.instance.syncNotificationPreferences(
      notificationsEnabled: _prefersDailyReminder,
      bedtimeReminderEnabled: _prefersSleepReminder,
      hydrationReminderEnabled: _prefersHydrationReminder,
      mealReminderEnabled: _prefersMealReminder,
      dailyLogReminderTime: _dailyLogReminderTime,
      hydrationStartTime: _hydrationStartTime,
      hydrationEndTime: _hydrationEndTime,
      hydrationIntervalMinutes: _hydrationIntervalMinutes,
      sleepWindDownTime: _sleepWindDownTime,
    );
    await LocalNotificationService.instance
        .refreshReminderScheduleFromPreferences();
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
      await AdaptiveReminderApi.savePreferences(_adaptiveReminderPreferences());
      await _syncLocalNotificationState();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder settings saved.')));
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

  AdaptiveReminderPreferences _adaptiveReminderPreferences() {
    return AdaptiveReminderPreferences(
      dailyLogReminderTime: _dailyLogReminderTime,
      weeklyPulseReminderDay: 1,
      weeklyPulseReminderTime: '18:00',
      hydrationStartTime: _hydrationStartTime,
      hydrationEndTime: _hydrationEndTime,
      hydrationIntervalMinutes: _hydrationIntervalMinutes,
      sleepWindDownTime: _sleepWindDownTime,
      hydrationReminderEnabled: _prefersHydrationReminder,
      recoveryReminderEnabled: _prefersExerciseReminder,
      sleepWindDownEnabled: _prefersSleepReminder,
      nudgeCooldownHours: _nudgeCooldownHours,
      maxDailyNudges: _maxDailyNudges,
    );
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
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    pageBottomContentPadding(context),
                  ),
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
                            value:
                                _prefersDailyReminder &&
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
                            title: 'Meal Reminders',
                            subtitle:
                                'Get gentle reminders to log meals and maintain consistency.',
                            value:
                                _prefersDailyReminder && _prefersMealReminder,
                            enabled: _prefersDailyReminder,
                            onChanged: (value) async {
                              setState(() {
                                _prefersMealReminder = value;
                              });
                              await _saveRemotePreferences();
                            },
                          ),
                          _divider(context),
                          _SwitchTile(
                            title: 'Exercise Reminder',
                            subtitle:
                                'Keep movement prompts aligned with your account preferences',
                            value:
                                _prefersDailyReminder &&
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
                      title: 'Reminder Schedule',
                      child: Column(
                        children: [
                          _TimeTile(
                            title: 'Daily log time',
                            subtitle: 'Main check-in reminder',
                            value: _dailyLogReminderTime,
                            enabled: _prefersDailyReminder,
                            onTap: () => _pickReminderTime(
                              currentValue: _dailyLogReminderTime,
                              onPicked: (value) {
                                setState(() {
                                  _dailyLogReminderTime = value;
                                  _reminderTime = value;
                                });
                              },
                            ),
                          ),
                          _divider(context),
                          _TimeTile(
                            title: 'Hydration starts',
                            subtitle: 'Default starts at 7:00 AM',
                            value: _hydrationStartTime,
                            enabled:
                                _prefersDailyReminder &&
                                _prefersHydrationReminder,
                            onTap: () => _pickReminderTime(
                              currentValue: _hydrationStartTime,
                              onPicked: (value) {
                                setState(() {
                                  _hydrationStartTime = value;
                                });
                              },
                            ),
                          ),
                          _divider(context),
                          _TimeTile(
                            title: 'Hydration ends',
                            subtitle: 'Stops reminders for the day',
                            value: _hydrationEndTime,
                            enabled:
                                _prefersDailyReminder &&
                                _prefersHydrationReminder,
                            onTap: () => _pickReminderTime(
                              currentValue: _hydrationEndTime,
                              onPicked: (value) {
                                setState(() {
                                  _hydrationEndTime = value;
                                });
                              },
                            ),
                          ),
                          _divider(context),
                          _SelectTile<int>(
                            title: 'Hydration frequency',
                            subtitle: 'Default is every 2 hours',
                            value: _hydrationIntervalMinutes,
                            enabled:
                                _prefersDailyReminder &&
                                _prefersHydrationReminder,
                            options: const [60, 120, 180, 240],
                            labelFor: _hydrationIntervalLabel,
                            onChanged: (value) async {
                              setState(() {
                                _hydrationIntervalMinutes = value;
                              });
                              await _saveRemotePreferences();
                            },
                          ),
                          _divider(context),
                          _TimeTile(
                            title: 'Sleep wind-down',
                            subtitle: 'Nightly prompt before bed',
                            value: _sleepWindDownTime,
                            enabled:
                                _prefersDailyReminder && _prefersSleepReminder,
                            onTap: () => _pickReminderTime(
                              currentValue: _sleepWindDownTime,
                              onPicked: (value) {
                                setState(() {
                                  _sleepWindDownTime = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsBlock(
                      title: 'Smart Nudge Limits',
                      child: Column(
                        children: [
                          _SelectTile<int>(
                            title: 'Minimum gap',
                            subtitle:
                                'Prevents repeated nudges of the same kind',
                            value: _nudgeCooldownHours,
                            options: const [4, 6, 8, 12],
                            labelFor: (value) => '$value hours',
                            onChanged: (value) async {
                              setState(() {
                                _nudgeCooldownHours = value;
                              });
                              await _saveRemotePreferences();
                            },
                          ),
                          _divider(context),
                          _SelectTile<int>(
                            title: 'Daily nudge cap',
                            subtitle: 'Urgent high-risk nudges can still pass',
                            value: _maxDailyNudges,
                            options: const [1, 2, 3, 4, 5],
                            labelFor: (value) => '$value per day',
                            onChanged: (value) async {
                              setState(() {
                                _maxDailyNudges = value;
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
