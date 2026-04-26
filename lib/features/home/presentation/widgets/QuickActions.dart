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
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 160;
          final cardPadding = isCompact ? 12.0 : 16.0;
          final iconBoxSize = isCompact ? 40.0 : 44.0;
          final actionSize = isCompact ? 28.0 : 32.0;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              height: isCompact ? 122 : 128,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.last.withOpacity(0.18),
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
                        color: Colors.white.withOpacity(0.72),
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
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                        SizedBox(width: isCompact ? 6 : 8),
                        Container(
                          width: actionSize,
                          height: actionSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.82),
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
      ),
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
      builder: (_) => const MainNavigation(
        initialIndex: 2,
        openNutritionLogOnStart: true,
      ),
    ),
  );
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackCards = constraints.maxWidth < 330;

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
              if (stackCards)
                Column(
                  children: [
                    _QuickActionRow(
                      child: QuickActionCard(
                        icon: Icons.monitor_heart_rounded,
                        title: 'Daily Check-in',
                        gradientColors: const [
                          Color(0xFFE6F6FF),
                          Color(0xFFDDEEFF),
                        ],
                        iconColor: const Color(0xFF2067C9),
                        titleColor: const Color(0xFF15447C),
                        subtitleColor: const Color(0xFF55789C),
                        onTap: () => _goToTab(context, 1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _QuickActionRow(
                      child: QuickActionCard(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'Log Meal',
                        gradientColors: const [
                          Color(0xFFE6FBF1),
                          Color(0xFFD7F6E8),
                        ],
                        iconColor: const Color(0xFF178A58),
                        titleColor: const Color(0xFF17583B),
                        subtitleColor: const Color(0xFF4C7C64),
                        onTap: () => _goToNutritionLog(context),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    QuickActionCard(
                      icon: Icons.monitor_heart_rounded,
                      title: 'Daily Check-in',
                      gradientColors: const [
                        Color(0xFFE6F6FF),
                        Color(0xFFDDEEFF),
                      ],
                      iconColor: const Color(0xFF2067C9),
                      titleColor: const Color(0xFF15447C),
                      subtitleColor: const Color(0xFF55789C),
                      onTap: () => _goToTab(context, 1),
                    ),
                    QuickActionCard(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Log Meal',
                      gradientColors: const [
                        Color(0xFFE6FBF1),
                        Color(0xFFD7F6E8),
                      ],
                      iconColor: const Color(0xFF178A58),
                      titleColor: const Color(0xFF17583B),
                      subtitleColor: const Color(0xFF4C7C64),
                      onTap: () => _goToNutritionLog(context),
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

class _QuickActionRow extends StatelessWidget {
  final Widget child;

  const _QuickActionRow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(children: [child]);
  }
}
