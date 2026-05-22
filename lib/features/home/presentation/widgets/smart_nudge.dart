import 'package:flutter/material.dart';

class SmartNudgeCard extends StatelessWidget {
  final String message;

  const SmartNudgeCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF7C2D12), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFDE68A), Color(0xFFFDE68A), Color(0xFFFFF7CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final textColor = isDark ? Colors.white : const Color(0xFF3F2A00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.amber.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Smart Nudge",
            style: TextStyle(
              fontSize: 12.5,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              color: textColor,
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
