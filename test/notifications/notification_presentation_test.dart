import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/shared/notifications/notification_presentation.dart';

void main() {
  test('regular reminders use notification sound 1', () {
    for (final type in [
      'daily_log_reminder',
      'hydration_reminder',
      'nutrition_morning_breakfast',
    ]) {
      final presentation = NotificationPresentation.forNotificationType(type);

      expect(presentation.androidSoundResource, 'notification_sound_1');
      expect(presentation.darwinSoundFile, 'notification_sound_1.wav');
    }
  });

  test('nudge notifications use notification sound 2', () {
    for (final type in ['adaptive_nudge_reminder', 'adaptive_nudge_now']) {
      final presentation = NotificationPresentation.forNotificationType(type);

      expect(presentation.androidSoundResource, 'notification_sound_2');
      expect(presentation.darwinSoundFile, 'notification_sound_2.wav');
      expect(presentation.androidChannelId, contains('nudges_sound_2'));
    }
  });

  test('wind-down reminders use notification sound 3', () {
    final presentation = NotificationPresentation.forNotificationType(
      'sleep_wind_down_reminder',
    );

    expect(presentation.androidSoundResource, 'notification_sound_3');
    expect(presentation.darwinSoundFile, 'notification_sound_3.wav');
    expect(presentation.androidChannelId, contains('wind_down_sound_3'));
  });

  test('hydration keeps its high-priority notification channel', () {
    final presentation = NotificationPresentation.forNotificationType(
      'hydration_reminder',
    );

    expect(presentation.usesHighPriority, isTrue);
    expect(presentation.androidChannelId, contains('hydration_reminders'));
  });
}
