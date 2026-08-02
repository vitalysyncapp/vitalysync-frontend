import 'package:shared_preferences/shared_preferences.dart';

import '../../features/activity/data/activity_service.dart';
import '../../features/home/data/device_location_service.dart';
import '../../shared/notifications/local_notification_service.dart';
import 'permission_runtime.dart';

typedef PermissionFlowStep = Future<void> Function();

class FirstInstallPermissionCoordinator {
  static const String completionKey =
      'first_install_permission_flow_completed_v1';

  static final FirstInstallPermissionCoordinator instance =
      FirstInstallPermissionCoordinator(
        isAndroid: () => isAndroidPermissionRuntime,
        isCompleted: () async {
          final preferences = await SharedPreferences.getInstance();
          return preferences.getBool(completionKey) ?? false;
        },
        markCompleted: () async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setBool(completionKey, true);
        },
        requestNotificationPermission: () async {
          await LocalNotificationService.instance.requestPermissions();
          await LocalNotificationService.instance
              .createAndroidNotificationChannels();
        },
        requestLocationPermission: () async {
          await DeviceLocationService.enableLocationAccess();
        },
        requestActivityPermission: () async {
          await ActivityService.instance.requestActivityRecognitionPermission();
        },
        refreshNotificationSchedule: () => LocalNotificationService.instance
            .refreshReminderScheduleFromPreferences(requestPermission: false),
      );

  final bool Function() _isAndroid;
  final Future<bool> Function() _isCompleted;
  final PermissionFlowStep _markCompleted;
  final PermissionFlowStep _requestNotificationPermission;
  final PermissionFlowStep _requestLocationPermission;
  final PermissionFlowStep _requestActivityPermission;
  final PermissionFlowStep _refreshNotificationSchedule;

  const FirstInstallPermissionCoordinator({
    required bool Function() isAndroid,
    required Future<bool> Function() isCompleted,
    required PermissionFlowStep markCompleted,
    required PermissionFlowStep requestNotificationPermission,
    required PermissionFlowStep requestLocationPermission,
    required PermissionFlowStep requestActivityPermission,
    required PermissionFlowStep refreshNotificationSchedule,
  }) : _isAndroid = isAndroid,
       _isCompleted = isCompleted,
       _markCompleted = markCompleted,
       _requestNotificationPermission = requestNotificationPermission,
       _requestLocationPermission = requestLocationPermission,
       _requestActivityPermission = requestActivityPermission,
       _refreshNotificationSchedule = refreshNotificationSchedule;

  Future<void> run({required PermissionFlowStep notificationSoundStep}) async {
    if (!_isAndroid() || await _isCompleted()) {
      return;
    }

    await _requestNotificationPermission();
    await notificationSoundStep();
    await _requestLocationPermission();
    await _requestActivityPermission();
    await _refreshNotificationSchedule();
    await _markCompleted();
  }
}
