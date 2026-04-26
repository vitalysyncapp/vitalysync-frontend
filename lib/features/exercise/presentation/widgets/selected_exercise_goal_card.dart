import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/exercise_goal_model.dart';

class SelectedExerciseGoalCard extends StatelessWidget {
  final ExerciseGoalModel goal;
  final double distanceMeters;
  final bool isSaving;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  const SelectedExerciseGoalCard({
    super.key,
    required this.goal,
    required this.distanceMeters,
    required this.isSaving,
    required this.onDone,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.isDistanceBased
        ? goal.progressForDistance(distanceMeters)
        : goal.isCompleted
        ? 1.0
        : 0.0;
    final progressPercent = (progress * 100).round();
    final canMarkDone =
        goal.canManualComplete && (!goal.isDistanceBased || progress >= 1.0);
    final accent = goal.isCompleted
        ? const Color(0xFF16A34A)
        : goal.isNoneToday
        ? const Color(0xFF64748B)
        : const Color(0xFF1EAD83);

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  goal.isCompleted
                      ? Icons.check_circle_rounded
                      : goal.isNoneToday
                      ? Icons.self_improvement_rounded
                      : Icons.flag_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GoalDetailRow(label: 'Target', value: goal.targetLabel()),
          const SizedBox(height: 10),
          _GoalDetailRow(
            label: goal.isDistanceBased ? 'Progress' : 'Completion',
            value: goal.isDistanceBased
                ? '${_formatDistance(distanceMeters)} / ${goal.targetLabel()}'
                : goal.isCompleted
                ? 'Done'
                : 'Tap Done when finished',
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: pageBorderColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              goal.isNoneToday ? 'Saved' : '$progressPercent%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: pagePrimaryTextColor(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isSaving || !canMarkDone ? null : onDone,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1FB489),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSaving || goal.isCompleted ? null : onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: pagePrimaryTextColor(context),
                    side: BorderSide(color: pageBorderColor(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (goal.isDistanceBased && !goal.isCompleted) ...[
            const SizedBox(height: 10),
            Text(
              progress >= 1.0
                  ? 'Distance reached. You can mark it done now.'
                  : 'Walking and jogging complete automatically when the target distance is reached.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: pageSecondaryTextColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel() {
    if (goal.isNoneToday) {
      return 'None today saved';
    }

    if (goal.isCompleted) {
      return 'Completed';
    }

    if (goal.isDistanceBased) {
      return 'Auto-tracked by step distance';
    }

    return 'Manual completion';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return '${meters.round()} m';
  }
}

class _GoalDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _GoalDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: pageSecondaryTextColor(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ),
      ],
    );
  }
}
