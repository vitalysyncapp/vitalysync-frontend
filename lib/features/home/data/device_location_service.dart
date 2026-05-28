import 'package:geolocator/geolocator.dart';

import '../../../shared/preferences/app_preferences.dart';

class DeviceCoordinates {
  const DeviceCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class DeviceLocationService {
  static Future<DeviceCoordinates?> getCurrentCoordinates() async {
    final preferences = AppPreferencesController.instance;
    var permissionChoice = preferences.notifier.value.locationPermissionChoice;

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    final hasPermission =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (hasPermission) {
      await preferences.updateLocationPermissionChoice(
        AppLocationPermissionChoice.allowed,
      );
    }

    if (permissionChoice == AppLocationPermissionChoice.denied &&
        !hasPermission) {
      return null;
    }

    if (permission == LocationPermission.denied &&
        permissionChoice == AppLocationPermissionChoice.undecided) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await preferences.updateLocationPermissionChoice(
        AppLocationPermissionChoice.denied,
      );
      return null;
    }

    await preferences.updateLocationPermissionChoice(
      AppLocationPermissionChoice.allowed,
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));

      return DeviceCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition == null) {
        return null;
      }

      return DeviceCoordinates(
        latitude: lastKnownPosition.latitude,
        longitude: lastKnownPosition.longitude,
      );
    }
  }

  static Future<DeviceCoordinates?> getLastKnownCoordinates() async {
    final preferences = AppPreferencesController.instance;

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return null;
    }

    final permission = await Geolocator.checkPermission();
    if (!_hasLocationPermission(permission)) {
      return null;
    }

    await preferences.updateLocationPermissionChoice(
      AppLocationPermissionChoice.allowed,
    );

    try {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition == null) {
        return null;
      }

      return DeviceCoordinates(
        latitude: lastKnownPosition.latitude,
        longitude: lastKnownPosition.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> enableLocationAccess() async {
    final preferences = AppPreferencesController.instance;

    if (!await Geolocator.isLocationServiceEnabled()) {
      await preferences.updateLocationPermissionChoice(
        AppLocationPermissionChoice.denied,
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    await preferences.updateLocationPermissionChoice(
      granted
          ? AppLocationPermissionChoice.allowed
          : AppLocationPermissionChoice.denied,
    );

    return granted;
  }

  static Future<void> disableLocationAccess() async {
    await AppPreferencesController.instance.updateLocationPermissionChoice(
      AppLocationPermissionChoice.denied,
    );
  }

  static Future<bool> openSystemLocationSettings() async {
    final openedAppSettings = await Geolocator.openAppSettings();
    final openedLocationSettings = await Geolocator.openLocationSettings();
    return openedAppSettings || openedLocationSettings;
  }

  static bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
