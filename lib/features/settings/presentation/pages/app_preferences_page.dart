import 'package:flutter/material.dart';

import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';

class AppPreferencesPage extends StatelessWidget {
  const AppPreferencesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesController.instance;

    return ValueListenableBuilder<AppPreferencesState>(
      valueListenable: preferences.notifier,
      builder: (context, prefs, _) {
        final textColor = pagePrimaryTextColor(context);
        final secondaryTextColor = pageSecondaryTextColor(context);

        return Container(
          decoration: buildPageDecoration(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: textColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'App Preferences',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                child: Column(
                  children: [
                    _buildSectionCard(
                      context: context,
                      title: 'Appearance',
                      children: [
                        _buildThemeTile(
                          context: context,
                          prefs: prefs,
                          label: 'Light Mode',
                          subtitle: 'Bright surfaces and default daytime look',
                          value: ThemeMode.light,
                          icon: Icons.light_mode_rounded,
                          onSelected: preferences.updateThemeMode,
                        ),
                        _buildDivider(context),
                        _buildThemeTile(
                          context: context,
                          prefs: prefs,
                          label: 'Dark Mode',
                          subtitle: 'Low-light colors for evening use',
                          value: ThemeMode.dark,
                          icon: Icons.dark_mode_rounded,
                          onSelected: preferences.updateThemeMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: 'Language',
                      children: [
                        _buildChoiceTile<AppLanguage>(
                          context: context,
                          title: 'App Language',
                          subtitle:
                              'Used for shell display like greetings and date formatting',
                          currentLabel: prefs.languageLabel,
                          options: const {
                            AppLanguage.english: 'English',
                            AppLanguage.filipino: 'Filipino',
                          },
                          groupValue: prefs.language,
                          onChanged: preferences.updateLanguage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: 'Display',
                      children: [
                        _buildChoiceTile<AppFontSize>(
                          context: context,
                          title: 'Font Size',
                          subtitle:
                              'Small is a bit smaller, medium matches the default UI, and large is a bit bigger',
                          currentLabel: prefs.fontSizeLabel,
                          options: const {
                            AppFontSize.small: 'Small',
                            AppFontSize.medium: 'Medium',
                            AppFontSize.large: 'Large',
                          },
                          groupValue: prefs.fontSize,
                          onChanged: preferences.updateFontSize,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFF6F9FF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: pageBorderColor(context),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preview',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'VitalySync will scale text throughout the app using your selected size.',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.05,
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

  Widget _buildThemeTile({
    required BuildContext context,
    required AppPreferencesState prefs,
    required String label,
    required String subtitle,
    required ThemeMode value,
    required IconData icon,
    required Future<void> Function(ThemeMode) onSelected,
  }) {
    final selected = prefs.themeMode == value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onSelected(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : pageSecondaryTextColor(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: selected,
              onChanged: (_) => onSelected(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceTile<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String currentLabel,
    required Map<T, String> options,
    required T groupValue,
    required Future<void> Function(T) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.entries.map((entry) {
              final selected = entry.key == groupValue;

              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => onChanged(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Current: $currentLabel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
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
