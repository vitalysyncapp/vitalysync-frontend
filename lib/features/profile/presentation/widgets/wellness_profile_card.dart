import 'package:flutter/material.dart';

class WellnessProfileCard extends StatelessWidget {
  final String lifestyleType; // Sedentary, Active, etc.
  final String occupationalStatus; // Student, Working Professional, etc.
  final String workIntensity; // Low, Medium, High
  final String waterGoal; // e.g. 2.5 L
  final String exerciseTarget; // e.g. 5 days/week

  const WellnessProfileCard({
    Key? key,
    required this.lifestyleType,
    required this.occupationalStatus,
    required this.workIntensity,
    required this.waterGoal,
    required this.exerciseTarget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8AA4D6).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Wellness Profile",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A56),
            ),
          ),
          const SizedBox(height: 18),

          _rowItem("Lifestyle Type", lifestyleType),
          const SizedBox(height: 14),

          _rowItem("Occupational Status", occupationalStatus),
          const SizedBox(height: 14),

          _rowItemWithBadge("Work Intensity", workIntensity),
          const SizedBox(height: 14),

          _rowItem("Daily Water Goal", waterGoal),
          const SizedBox(height: 14),

          _rowItem("Exercise Target", exerciseTarget),
        ],
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF5B6B7F),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF102A56),
          ),
        ),
      ],
    );
  }

  Widget _rowItemWithBadge(String label, String value) {
    Color badgeColor;

    switch (value.toLowerCase()) {
      case 'high':
        badgeColor = const Color(0xFFFFE5D0);
        break;
      case 'medium':
        badgeColor = const Color(0xFFFFF4CC);
        break;
      default:
        badgeColor = const Color(0xFFE6F4EA);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            color: Color(0xFF5B6B7F),
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
              color: value.toLowerCase() == 'high'
                  ? Colors.red
                  : value.toLowerCase() == 'medium'
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}