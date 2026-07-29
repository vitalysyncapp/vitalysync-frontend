class ExerciseContextResolution {
  final bool needsRecovery;
  final String? workloadHoursBand;

  const ExerciseContextResolution({
    required this.needsRecovery,
    required this.workloadHoursBand,
  });
}

class ExerciseContextPolicy {
  const ExerciseContextPolicy._();

  static ExerciseContextResolution resolve({
    required bool hasCurrentBurnoutEvidence,
    required bool currentBurnoutNeedsRecovery,
    required String? currentWorkloadHoursBand,
    required String? initialBurnoutLevel,
    required double? initialBurnoutScore,
    required int? onboardingWorkloadLevel,
  }) {
    final normalizedCurrentWorkload = currentWorkloadHoursBand?.trim();
    final workloadHoursBand = normalizedCurrentWorkload?.isNotEmpty == true
        ? normalizedCurrentWorkload
        : _workloadFallback(onboardingWorkloadLevel);
    final normalizedInitialLevel = initialBurnoutLevel?.trim().toLowerCase();
    final onboardingBurnoutNeedsRecovery =
        normalizedInitialLevel == 'high' ||
        normalizedInitialLevel == 'very high' ||
        (initialBurnoutScore != null && initialBurnoutScore >= 45);

    return ExerciseContextResolution(
      needsRecovery:
          currentBurnoutNeedsRecovery ||
          (!hasCurrentBurnoutEvidence && onboardingBurnoutNeedsRecovery),
      workloadHoursBand: workloadHoursBand,
    );
  }

  static String? _workloadFallback(int? level) {
    return switch (level) {
      5 => '10-12 hours',
      4 => '8-9 hours',
      3 => '5-6 hours',
      2 => '3-4 hours',
      1 => '1-2 hours',
      _ => null,
    };
  }
}
