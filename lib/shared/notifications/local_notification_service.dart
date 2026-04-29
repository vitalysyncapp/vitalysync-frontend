import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_event_api.dart';
import '../preferences/app_preferences.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const int _dailyLogReminderId = 1001;
  static const int _hydrationReminderBaseId = 2000;
  static const int _hydrationReminderMaxSlots = 48;
  static const int _sleepReminderId = 1003;
  static const int _adaptiveReminderId = 1100;
  static const int _adaptiveNowId = 1101;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _pendingLaunchPayload;
  void Function(String payload)? onNotificationPayload;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null &&
        launchPayload.isNotEmpty) {
      _pendingLaunchPayload = launchPayload;
    }
    _initialized = true;
  }

  String? consumePendingLaunchPayload() {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return payload;
  }

  void rememberPendingPayload(String payload) {
    if (payload.isNotEmpty) {
      _pendingLaunchPayload = payload;
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    final handler = onNotificationPayload;
    if (handler == null) {
      _pendingLaunchPayload = payload;
      return;
    }

    handler(payload);
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (kIsWeb) {
      return false;
    }

    final androidGranted =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        true;
    final iosGranted =
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    final macGranted =
        await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;

    return androidGranted && iosGranted && macGranted;
  }

  Future<void> refreshReminderScheduleFromPreferences() async {
    await initialize();
    if (kIsWeb) {
      return;
    }

    final prefs = AppPreferencesController.instance.notifier.value;
    await _cancelDefaultReminders();

    if (!prefs.notificationsEnabled) {
      return;
    }

    await requestPermissions();
    final dailyTime = _parseTime(prefs.dailyLogReminderTime);
    await scheduleDailyLogReminder(
      hour: dailyTime.hour,
      minute: dailyTime.minute,
    );

    if (prefs.hydrationReminderEnabled) {
      await scheduleHydrationReminders(
        startTime: prefs.hydrationStartTime,
        endTime: prefs.hydrationEndTime,
        intervalMinutes: prefs.hydrationIntervalMinutes,
      );
    }

    if (prefs.bedtimeReminderEnabled) {
      final sleepTime = _parseTime(prefs.sleepWindDownTime);
      await scheduleSleepReminder(
        hour: sleepTime.hour,
        minute: sleepTime.minute,
      );
    }
  }

  Future<void> scheduleDailyLogReminder({
    required int hour,
    required int minute,
  }) {
    return _scheduleDaily(
      id: _dailyLogReminderId,
      title: 'Daily check-in',
      body: "Log today's stress, workload, recovery, and energy.",
      hour: hour,
      minute: minute,
      payload: 'daily_log',
      notificationType: 'daily_log_reminder',
    );
  }

  Future<void> scheduleHydrationReminders({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) async {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    final boundedInterval = intervalMinutes.clamp(30, 360).toInt();
    final startMinutes = start.hour * 60 + start.minute;
    var endMinutes = end.hour * 60 + end.minute;
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    var index = 0;
    for (
      var minuteOfDay = startMinutes;
      minuteOfDay <= endMinutes && index < _hydrationReminderMaxSlots;
      minuteOfDay += boundedInterval
    ) {
      final normalizedMinute = minuteOfDay % (24 * 60);
      await _scheduleDaily(
        id: _hydrationReminderBaseId + index,
        title: 'Hydration reset',
        body: 'Take a quick water break before your next task.',
        hour: normalizedMinute ~/ 60,
        minute: normalizedMinute % 60,
        payload: 'hydration',
        notificationType: 'hydration_reminder',
        metadata: {
          'hydration_start_time': startTime,
          'hydration_end_time': endTime,
          'hydration_interval_minutes': boundedInterval,
        },
      );
      index += 1;
    }
  }

  Future<void> scheduleHydrationReminder({
    required int hour,
    required int minute,
  }) {
    return _scheduleDaily(
      id: _hydrationReminderBaseId,
      title: 'Hydration reset',
      body: 'Take a quick water break before your next task.',
      hour: hour,
      minute: minute,
      payload: 'hydration',
      notificationType: 'hydration_reminder',
    );
  }

  Future<void> scheduleSleepReminder({required int hour, required int minute}) {
    return _scheduleDaily(
      id: _sleepReminderId,
      title: 'Wind down soon',
      body: 'Start easing your workload so sleep has room to happen.',
      hour: hour,
      minute: minute,
      payload: 'sleep_wind_down',
      notificationType: 'sleep_wind_down_reminder',
    );
  }

  Future<void> scheduleAdaptiveReminder({
    required String title,
    required String body,
    Duration delay = const Duration(minutes: 30),
    String payload = 'adaptive_nudge',
  }) async {
    await initialize();
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }

    await requestPermissions();
    final scheduledDate = _zonedFromLocal(DateTime.now().add(delay));
    await _plugin.zonedSchedule(
      id: _adaptiveReminderId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
    unawaited(
      _safeLogNotificationEvent(
        notificationType: 'adaptive_nudge_reminder',
        title: title,
        body: body,
        scheduledFor: _dateTimeFromZoned(scheduledDate),
        status: 'scheduled',
        metadata: {'payload': payload, 'delay_minutes': delay.inMinutes},
      ),
    );
  }

  Future<void> showAdaptiveNudgeNow({
    required String title,
    required String body,
    String payload = 'adaptive_nudge_now',
  }) async {
    await initialize();
    if (kIsWeb) {
      return;
    }

    await requestPermissions();
    await _plugin.show(
      id: _adaptiveNowId,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
      payload: payload,
    );
    unawaited(
      _safeLogNotificationEvent(
        notificationType: 'adaptive_nudge_now',
        title: title,
        body: body,
        sentAt: DateTime.now(),
        status: 'sent',
        metadata: {'payload': payload},
      ),
    );
  }

  Future<void> cancelAdaptiveReminder() async {
    await initialize();
    await _plugin.cancel(id: _adaptiveReminderId);
  }

  Future<void> _cancelDefaultReminders() async {
    await _plugin.cancel(id: _dailyLogReminderId);
    for (var index = 0; index < _hydrationReminderMaxSlots; index += 1) {
      await _plugin.cancel(id: _hydrationReminderBaseId + index);
    }
    await _plugin.cancel(id: _sleepReminderId);
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
    required String notificationType,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    await initialize();
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }

    final scheduledDate = _nextDailyTime(hour: hour, minute: minute);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    unawaited(
      _safeLogNotificationEvent(
        notificationType: notificationType,
        title: title,
        body: body,
        scheduledFor: _dateTimeFromZoned(scheduledDate),
        status: 'scheduled',
        metadata: {
          'payload': payload,
          'reminder_id': id,
          'recurring_daily': true,
          ...metadata,
        },
      ),
    );
  }

  tz.TZDateTime _nextDailyTime({required int hour, required int minute}) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return _zonedFromLocal(scheduled);
  }

  tz.TZDateTime _zonedFromLocal(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  DateTime _dateTimeFromZoned(tz.TZDateTime dateTime) {
    return DateTime.fromMillisecondsSinceEpoch(dateTime.millisecondsSinceEpoch);
  }

  _TimeParts _parseTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return _TimeParts(
      hour: (hour ?? 0).clamp(0, 23).toInt(),
      minute: (minute ?? 0).clamp(0, 59).toInt(),
    );
  }

  Future<void> _safeLogNotificationEvent({
    required String notificationType,
    required String title,
    required String body,
    DateTime? scheduledFor,
    DateTime? sentAt,
    required String status,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    try {
      await NotificationEventApi.createEvent(
        notificationType: notificationType,
        title: title,
        body: body,
        scheduledFor: scheduledFor,
        sentAt: sentAt,
        status: status,
        metadata: metadata,
      );
    } catch (_) {
      // Notification delivery should not fail because analytics logging failed.
    }
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      'vitalysync_reminders',
      'VitalySync Reminders',
      channelDescription:
          'Daily check-ins, hydration prompts, sleep wind-downs, and adaptive nudges.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwin = DarwinNotificationDetails();

    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }
}

class _TimeParts {
  final int hour;
  final int minute;

  const _TimeParts({required this.hour, required this.minute});
}
