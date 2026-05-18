import 'package:flutter/material.dart';

import '../../../home/data/device_location_service.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';

class LocationSettingsPage extends StatelessWidget {
  const LocationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesController.instance;

    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: preferences.notifier,
      builder: (context, prefs, _) {
        final actionAvailable =
            prefs.locationPermissionChoice ==
            AppLocationPermissionChoice.denied;

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
                'Location Settings',
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
                  _SectionCard(
                    title: 'Location Access',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Text(
                          'Allow device location to improve local weather and air quality details. When this is off, VitalySync uses a fallback location instead.',
                          style: TextStyle(
                            height: 1.45,
                            color: pageSecondaryTextColor(context),
                          ),
                        ),
                      ),
                      _divider(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Use Device Location',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: pagePrimaryTextColor(context),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'This setting only affects location-based data inside the app.',
                                        style: TextStyle(
                                          height: 1.4,
                                          color: pageSecondaryTextColor(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Switch(
                                  value: prefs.isLocationAccessEnabled,
                                  onChanged: (value) async {
                                    if (value) {
                                      await DeviceLocationService.enableLocationAccess();
                                      return;
                                    }

                                    await DeviceLocationService.disableLocationAccess();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Current: ${prefs.locationPermissionLabel}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (actionAvailable) ...[
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  DeviceLocationService.openSystemLocationSettings();
                                },
                                child: const Text('Open System Settings'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: pageBorderColor(context),
      indent: 18,
      endIndent: 18,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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
}
