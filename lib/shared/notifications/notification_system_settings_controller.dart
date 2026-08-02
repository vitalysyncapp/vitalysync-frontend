import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationSystemSettingsController {
  NotificationSystemSettingsController._();

  static final NotificationSystemSettingsController instance =
      NotificationSystemSettingsController._();

  static const MethodChannel _channel = MethodChannel(
    'vitalysync/notification_settings',
  );

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> open() async {
    if (!isSupported) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
