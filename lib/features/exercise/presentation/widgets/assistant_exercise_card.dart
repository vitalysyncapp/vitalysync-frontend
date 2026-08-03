import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/exercise_icon_mapper.dart';
import '../../data/exercise_recommendation_model.dart';
import 'package:vitalysync/l10n/localized_text.dart';

IconData assistantExerciseIconFor(ExerciseRecommendationModel recommendation) {
  return exerciseIconFor(
    name: recommendation.exerciseName,
    category: recommendation.exerciseCategory,
  );
}

class AssistantExerciseCard extends StatelessWidget {
  final List<ExerciseRecommendationModel> recommendations;
  final bool isSaving;
  final ValueChanged<ExerciseRecommendationModel> onChoose;

  const AssistantExerciseCard({
    super.key,
    required this.recommendations,
    required this.isSaving,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final visibleRecommendations = recommendations.take(5).toList();

    return _AssistantCardShell(
      icon: Icons.fitness_center_rounded,
      title: 'Exercise recommendation',
      subtitle: 'Choose what fits your energy today',
      child: Column(
        children: [
          ...visibleRecommendations.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecommendationTile(
                recommendation: item,
                isSaving: isSaving,
                onTap: () => onChoose(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final ExerciseRecommendationModel recommendation;
  final bool isSaving;
  final VoidCallback onTap;

  const _RecommendationTile({
    required this.recommendation,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNone = recommendation.isNoneToday;
    final accent = isNone ? const Color(0xFF64748B) : const Color(0xFF1EAD83);

    return InkWell(
      onTap: isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isNone ? 0.08 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isNone
                    ? Icons.self_improvement_rounded
                    : assistantExerciseIconFor(recommendation),
                color: accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedText(
                          recommendation.exerciseName,
                          translate: false,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: pagePrimaryTextColor(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      LocalizedText(
                        recommendation.targetLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LocalizedText(
                    recommendation.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: pageSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _AssistantCardShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _AssistantCardShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1FB489), Color(0xFF5DB8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    LocalizedText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
