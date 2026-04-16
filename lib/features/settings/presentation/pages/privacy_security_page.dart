import 'package:flutter/material.dart';

import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

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
                'Privacy & Security',
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
                    title: 'Privacy Controls',
                    children: [
                      _PrivacySwitchTile(
                        title: 'Hide Sensitive Content',
                        subtitle:
                            'Softens wellness details on shared or public screens',
                        value: prefs.hideSensitiveContent,
                        onChanged: preferences.updateHideSensitiveContent,
                      ),
                      _divider(context),
                      _PrivacySwitchTile(
                        title: 'Biometric Lock',
                        subtitle:
                            'Keep a local lock preference saved for future secure unlock support',
                        value: prefs.biometricLockEnabled,
                        onChanged: preferences.updateBiometricLockEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'About This Section',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Text(
                          'These settings are stored locally on this device for now. They help us keep privacy behavior consistent even before deeper account security is connected.',
                          style: TextStyle(
                            height: 1.45,
                            color: pageSecondaryTextColor(context),
                          ),
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

  const _SectionCard({
    required this.title,
    required this.children,
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
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.05,
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

class _PrivacySwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  const _PrivacySwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.4,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
