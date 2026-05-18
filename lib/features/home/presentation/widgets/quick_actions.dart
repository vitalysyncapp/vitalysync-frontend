import 'package:flutter/material.dart';

import '../../../../app/main_navigation.dart';
import '../../../../shared/theme/app_page_style.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.gradientColors,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(
          context,
        ).scale(1).clamp(1.0, 1.35);
        final isCompact = constraints.maxWidth < 170;
        final cardPadding = isCompact ? 14.0 : 16.0;
        final iconBoxSize = isCompact ? 40.0 : 44.0;
        final actionSize = isCompact ? 30.0 : 34.0;
        final cardHeight =
            (isCompact ? 136.0 : 144.0) + ((textScale - 1.0) * 28.0);

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: isCompact ? 14.5 : 16,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: isCompact ? 3 : 4),
                            Text(
                              'Open now',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: isCompact ? 12 : 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isCompact ? 8 : 10),
                      Container(
                        width: actionSize,
                        height: actionSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: titleColor,
                          size: isCompact ? 16 : 18,
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
}

void _goToTab(BuildContext context, int index) {
  final controller = MainNavigationController.maybeOf(context);
  if (controller != null) {
    controller.onTabSelected(index);
    return;
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: index)),
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
      builder: (_) =>
          const MainNavigation(initialIndex: 2, openNutritionLogOnStart: true),
    ),
  );
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionItem(
        icon: Icons.monitor_heart_rounded,
        title: 'Daily Check-in',
        gradientColors: const [Color(0xFFE6F6FF), Color(0xFFDDEEFF)],
        iconColor: const Color(0xFF2067C9),
        titleColor: const Color(0xFF15447C),
        subtitleColor: const Color(0xFF55789C),
        onTap: () => _goToTab(context, 1),
      ),
      _QuickActionItem(
        icon: Icons.restaurant_menu_rounded,
        title: 'Log Meal',
        gradientColors: const [Color(0xFFE6FBF1), Color(0xFFD7F6E8)],
        iconColor: const Color(0xFF178A58),
        titleColor: const Color(0xFF17583B),
        subtitleColor: const Color(0xFF4C7C64),
        onTap: () => _goToNutritionLog(context),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.25
                  : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(
            context,
          ).scale(1).clamp(1.0, 1.35);
          final spacing = 12.0;
          final useSingleColumn = constraints.maxWidth < 360 || textScale > 1.1;
          final cardWidth = useSingleColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - spacing) / 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick up a healthy habit in one tap.',
                style: TextStyle(
                  fontSize: 13,
                  color: pageSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: actions
                    .map(
                      (action) => SizedBox(
                        width: cardWidth,
                        child: QuickActionCard(
                          icon: action.icon,
                          title: action.title,
                          onTap: action.onTap,
                          gradientColors: action.gradientColors,
                          iconColor: action.iconColor,
                          titleColor: action.titleColor,
                          subtitleColor: action.subtitleColor,
                        ),
                      ),
                    )
                    .toList(),
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
  final Color subtitleColor;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.gradientColors,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
  });
}
