import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../preferences/app_preferences.dart';

class OverlayAssistantController {
  OverlayAssistantController._();

  static final OverlayAssistantController instance =
      OverlayAssistantController._();

  static const MethodChannel _channel = MethodChannel(
    'vitalysync/assistant_overlay',
  );

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isOverlayPermissionGranted() async {
    if (!_isAndroid) {
      return false;
    }

    try {
      final granted = await _channel.invokeMethod<bool>(
        'isOverlayPermissionGranted',
      );
      return granted ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openOverlayPermissionSettings() async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('openOverlayPermissionSettings');
  }

  Future<void> startOverlayService() async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('startOverlayService');
  }

  Future<void> stopOverlayService() async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('stopOverlayService');
  }

  Future<void> disableForLogout() async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('syncOverlaySettings', {'enabled': false});
    await _invokeOverlayMethod('stopOverlayService');
  }

  Future<void> collapseOverlay() async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('collapseOverlay');
  }

  Future<void> openApp({String payload = ''}) async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('openApp', {'payload': payload});
  }

  Future<void> scheduleReminderPreview({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
    required String notificationType,
  }) async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('scheduleReminderPreview', {
      'id': id,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
      'payload': payload,
      'notificationType': notificationType,
    });
  }

  Future<void> cancelReminderPreview(int id) async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('cancelReminderPreview', {'id': id});
  }

  Future<bool> showGeneratedPreview({
    required String kind,
    required String title,
    required String body,
  }) async {
    if (!_isAndroid) {
      return false;
    }

    return _invokeOverlayBoolMethod('showGeneratedPreview', {
      'kind': kind,
      'title': title,
      'body': body,
    });
  }

  Future<void> syncSettings(AppPreferencesState prefs) async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('syncOverlaySettings', {
      'enabled': prefs.assistantOverlayEnabled,
    });
  }

  Future<void> syncAppLifecycle({
    required bool isForeground,
    required AppPreferencesState prefs,
  }) async {
    if (!_isAndroid) {
      return;
    }

    await _invokeOverlayMethod('syncAppVisibility', {
      'isForeground': isForeground,
      'enabled': prefs.assistantOverlayEnabled,
    });
  }

  Future<void> _invokeOverlayMethod(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<bool> _invokeOverlayBoolMethod(
    String method, [
    Object? arguments,
  ]) async {
    try {
      final result = await _channel.invokeMethod<bool>(method, arguments);
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> ensurePermissionWithPrompt(BuildContext context) async {
    if (!_isAndroid) {
      return false;
    }

    if (await isOverlayPermissionGranted()) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Allow floating assistant'),
          content: Text(
            'VitalySync needs the Android "display over other apps" permission so the assistant can appear outside the app.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );

    if (approved != true) {
      return false;
    }

    await openOverlayPermissionSettings();
    return true;
  }
}
