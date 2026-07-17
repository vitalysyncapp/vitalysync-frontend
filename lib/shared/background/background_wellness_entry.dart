import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../features/activity/data/activity_service.dart';
import '../../features/home/data/device_location_service.dart';
import '../../features/home/data/environment_api.dart';
import '../notifications/notification_feed_service.dart';
import '../preferences/app_preferences.dart';
import '../preferences/user_session.dart';

const MethodChannel _backgroundWellnessChannel = MethodChannel(
  'vitalysync/background_wellness',
);

const double _fallbackLatitude = 9.65;
const double _fallbackLongitude = 123.85;

Future<void> runBackgroundWellnessCollection() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    await AppPreferencesController.instance.load();
    final session = await UserSessionController.instance.load();
    if (!session.isLoggedIn ||
        !session.hasAuthToken ||
        session.userId == null) {
      return;
    }

    await Future.wait([
      ActivityService.instance.primeStepTrackingSnapshot(),
      _refreshEnvironmentSnapshot(),
      NotificationFeedService.instance.refreshFeed(),
    ]);
  } finally {
    await _notifyNativeComplete();
  }
}

Future<void> _refreshEnvironmentSnapshot() async {
  try {
    final coordinates = await DeviceLocationService.getLastKnownCoordinates();
    await EnvironmentApi.fetchEnvironment(
      lat: coordinates?.latitude ?? _fallbackLatitude,
      lon: coordinates?.longitude ?? _fallbackLongitude,
    );
  } catch (_) {
    // Background collection should never surface failures to the user.
  }
}

Future<void> _notifyNativeComplete() async {
  try {
    await _backgroundWellnessChannel.invokeMethod<void>(
      'backgroundRunComplete',
    );
  } on PlatformException {
    return;
  } on MissingPluginException {
    return;
  }
}
