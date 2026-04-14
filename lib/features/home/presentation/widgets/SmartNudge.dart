import 'package:flutter/material.dart';

class SmartNudgeCard extends StatelessWidget {
  final String message;
  final String messageSample = "🌟 Remember to take a 5-minute break every hour to maintain focus and reduce burnout risk!";

  const SmartNudgeCard({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Background gradient based on theme
    final backgroundGradient = isDark
        ? LinearGradient(
            colors: [Colors.orange.shade900, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Colors.yellow.shade200, Colors.yellow.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    // Text color adapts
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Smart Nudge",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 12),
          Text(
            messageSample,
            style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
