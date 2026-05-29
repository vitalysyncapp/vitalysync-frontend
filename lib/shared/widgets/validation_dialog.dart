import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_page_style.dart';

enum ValidationDialogType { success, error, warning, connection }

class ValidationDialog extends StatefulWidget {
  const ValidationDialog({
    super.key,
    required this.message,
    required this.type,
    this.title,
    this.duration = const Duration(milliseconds: 1500),
  });

  final String message;
  final ValidationDialogType type;
  final String? title;
  final Duration duration;

  static Future<void> show(
    BuildContext context, {
    required String message,
    required ValidationDialogType type,
    String? title,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    if (!context.mounted) {
      return Future<void>.value();
    }

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) {
        return ValidationDialog(
          message: message,
          type: type,
          title: title,
          duration: duration,
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ValidationDialog> createState() => _ValidationDialogState();
}

class _ValidationDialogState extends State<ValidationDialog> {
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissing || !mounted) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) {
      return;
    }

    _isDismissing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _ValidationDialogSpec.forType(widget.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF132235).withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: spec.accent.withValues(alpha: 0.24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: spec.accent.withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(spec.icon, color: spec.accent, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title ?? spec.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: pagePrimaryTextColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: pageSecondaryTextColor(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidationDialogSpec {
  const _ValidationDialogSpec({
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color accent;

  static _ValidationDialogSpec forType(ValidationDialogType type) {
    switch (type) {
      case ValidationDialogType.success:
        return const _ValidationDialogSpec(
          title: 'Success',
          icon: Icons.check_circle_rounded,
          accent: Color(0xFF1EAD83),
        );
      case ValidationDialogType.error:
        return const _ValidationDialogSpec(
          title: 'Something went wrong',
          icon: Icons.error_outline_rounded,
          accent: Color(0xFFE53935),
        );
      case ValidationDialogType.warning:
        return const _ValidationDialogSpec(
          title: 'Check details',
          icon: Icons.report_problem_outlined,
          accent: Color(0xFFF59E0B),
        );
      case ValidationDialogType.connection:
        return const _ValidationDialogSpec(
          title: 'Connection issue',
          icon: Icons.wifi_off_rounded,
          accent: Color(0xFF2563EB),
        );
    }
  }
}
