import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/localized_text.dart';
import '../../shared/notifications/notification_system_settings_controller.dart';
import '../../shared/theme/app_page_style.dart';
import 'first_install_permission_coordinator.dart';

class FirstInstallPermissionGate extends StatefulWidget {
  final Widget child;
  final FirstInstallPermissionCoordinator? coordinator;

  const FirstInstallPermissionGate({
    super.key,
    required this.child,
    this.coordinator,
  });

  @override
  State<FirstInstallPermissionGate> createState() =>
      _FirstInstallPermissionGateState();
}

class _FirstInstallPermissionGateState
    extends State<FirstInstallPermissionGate> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runPermissionFlow());
    });
  }

  Future<void> _runPermissionFlow() async {
    try {
      await (widget.coordinator ?? FirstInstallPermissionCoordinator.instance)
          .run(notificationSoundStep: _showNotificationSoundStep);
    } finally {
      if (mounted) {
        setState(() => _isReady = true);
      }
    }
  }

  Future<void> _showNotificationSoundStep() async {
    if (!mounted) {
      return;
    }

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Turn on notification sound'),
        content: const LocalizedText(
          'Android gives you final control of notification sound. Open VitalySync notification settings, turn on Ring, then return here to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const LocalizedText('Not now'),
          ),
          FilledButton(
            key: const ValueKey('open-notification-sound-settings'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const LocalizedText('Open sound settings'),
          ),
        ],
      ),
    );

    if (shouldOpenSettings == true) {
      await NotificationSystemSettingsController.instance.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return widget.child;
    }

    return Container(
      decoration: buildPageDecoration(context),
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 18),
                LocalizedText(
                  'Preparing your device permissions...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
