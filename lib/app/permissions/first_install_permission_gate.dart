import 'dart:async';

import 'package:flutter/material.dart';

import 'first_install_permission_coordinator.dart';

class FirstInstallPermissionGate extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final FirstInstallPermissionCoordinator? coordinator;

  const FirstInstallPermissionGate({
    super.key,
    required this.child,
    this.enabled = true,
    this.coordinator,
  });

  @override
  State<FirstInstallPermissionGate> createState() =>
      _FirstInstallPermissionGateState();
}

class _FirstInstallPermissionGateState
    extends State<FirstInstallPermissionGate> {
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _schedulePermissionFlow();
  }

  @override
  void didUpdateWidget(covariant FirstInstallPermissionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePermissionFlow();
  }

  void _schedulePermissionFlow() {
    if (!widget.enabled || _hasStarted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled || _hasStarted) {
        return;
      }
      _hasStarted = true;
      unawaited(_runPermissionFlow());
    });
  }

  Future<void> _runPermissionFlow() async {
    try {
      await (widget.coordinator ?? FirstInstallPermissionCoordinator.instance)
          .run();
    } catch (error, stackTrace) {
      debugPrint('Unable to request device permissions: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
