import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final animationDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 320);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: pageCardShadow(context),
          border: Border.all(color: pageBorderColor(context)),
        ),
        child: AppSkeleton(
          enabled: isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: animationDuration,
                    child: Icon(
                      icon,
                      key: ValueKey<IconData>(icon),
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: animationDuration,
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    alignment: Alignment.centerLeft,
                    scale: Tween<double>(
                      begin: 0.92,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  value,
                  key: ValueKey<String>(value),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
