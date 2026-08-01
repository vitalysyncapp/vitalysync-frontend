part of 'floating_smart_nudge_assistant.dart';

class _AssistantCheckInCard extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final bool isSaving;
  final CheckInStatus? status;
  final CheckInDraft draft;
  final bool isEditing;
  final int currentStreak;
  final String exerciseGoalLabel;
  final ValueChanged<CheckInDraft> onChanged;
  final Future<void> Function() onSave;
  final VoidCallback onRedo;

  const _AssistantCheckInCard({
    required this.isActive,
    required this.isLoading,
    required this.isSaving,
    required this.status,
    required this.draft,
    required this.isEditing,
    required this.currentStreak,
    required this.exerciseGoalLabel,
    required this.onChanged,
    required this.onSave,
    required this.onRedo,
  });

  bool get _showWeeklyQuestions => status?.requiredMode == CheckInMode.weekly;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildEntrance(context, const _AssistantLoadingCard());
    }
    final currentStatus = status;
    if (currentStatus == null) {
      return _buildEntrance(
        context,
        const _AssistantCheckInMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Check-in unavailable',
          message:
              'Reconnect and refresh the assistant to load today\'s check-in.',
        ),
      );
    }
    if (currentStatus.isComplete && !isEditing) {
      return _buildEntrance(
        context,
        CheckInSuccessView(
          isOffline:
              currentStatus.isOffline && currentStatus.pendingSyncCount > 0,
          hasPendingSync: currentStatus.pendingSyncCount > 0,
          pendingSyncCount: currentStatus.pendingSyncCount,
          currentStreak: currentStreak,
          onRedo: onRedo,
        ),
      );
    }

    final missing = draft.validationErrors(currentStatus.requiredMode);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      primary.withValues(alpha: 0.18),
                      const Color(0xFF1FB489).withValues(alpha: 0.09),
                    ]
                  : [
                      primary.withValues(alpha: 0.1),
                      const Color(0xFF1FB489).withValues(alpha: 0.06),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primary.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.08 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -36,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.055),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary.withValues(alpha: isDark ? 0.28 : 0.18),
                            const Color(
                              0xFF1FB489,
                            ).withValues(alpha: isDark ? 0.2 : 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        _showWeeklyQuestions
                            ? Icons.calendar_view_week_rounded
                            : Icons.bolt_rounded,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            _showWeeklyQuestions
                                ? 'How did your week feel?'
                                : 'Daily Check-in',
                            style: TextStyle(
                              color: pagePrimaryTextColor(context),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LocalizedText(
                            _showWeeklyQuestions
                                ? 'Reflect on this week\'s pressure, recovery, time to switch off, focus, and sense of accomplishment.'
                                : 'Take a moment to reflect on your day and see how you are doing.',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
          revealCards: isActive,
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
            label: LocalizedText(
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
          LocalizedText(
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
    return _buildEntrance(context, form);
  }

  Widget _buildEntrance(BuildContext context, Widget child) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 420);

    return AnimatedSlide(
      key: const ValueKey('assistant-check-in-entrance'),
      offset: isActive ? Offset.zero : const Offset(0, 0.025),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isActive ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: child,
      ),
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

class _AssistantCheckInMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _AssistantCheckInMessage({
    required this.icon,
    required this.title,
    required this.message,
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
          LocalizedText(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          LocalizedText(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
