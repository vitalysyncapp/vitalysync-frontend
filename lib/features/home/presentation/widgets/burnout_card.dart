import 'package:flutter/material.dart';

class BurnoutCard extends StatelessWidget {
  final int score;
  final String status;

  const BurnoutCard({super.key, required this.score, required this.status});

  // Base gradient colors
  List<Color> _baseGradientColors() {
    if (score <= 20) return [Color(0xFF096EB1), Color(0xFF5DADE2)];
    if (score <= 40) {
      return [Color.fromARGB(255, 9, 119, 144), Color(0xFF48C9B0)];
    }
    if (score <= 50) return [Color(0xFF15B658), Color(0xFF58D68D)];
    if (score <= 60) return [Color(0xFFCAA307), Color(0xFFF7DC6F)];
    if (score <= 80) return [Color(0xFFD46E14), Color(0xFFF5B041)];
    if (score <= 90) return [Color(0xFFE74C3C), Color(0xFFFF8C42)];
    return [Color(0xFFE74C3C), Color(0xFFDB3710)];
  }

  // Adjust gradient and glow for dark mode
  List<Color> getGradientColors(bool isDark) {
    final colors = _baseGradientColors();
    if (isDark) return colors.map((c) => c.withValues(alpha: 0.85)).toList();
    return colors;
  }

  IconData getIcon() {
    if (score <= 20) return Icons.sentiment_very_satisfied;
    if (score <= 40) return Icons.sentiment_satisfied;
    if (score <= 60) return Icons.sentiment_neutral;
    if (score <= 80) return Icons.warning_amber_rounded;
    return Icons.error_outline;
  }

  // Glow color for high-risk scores
  Color getGlowColor() {
    if (score > 80) return Colors.redAccent.withValues(alpha: 0.6);
    if (score > 60) return Colors.orangeAccent.withValues(alpha: 0.5);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = getGradientColors(isDark);
    final glowColor = getGlowColor();
    final textColor = Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: glowColor != Colors.transparent
            ? [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Burnout Risk Score',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$score/100',
                style: TextStyle(
                  color: textColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(getIcon(), color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }
}
