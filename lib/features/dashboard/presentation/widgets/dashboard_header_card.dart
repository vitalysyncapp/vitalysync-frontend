import 'package:flutter/material.dart';

import '../../../../shared/learning/first_week_learning_service.dart';
import '../../../../shared/widgets/first_week_learning_pill.dart';

class DashboardHeaderCard extends StatelessWidget {
  final FirstWeekLearningState? learningState;

  const DashboardHeaderCard({super.key, this.learningState});

  @override
  Widget build(BuildContext context) {
    final firstWeekState = learningState;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF4A3469), Color(0xFF1B264F)]
              : const [Color.fromARGB(255, 135, 97, 186), Color(0xFF5DB8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF3CB7C8).withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your wellness analytics dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Track your wellness trends, sleep, mood, symptoms, and overall performance.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                if (firstWeekState?.isVisible == true) ...[
                  const SizedBox(height: 9),
                  FirstWeekLearningPill(
                    state: firstWeekState!,
                    message: firstWeekState.headerLabel,
                    onGradient: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          const _HeaderIcon(),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
    );
  }
}
