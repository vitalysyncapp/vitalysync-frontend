import 'package:flutter/material.dart';

import '../../../../app/main_navigation.dart';
import '../../../../shared/navigation/main_tab.dart';
import '../../../../shared/theme/app_page_style.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color titleColor;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.gradientColors,
    required this.iconColor,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(
          context,
        ).scale(1).clamp(1.0, 1.35);
        final isCompact = constraints.maxWidth < 170;
        final cardPadding = isCompact ? 8.0 : 9.0;
        final iconBoxSize = isCompact ? 28.0 : 30.0;
        final actionSize = isCompact ? 22.0 : 24.0;
        final cardHeight =
            (isCompact ? 62.0 : 66.0) + ((textScale - 1.0) * 10.0);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  SizedBox(width: isCompact ? 7 : 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: isCompact ? 12 : 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 5 : 6),
                  Container(
                    width: actionSize,
                    height: actionSize,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.15) 
                          : Colors.white.withValues(alpha: 0.82),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: titleColor,
                      size: isCompact ? 13 : 14,
                    ),
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

void _goToTab(BuildContext context, MainTab tab) {
  final controller = MainNavigationController.maybeOf(context);
  if (controller != null) {
    controller.onTabSelected(tab);
    return;
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => MainNavigation(initialTab: tab)),
  );
}

void _goToNutritionLog(BuildContext context) {
  final controller = MainNavigationController.maybeOf(context);
  if (controller != null) {
    controller.onNutritionLogRequested();
    return;
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const MainNavigation(
        initialTab: MainTab.nutrition,
        openNutritionLogOnStart: true,
      ),
    ),
  );
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _QuickActionItem(
        icon: Icons.monitor_heart_rounded,
        title: 'Daily check-in',
        gradientColors: isDark
            ? const [Color(0xFF1C2C42), Color(0xFF142032)]
            : const [Color(0xFFE6F6FF), Color(0xFFDDEEFF)],
        iconColor: isDark ? const Color(0xFF7CB8FF) : const Color(0xFF2067C9),
        titleColor: isDark ? const Color(0xFFE6F0FF) : const Color(0xFF15447C),
        onTap: () => _goToTab(context, MainTab.log),
      ),
      _QuickActionItem(
        icon: Icons.restaurant_menu_rounded,
        title: 'Log meal',
        gradientColors: isDark
            ? const [Color(0xFF162D24), Color(0xFF10221A)]
            : const [Color(0xFFE6FBF1), Color(0xFFD7F6E8)],
        iconColor: isDark ? const Color(0xFF67E2A8) : const Color(0xFF178A58),
        titleColor: isDark ? const Color(0xFFE6F8EF) : const Color(0xFF17583B),
        onTap: () => _goToNutritionLog(context),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.18
                  : 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(
            context,
          ).scale(1).clamp(1.0, 1.35);
          final spacing = 8.0;
          final useSingleColumn =
              constraints.maxWidth < 320 || textScale > 1.18;
          final cardWidth = useSingleColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - spacing) / 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  ...actions.map(
                    (action) => SizedBox(
                      width: cardWidth,
                      child: QuickActionCard(
                        icon: action.icon,
                        title: action.title,
                        onTap: action.onTap,
                        gradientColors: action.gradientColors,
                        iconColor: action.iconColor,
                        titleColor: action.titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color titleColor;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.gradientColors,
    required this.iconColor,
    required this.titleColor,
  });
}
