import 'package:flutter/material.dart';

import '../../../dashboard/data/burnout_score_api.dart';
import 'burnout_info_dialog.dart';

class BurnoutCard extends StatelessWidget {
  final int score;
  final String status;
  final BurnoutScoreSnapshot? latestScore;
  final BurnoutPatternSummary? patternSummary;

  const BurnoutCard({
    super.key,
    required this.score,
    required this.status,
    this.latestScore,
    this.patternSummary,
  });

  // Base gradient colors
  List<Color> _baseGradientColors() {
    if (score <= 20) return [Color(0xFF096EB1), Color(0xFF5DADE2)];
    if (score <= 40) {
      return [Color.fromARGB(255, 9, 119, 144), Color(0xFF48C9B0)];
    }
    if (score <= 50) {
      return [Color.fromARGB(255, 102, 192, 17), Color(0xFF58D68D)];
    }
    if (score <= 60) return [Color(0xFFCAA307), Color(0xFFF7DC6F)];
    if (score <= 80) return [Color(0xFFD46E14), Color(0xFFF5B041)];
    if (score <= 90) return [Color(0xFFE74C3C), Color(0xFFFF8C42)];
    return [Color(0xFFE74C3C), Color(0xFFDB3710)];
  }

  // Adjust gradient and glow for dark mode
  List<Color> getGradientColors(bool isDark) {
    final colors = _baseGradientColors();
    if (isDark) {
      return colors
          .map((color) => Color.lerp(const Color(0xFF071827), color, 0.72)!)
          .toList();
    }
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

  void _showInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BurnoutInfoDialog(
          score: score,
          status: status,
          latestScore: latestScore,
          patternSummary: patternSummary,
          accentColors: getGradientColors(isDark),
        );
      },
    );
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: glowColor != Colors.transparent
            ? [
                BoxShadow(
                  color: isDark ? glowColor.withValues(alpha: 0.42) : glowColor,
                  blurRadius: isDark ? 18 : 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ]
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Burnout Risk Score',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'About burnout score',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 15,
                    color: textColor,
                    onPressed: () => _showInfoDialog(context),
                    icon: const Icon(Icons.question_mark_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$score/100',
                style: TextStyle(
                  color: textColor,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(getIcon(), color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: textColor, fontSize: 12.5, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
