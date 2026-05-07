import 'dart:async';
import 'dart:io';

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

  Future<bool> isOverlayPermissionGranted() async {
    if (!Platform.isAndroid) {
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
    if (!Platform.isAndroid) {
      return;
    }

    await _invokeOverlayMethod('openOverlayPermissionSettings');
  }

  Future<void> startOverlayService() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _invokeOverlayMethod('startOverlayService');
  }

  Future<void> stopOverlayService() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _invokeOverlayMethod('stopOverlayService');
  }

  Future<void> collapseOverlay() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _invokeOverlayMethod('collapseOverlay');
  }

  Future<void> syncSettings(AppPreferencesState prefs) async {
    if (!Platform.isAndroid) {
      return;
    }

    await _invokeOverlayMethod('syncOverlaySettings', {
      'enabled': prefs.assistantOverlayEnabled,
      'autoShowEnabled': prefs.assistantOverlayAutoShowEnabled,
      'autoShowTime': prefs.assistantOverlayAutoShowTime,
    });
  }

  Future<void> syncAppLifecycle({
    required bool isForeground,
    required AppPreferencesState prefs,
  }) async {
    if (!Platform.isAndroid) {
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

  Future<bool> ensurePermissionWithPrompt(BuildContext context) async {
    if (!Platform.isAndroid) {
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
