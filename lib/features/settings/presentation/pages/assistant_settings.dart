import 'package:flutter/material.dart';

import '../../../../shared/assistant/overlay_assistant_controller.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';

class AssistantSettings extends StatefulWidget {
  final GlobalKey? tutorialOverlaySwitchKey;

  const AssistantSettings({super.key, this.tutorialOverlaySwitchKey});

  @override
  State<AssistantSettings> createState() => _AssistantSettingsState();
}

class _AssistantSettingsState extends State<AssistantSettings>
    with WidgetsBindingObserver {
  bool? _overlayPermissionGranted;
  bool _pendingAssistantOverlayEnable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStatuses().then((_) {
        if (mounted) {
          _completePendingAssistantOverlayEnable();
        }
      });
    }
  }

  Future<void> _loadPermissionStatuses() async {
    final overlayGranted = await OverlayAssistantController.instance
        .isOverlayPermissionGranted();
    if (!mounted) {
      return;
    }

    setState(() {
      _overlayPermissionGranted = overlayGranted;
    });
  }

  Future<void> _completePendingAssistantOverlayEnable() async {
    if (!_pendingAssistantOverlayEnable || _overlayPermissionGranted != true) {
      return;
    }

    _pendingAssistantOverlayEnable = false;
    await AppPreferencesController.instance.updateAssistantOverlayEnabled(true);
    await OverlayAssistantController.instance.syncSettings(
      AppPreferencesController.instance.notifier.value,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Floating assistant is ready and will appear when you leave VitalySync.',
        ),
      ),
    );
  }

  Future<void> _handleAssistantOverlayToggle(
    AppPreferencesState prefs,
    bool value,
  ) async {
    if (!value) {
      await AppPreferencesController.instance.updateAssistantOverlayEnabled(
        false,
      );
      await OverlayAssistantController.instance.stopOverlayService();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Floating assistant is turned off outside the app.'),
        ),
      );
      return;
    }

    final granted = await OverlayAssistantController.instance
        .isOverlayPermissionGranted();
    if (!granted) {
      if (!mounted) {
        return;
      }
      _pendingAssistantOverlayEnable = true;
      final prompted = await OverlayAssistantController.instance
          .ensurePermissionWithPrompt(context);
      if (!prompted && mounted) {
        _pendingAssistantOverlayEnable = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Turn on the Android overlay permission, then try enabling the assistant again.',
            ),
          ),
        );
      }
      await _loadPermissionStatuses();
      return;
    }

    await AppPreferencesController.instance.updateAssistantOverlayEnabled(true);
    await OverlayAssistantController.instance.syncSettings(
      prefs.copyWith(assistantOverlayEnabled: true),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Floating assistant is ready and will appear when you leave VitalySync.',
        ),
      ),
    );
  }

  String _assistantOverlaySubtitle(AppPreferencesState prefs) {
    if (!prefs.assistantOverlayEnabled) {
      return 'Show the assistant as a chat-head above other apps on Android';
    }

    if (_overlayPermissionGranted == false) {
      return 'Overlay permission is still required before the assistant can appear outside the app';
    }

    return 'Enabled. The assistant can appear when you leave VitalySync';
  }

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesController.instance;

    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: preferences.notifier,
      builder: (context, prefs, _) {
        return Container(
          decoration: buildPageDecoration(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: pagePrimaryTextColor(context),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Assistant',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  pageBottomContentPadding(context),
                ),
                child: _buildSectionCard(
                  context: context,
                  title: 'Floating assistant',
                  children: [
                    KeyedSubtree(
                      key: widget.tutorialOverlaySwitchKey,
                      child: _buildSwitchTile(
                        context: context,
                        icon: Icons.bubble_chart_rounded,
                        iconBg: const Color(0xFFE5F7F0),
                        iconColor: const Color(0xFF1F9D63),
                        title: 'Allow assistant outside app',
                        subtitle: _assistantOverlaySubtitle(prefs),
                        value: prefs.assistantOverlayEnabled,
                        onChanged: (value) =>
                            _handleAssistantOverlayToggle(prefs, value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool value) onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? pagePrimaryTextColor(context)
                        : pageSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: pageSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}
