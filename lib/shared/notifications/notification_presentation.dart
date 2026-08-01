class NotificationPresentation {
  final String androidChannelId;
  final String androidChannelName;
  final String androidChannelDescription;
  final String androidSoundResource;
  final String darwinSoundFile;
  final bool usesHighPriority;

  const NotificationPresentation({
    required this.androidChannelId,
    required this.androidChannelName,
    required this.androidChannelDescription,
    required this.androidSoundResource,
    required this.darwinSoundFile,
    this.usesHighPriority = false,
  });

  static const _reminder = NotificationPresentation(
    androidChannelId: 'vitalysync_reminders_sound_1_v1',
    androidChannelName: 'VitalySync reminders',
    androidChannelDescription:
        'Daily check-ins, meal prompts, and other wellness reminders with sound 1.',
    androidSoundResource: 'notification_sound_1',
    darwinSoundFile: 'notification_sound_1.wav',
  );

  static const _hydrationReminder = NotificationPresentation(
    androidChannelId: 'vitalysync_hydration_reminders_sound_1_v1',
    androidChannelName: 'Hydration reminders',
    androidChannelDescription:
        'Water break reminders that stay visible and use sound 1.',
    androidSoundResource: 'notification_sound_1',
    darwinSoundFile: 'notification_sound_1.wav',
    usesHighPriority: true,
  );

  static const _nudge = NotificationPresentation(
    androidChannelId: 'vitalysync_nudges_sound_2_v1',
    androidChannelName: 'VitalySync nudges',
    androidChannelDescription: 'Adaptive wellness nudges with sound 2.',
    androidSoundResource: 'notification_sound_2',
    darwinSoundFile: 'notification_sound_2.wav',
  );

  static const _windDown = NotificationPresentation(
    androidChannelId: 'vitalysync_wind_down_sound_3_v1',
    androidChannelName: 'Wind-down reminders',
    androidChannelDescription: 'Sleep wind-down reminders with sound 3.',
    androidSoundResource: 'notification_sound_3',
    darwinSoundFile: 'notification_sound_3.wav',
  );

  static NotificationPresentation forNotificationType(String notificationType) {
    if (notificationType == 'sleep_wind_down_reminder') {
      return _windDown;
    }
    if (notificationType == 'hydration_reminder') {
      return _hydrationReminder;
    }
    if (notificationType.contains('nudge')) {
      return _nudge;
    }
    return _reminder;
  }
}
