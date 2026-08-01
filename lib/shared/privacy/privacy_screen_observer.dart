import 'package:flutter/material.dart';

import '../preferences/app_preferences.dart';
import 'package:vitalysync/l10n/localized_text.dart';

/// Pushes a branded privacy overlay when the app leaves the foreground so that
/// the Android/iOS app‐switcher thumbnail does not reveal wellness data.
///
/// Only active when [AppPreferencesState.hideSensitiveContent] is `true`.
///
/// Attach an instance as a [WidgetsBindingObserver] and call [dispose] when no
/// longer needed.
class PrivacyScreenObserver with WidgetsBindingObserver {
  PrivacyScreenObserver._();

  static final PrivacyScreenObserver instance = PrivacyScreenObserver._();

  OverlayEntry? _overlayEntry;
  bool _isShowing = false;

  /// Call once during app init to start observing lifecycle events.
  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Call during teardown.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeOverlay();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = AppPreferencesController.instance.notifier.value;
    if (!prefs.hideSensitiveContent) {
      _removeOverlay();
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _showOverlay();
        break;
      case AppLifecycleState.resumed:
        _removeOverlay();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _showOverlay() {
    if (_isShowing) return;

    final overlay = _findOverlay();
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => const _PrivacyScreen(),
    );
    overlay.insert(_overlayEntry!);
    _isShowing = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  OverlayState? _findOverlay() {
    try {
      final context = WidgetsBinding
          .instance.rootElement;
      if (context == null) return null;
      return Overlay.maybeOf(context, rootOverlay: true);
    } catch (_) {
      return null;
    }
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF08131D) : const Color(0xFFF0F8FF),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 72,
              height: 72,
              errorBuilder: (_, e, s) => Icon(
                Icons.spa_rounded,
                size: 56,
                color: isDark
                    ? const Color(0xFF1EAD83)
                    : const Color(0xFF1F9D63),
              ),
            ),
            const SizedBox(height: 16),
            LocalizedText(
              'VitalySync',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
