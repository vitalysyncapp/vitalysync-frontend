import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

class WellnessProfileCard extends StatelessWidget {
  final String lifestyleType;
  final String currentRole;
  final String workIntensity;
  final String waterGoal;
  final String exerciseTarget;

  const WellnessProfileCard({
    super.key,
    required this.lifestyleType,
    required this.currentRole,
    required this.workIntensity,
    required this.waterGoal,
    required this.exerciseTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wellness Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 18),
          _rowItem(context, 'Lifestyle Type', lifestyleType),
          const SizedBox(height: 14),
          _rowItem(context, 'Current Role', currentRole),
          const SizedBox(height: 14),
          _rowItemWithBadge(context, 'Work Intensity', workIntensity),
          const SizedBox(height: 14),
          _rowItem(context, 'Daily Water Goal', waterGoal),
          const SizedBox(height: 14),
          _rowItem(context, 'Exercise Target', exerciseTarget),
        ],
      ),
    );
  }

  Widget _rowItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            color: pageSecondaryTextColor(context),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowItemWithBadge(BuildContext context, String label, String value) {
    Color badgeColor;
    Color textColor;

    switch (value.toLowerCase()) {
      case 'high':
        badgeColor = const Color(0xFFFFE5D0);
        textColor = Colors.red;
        break;
      case 'medium':
        badgeColor = const Color(0xFFFFF4CC);
        textColor = Colors.orange;
        break;
      default:
        badgeColor = const Color(0xFFE6F4EA);
        textColor = Colors.green;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            color: pageSecondaryTextColor(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
