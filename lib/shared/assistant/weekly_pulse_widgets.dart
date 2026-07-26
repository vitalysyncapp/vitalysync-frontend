part of 'floating_smart_nudge_assistant.dart';

class _AssistantCheckInCard extends StatelessWidget {
  final bool isLoading;
  final bool isSaving;
  final CheckInStatus? status;
  final CheckInDraft draft;
  final bool isEditing;
  final String exerciseGoalLabel;
  final ValueChanged<CheckInDraft> onChanged;
  final Future<void> Function() onSave;
  final VoidCallback onRedo;

  const _AssistantCheckInCard({
    required this.isLoading,
    required this.isSaving,
    required this.status,
    required this.draft,
    required this.isEditing,
    required this.exerciseGoalLabel,
    required this.onChanged,
    required this.onSave,
    required this.onRedo,
  });

  bool get _showWeeklyQuestions => status?.requiredMode == CheckInMode.weekly;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _AssistantLoadingCard();
    final currentStatus = status;
    if (currentStatus == null) {
      return _AssistantCheckInMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Check-in unavailable',
        message:
            'Reconnect and refresh the assistant to load today\'s check-in.',
      );
    }
    if (currentStatus.isComplete && !isEditing) {
      return _AssistantCheckInSavedView(
        isWeekly: _showWeeklyQuestions,
        isOffline: currentStatus.isOffline,
        nextDueDate: currentStatus.schedule.nextDueDate,
        onRedo: onRedo,
      );
    }

    final missing = draft.validationErrors(currentStatus.requiredMode);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _showWeeklyQuestions
                    ? Icons.calendar_view_week_rounded
                    : Icons.bolt_rounded,
                color: primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showWeeklyQuestions
                          ? currentStatus.schedule.isOverdue
                                ? 'Weekly pulse due'
                                : 'Weekly pulse'
                          : 'Short daily check-in',
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showWeeklyQuestions
                          ? 'Today includes the usual nine inputs plus five weekly reflections. It cannot be skipped, but it follows you to the next day you return.'
                          : 'The same nine inputs as the Log page, sized for the assistant.',
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LogWidgets(
          showWeeklyQuestions: _showWeeklyQuestions,
          sleepHours: draft.sleepHours,
          sleepQuality: draft.sleepQuality,
          moodIndex: draft.moodIndex,
          energyLevel: draft.energyLevel,
          hydration: draft.hydrationLiters,
          workloadHoursBand: draft.workloadHoursBand,
          perceivedStressLevel: draft.perceivedPressureLevel,
          breakQualityLevel: draft.recoveryRestLevel,
          dailyDetachmentLevel: draft.detachmentLevel,
          dailyFocusLevel: draft.productivityFocusLevel,
          dailyAccomplishmentLevel: draft.accomplishmentLevel,
          selectedExercises: draft.exerciseNames,
          selectedSymptoms: draft.symptomNames,
          selectedHabits: draft.habitNames,
          sleepLabels: CheckInFormOptions.sleepLabels,
          sleepStars: CheckInFormOptions.sleepStars,
          moods: CheckInFormOptions.moods,
          exercises: LogApi.exerciseOptions,
          symptoms: CheckInFormOptions.symptoms,
          habits: CheckInFormOptions.habits,
          exerciseGoalLabel: exerciseGoalLabel,
          workloadOptions: LogApi.workloadHoursBandOptions,
          onSleepChanged: (value) =>
              onChanged(draft.copyWith(sleepHours: value)),
          onSleepQualityChanged: (value) =>
              onChanged(draft.copyWith(sleepQuality: value)),
          onMoodChanged: (value) => onChanged(draft.copyWith(moodIndex: value)),
          onEnergyChanged: (value) =>
              onChanged(draft.copyWith(energyLevel: value)),
          onHydrationAdd: (value) => onChanged(
            draft.copyWith(
              hydrationLiters: (draft.hydrationLiters + value)
                  .clamp(0, 10)
                  .toDouble(),
            ),
          ),
          onHydrationSubtract: () => onChanged(
            draft.copyWith(
              hydrationLiters: (draft.hydrationLiters - 0.25)
                  .clamp(0, 10)
                  .toDouble(),
            ),
          ),
          onHydrationReset: () => onChanged(draft.copyWith(hydrationLiters: 0)),
          onWorkloadChanged: (value) =>
              onChanged(draft.copyWith(workloadHoursBand: value)),
          onPerceivedStressChanged: (value) =>
              onChanged(draft.copyWith(perceivedPressureLevel: value)),
          onBreakQualityChanged: (value) =>
              onChanged(draft.copyWith(recoveryRestLevel: value)),
          onDailyDetachmentChanged: (value) =>
              onChanged(draft.copyWith(detachmentLevel: value)),
          onDailyFocusChanged: (value) =>
              onChanged(draft.copyWith(productivityFocusLevel: value)),
          onDailyAccomplishmentChanged: (value) =>
              onChanged(draft.copyWith(accomplishmentLevel: value)),
          onExerciseToggle: (value) => onChanged(
            draft.copyWith(
              exerciseNames: _toggleSelection(draft.exerciseNames, value),
            ),
          ),
          onSymptomToggle: (value) => onChanged(
            draft.copyWith(
              symptomNames: _toggleSelection(draft.symptomNames, value),
            ),
          ),
          onHabitToggle: (value) => onChanged(
            draft.copyWith(
              habitNames: _toggleSelection(draft.habitNames, value),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSaving || missing.isNotEmpty ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              isSaving
                  ? 'Saving...'
                  : _showWeeklyQuestions
                  ? 'Save weekly pulse and check-in'
                  : 'Save daily check-in',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Still needed: ${missing.join(', ')}',
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  static Set<String> _toggleSelection(Set<String> current, String value) {
    final updated = Set<String>.from(current);
    if (value == 'None') {
      if (updated.contains('None')) {
        updated.remove('None');
      } else {
        updated
          ..clear()
          ..add('None');
      }
      return updated;
    }
    updated.remove('None');
    if (!updated.add(value)) updated.remove(value);
    return updated;
  }
}

class _AssistantCheckInSavedView extends StatelessWidget {
  final bool isWeekly;
  final bool isOffline;
  final String? nextDueDate;
  final VoidCallback onRedo;

  const _AssistantCheckInSavedView({
    required this.isWeekly,
    required this.isOffline,
    required this.nextDueDate,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final nextDate = DateTime.tryParse(nextDueDate ?? '');
    final nextLabel = nextDate == null
        ? null
        : DateFormat('EEE, MMM d').format(nextDate);
    return _AssistantCheckInMessage(
      icon: isOffline ? Icons.cloud_upload_outlined : Icons.check_rounded,
      title: isWeekly ? 'Weekly pulse saved' : 'Today\'s check-in is done',
      message: isOffline
          ? 'Your answers are safe on this device and will sync automatically.'
          : isWeekly && nextLabel != null
          ? 'Your next weekly pulse is scheduled for $nextLabel.'
          : 'You can update today\'s answers if anything changes.',
      action: OutlinedButton.icon(
        onPressed: onRedo,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(isWeekly ? 'Update today\'s pulse' : 'Update check-in'),
      ),
    );
  }
}

class _AssistantCheckInMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _AssistantCheckInMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: primary.withValues(alpha: 0.14),
            child: Icon(icon, color: primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}
