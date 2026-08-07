import 'package:flutter/material.dart';

import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../activity/data/activity_service.dart';
import '../../../home/data/device_location_service.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class PermissionsSettingsPage extends StatelessWidget {
  const PermissionsSettingsPage({super.key});

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
              title: LocalizedText(
                'Permissions settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
            ),
            body: SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  pageBottomContentPadding(context),
                ),
                children: [
                  _PermissionSection(
                    title: 'Location access',
                    description:
                        'Allow device location to improve local weather and air quality details. When this is off, VitalySync uses a fallback location instead.',
                    settingTitle: 'Use device location',
                    settingDescription:
                        'This setting only affects location-based data inside the app.',
                    currentLabel: prefs.locationPermissionLabel,
                    switchKey: const ValueKey('location-permission-switch'),
                    value: prefs.isLocationAccessEnabled,
                    onChanged: (value) async {
                      if (value) {
                        await DeviceLocationService.enableLocationAccess();
                        return;
                      }

                      await DeviceLocationService.disableLocationAccess();
                    },
                    showSystemSettings:
                        prefs.locationPermissionChoice ==
                        AppPermissionChoice.denied,
                    onOpenSystemSettings: () async {
                      await DeviceLocationService.openSystemLocationSettings();
                    },
                  ),
                  const SizedBox(height: 16),
                  _PermissionSection(
                    title: 'Activity access',
                    description:
                        'Allow activity access so VitalySync can read step counts and support your daily movement goals.',
                    settingTitle: 'Use activity data',
                    settingDescription:
                        'This setting controls step tracking from your phone sensors inside the app.',
                    currentLabel: prefs.activityPermissionLabel,
                    switchKey: const ValueKey('activity-permission-switch'),
                    value: prefs.isActivityAccessEnabled,
                    onChanged: (value) async {
                      if (value) {
                        await ActivityService.instance.enableActivityAccess();
                        return;
                      }

                      await ActivityService.instance.disableActivityAccess();
                    },
                    showSystemSettings:
                        prefs.activityPermissionChoice ==
                        AppPermissionChoice.denied,
                    onOpenSystemSettings: () async {
                      await ActivityService.instance
                          .openSystemActivitySettings();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionSection extends StatelessWidget {
  final String title;
  final String description;
  final String settingTitle;
  final String settingDescription;
  final String currentLabel;
  final Key switchKey;
  final bool value;
  final Future<void> Function(bool value) onChanged;
  final bool showSystemSettings;
  final Future<void> Function() onOpenSystemSettings;

  const _PermissionSection({
    required this.title,
    required this.description,
    required this.settingTitle,
    required this.settingDescription,
    required this.currentLabel,
    required this.switchKey,
    required this.value,
    required this.onChanged,
    required this.showSystemSettings,
    required this.onOpenSystemSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: LocalizedText(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: LocalizedText(
              description,
              style: TextStyle(
                height: 1.45,
                color: pageSecondaryTextColor(context),
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: pageBorderColor(context),
            indent: 18,
            endIndent: 18,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            settingTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: pagePrimaryTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          LocalizedText(
                            settingDescription,
                            style: TextStyle(
                              height: 1.4,
                              color: pageSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(key: switchKey, value: value, onChanged: onChanged),
                  ],
                ),
                const SizedBox(height: 12),
                LocalizedText(
                  'Current: $currentLabel',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (showSystemSettings) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onOpenSystemSettings,
                    child: const LocalizedText('Open system settings'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
