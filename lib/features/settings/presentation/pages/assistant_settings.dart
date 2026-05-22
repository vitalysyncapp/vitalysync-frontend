import 'package:flutter/material.dart';

import '../../../../shared/assistant/overlay_assistant_controller.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';

class AssistantSettings extends StatefulWidget {
  const AssistantSettings({super.key});

  @override
  State<AssistantSettings> createState() => _AssistantSettingsState();
}

class _AssistantSettingsState extends State<AssistantSettings>
    with WidgetsBindingObserver {
  bool? _overlayPermissionGranted;
  bool? _exactAlarmPermissionGranted;
  bool _pendingAssistantOverlayEnable = false;
  bool _pendingAssistantAutoShowEnable = false;

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
          _completePendingAssistantAutoShowEnable();
        }
      });
    }
  }

  Future<void> _loadPermissionStatuses() async {
    final overlayGranted = await OverlayAssistantController.instance
        .isOverlayPermissionGranted();
    final exactAlarmGranted = await OverlayAssistantController.instance
        .canScheduleExactAlarms();
    if (!mounted) {
      return;
    }

    setState(() {
      _overlayPermissionGranted = overlayGranted;
      _exactAlarmPermissionGranted = exactAlarmGranted;
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

  Future<void> _completePendingAssistantAutoShowEnable() async {
    if (!_pendingAssistantAutoShowEnable) {
      return;
    }

    if (_exactAlarmPermissionGranted != true) {
      _pendingAssistantAutoShowEnable = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Turn on Alarms & reminders access, then try enabling auto appear again.',
          ),
        ),
      );
      return;
    }

    _pendingAssistantAutoShowEnable = false;
    await AppPreferencesController.instance
        .updateAssistantOverlayAutoShowEnabled(true);
    await OverlayAssistantController.instance.syncSettings(
      AppPreferencesController.instance.notifier.value,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto appear is scheduled for your selected time.'),
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

  Future<void> _handleAssistantAutoShowToggle(bool value) async {
    if (value) {
      final canScheduleExactAlarms = await OverlayAssistantController.instance
          .canScheduleExactAlarms();
      if (!canScheduleExactAlarms) {
        if (!mounted) {
          return;
        }

        _pendingAssistantAutoShowEnable = true;
        final prompted = await OverlayAssistantController.instance
            .ensureExactAlarmPermissionWithPrompt(context);
        if (!prompted && mounted) {
          _pendingAssistantAutoShowEnable = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Auto appear needs Alarms & reminders access to run on schedule.',
              ),
            ),
          );
        }
        await _loadPermissionStatuses();
        return;
      }
    } else {
      _pendingAssistantAutoShowEnable = false;
    }

    await AppPreferencesController.instance
        .updateAssistantOverlayAutoShowEnabled(value);
    await OverlayAssistantController.instance.syncSettings(
      AppPreferencesController.instance.notifier.value,
    );
  }

  Future<void> _pickAssistantOverlayTime(String currentValue) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDayFromString(currentValue),
    );
    if (picked == null || !mounted) {
      return;
    }

    await AppPreferencesController.instance.updateAssistantOverlayAutoShowTime(
      _formatTimeOfDay(picked),
    );
    await OverlayAssistantController.instance.syncSettings(
      AppPreferencesController.instance.notifier.value,
    );
  }

  TimeOfDay _timeOfDayFromString(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return TimeOfDay(
      hour: (hour ?? 0).clamp(0, 23).toInt(),
      minute: (minute ?? 0).clamp(0, 59).toInt(),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _displayTime(BuildContext context, String value) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(_timeOfDayFromString(value));
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

  String _assistantAutoShowSubtitle(AppPreferencesState prefs) {
    if (!prefs.assistantOverlayEnabled) {
      return 'Enable the floating assistant first';
    }

    if (_exactAlarmPermissionGranted == false) {
      return 'Allow Android Alarms & reminders so it can appear at the scheduled time';
    }

    return prefs.assistantOverlayAutoShowEnabled
        ? 'Daily outside-app assistant after ${_displayTime(context, prefs.assistantOverlayAutoShowTime)}, including when you unlock later'
        : 'Automatically surface the assistant outside the app each morning';
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
                  title: 'Floating Assistant',
                  children: [
                    _buildSwitchTile(
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
                    _buildDivider(context),
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.alarm_on_rounded,
                      iconBg: const Color(0xFFE8EDFF),
                      iconColor: const Color(0xFF5563F5),
                      title: 'Auto appear outside app',
                      subtitle: _assistantAutoShowSubtitle(prefs),
                      value:
                          prefs.assistantOverlayEnabled &&
                          prefs.assistantOverlayAutoShowEnabled,
                      enabled: prefs.assistantOverlayEnabled,
                      onChanged: _handleAssistantAutoShowToggle,
                    ),
                    _buildDivider(context),
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.schedule_rounded,
                      iconBg: const Color(0xFFFFF5D8),
                      iconColor: const Color(0xFFD79B00),
                      title: 'Auto appear time',
                      subtitle: _displayTime(
                        context,
                        prefs.assistantOverlayAutoShowTime,
                      ),
                      enabled:
                          prefs.assistantOverlayEnabled &&
                          prefs.assistantOverlayAutoShowEnabled,
                      onTap: () => _pickAssistantOverlayTime(
                        prefs.assistantOverlayAutoShowTime,
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: enabled
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFFCBD5E1),
              size: 28,
            ),
          ],
        ),
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

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: pageBorderColor(context),
      indent: 18,
      endIndent: 18,
    );
  }
}
