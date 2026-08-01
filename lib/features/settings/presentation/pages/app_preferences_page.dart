import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/localization/language_change_coordinator.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class AppPreferencesPage extends StatelessWidget {
  const AppPreferencesPage({super.key, this.languageCoordinator});

  final LanguageChangeCoordinator? languageCoordinator;

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
              title: LocalizedText(
                context.l10n.appPreferencesTitle,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
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
                      title: context.l10n.appearanceSection,
                      children: [
                        _buildThemeTile(
                          context: context,
                          prefs: prefs,
                          label: context.l10n.lightMode,
                          subtitle: context.l10n.lightModeDescription,
                          value: ThemeMode.light,
                          icon: Icons.light_mode_rounded,
                          onSelected: preferences.updateThemeMode,
                        ),
                        _buildDivider(context),
                        _buildThemeTile(
                          context: context,
                          prefs: prefs,
                          label: context.l10n.darkMode,
                          subtitle: context.l10n.darkModeDescription,
                          value: ThemeMode.dark,
                          icon: Icons.dark_mode_rounded,
                          onSelected: preferences.updateThemeMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: context.l10n.languageSection,
                      children: [
                        _buildChoiceTile<AppLanguage>(
                          context: context,
                          title: context.l10n.appLanguage,
                          subtitle: context.l10n.appLanguageDescription,
                          currentLabel: context.l10n.languageLabel(
                            prefs.language,
                          ),
                          options: {
                            AppLanguage.english: context.l10n.englishLanguage,
                            AppLanguage.tagalog: context.l10n.tagalogLanguage,
                          },
                          groupValue: prefs.language,
                          onChanged: (language) =>
                              (languageCoordinator ??
                                      LanguageChangeCoordinator.instance)
                                  .changeLanguage(language),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      context: context,
                      title: context.l10n.displaySection,
                      children: [
                        _buildChoiceTile<AppFontSize>(
                          context: context,
                          title: context.l10n.fontSize,
                          subtitle: context.l10n.fontSizeDescription,
                          currentLabel: context.l10n.fontSizeLabel(
                            prefs.fontSize,
                          ),
                          options: {
                            AppFontSize.small: context.l10n.smallSize,
                            AppFontSize.medium: context.l10n.mediumSize,
                            AppFontSize.large: context.l10n.largeSize,
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
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF6F9FF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: pageBorderColor(context),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LocalizedText(
                                  context.l10n.preview,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LocalizedText(
                                  context.l10n.fontPreviewDescription,
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
            child: LocalizedText(
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
                  LocalizedText(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  LocalizedText(
                    subtitle,
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: selected, onChanged: (_) => onSelected(value)),
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
          LocalizedText(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          LocalizedText(
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
                label: LocalizedText(entry.value),
                selected: selected,
                onSelected: (_) => onChanged(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          LocalizedText(
            context.l10n.currentValue(value: currentLabel),
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
