import 'package:flutter/material.dart';

import '../learning/first_week_learning_service.dart';
import '../theme/app_page_style.dart';

class FirstWeekLearningPill extends StatelessWidget {
  final FirstWeekLearningState state;
  final String message;
  final bool onGradient;
  final IconData icon;
  final int maxLines;

  const FirstWeekLearningPill({
    super.key,
    required this.state,
    required this.message,
    this.onGradient = false,
    this.icon = Icons.hourglass_top_rounded,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isVisible) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = onGradient
        ? Colors.white
        : isDark
        ? const Color(0xFFB9F6CA)
        : const Color(0xFF08765D);
    final backgroundColor = onGradient
        ? Colors.white.withValues(alpha: 0.16)
        : foregroundColor.withValues(alpha: isDark ? 0.12 : 0.10);
    final borderColor = onGradient
        ? Colors.white.withValues(alpha: 0.28)
        : foregroundColor.withValues(alpha: 0.18);

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: foregroundColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              message,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onGradient
                    ? foregroundColor.withValues(alpha: 0.94)
                    : pagePrimaryTextColor(context),
                fontSize: 10.8,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
