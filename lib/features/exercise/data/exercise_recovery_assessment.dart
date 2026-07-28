class ExerciseRecoveryAssessment {
  final bool hasPoorRecovery;
  final bool needsRestorative;
  final int strainAreaCount;
  final String? reasonSubject;
  final bool reasonSubjectIsPlural;

  const ExerciseRecoveryAssessment({
    required this.hasPoorRecovery,
    required this.needsRestorative,
    required this.strainAreaCount,
    required this.reasonSubject,
    required this.reasonSubjectIsPlural,
  });

  static const none = ExerciseRecoveryAssessment(
    hasPoorRecovery: false,
    needsRestorative: false,
    strainAreaCount: 0,
    reasonSubject: null,
    reasonSubjectIsPlural: false,
  );

  factory ExerciseRecoveryAssessment.evaluate({
    required bool needsRecovery,
    int? energyLevel,
    double? sleepHours,
    int? sleepQuality,
    String? workloadHoursBand,
    String? burnoutPatternFocus,
    String? burnoutPatternSeverity,
  }) {
    final sleepStrain =
        (sleepHours != null && sleepHours > 0 && sleepHours < 6) ||
        (sleepQuality != null && sleepQuality <= 1);
    final energyStrain = energyLevel != null && energyLevel <= 2;
    final workloadStrain = _isHeavyWorkload(workloadHoursBand);
    final normalizedSeverity = _normalized(burnoutPatternSeverity);
    final needsSupport = const {
      'needs_support',
      'critical',
      'urgent',
    }.contains(normalizedSeverity);
    final highBurnout =
        needsSupport ||
        const {'high', 'high_risk'}.contains(normalizedSeverity);
    final focus = _normalized(burnoutPatternFocus);
    final recoveryFocus =
        focus.contains('recovery') ||
        focus.contains('load_reduction') ||
        focus.contains('stabilize') ||
        focus.contains('support');
    final burnoutStrain = highBurnout || recoveryFocus;

    final subjects = <String>[
      if (sleepStrain) 'Short or low-quality sleep',
      if (energyStrain) 'lower energy',
      if (workloadStrain) 'a heavy workload',
      if (burnoutStrain)
        needsSupport
            ? 'a needs-support pattern'
            : highBurnout
            ? 'a high recent strain pattern'
            : 'a recovery-focused recent pattern',
    ];
    final strainAreaCount = subjects.length;
    final hasPoorRecovery = needsRecovery || strainAreaCount > 0;
    final needsRestorative = needsSupport || strainAreaCount >= 2;

    if (!hasPoorRecovery) {
      return none;
    }

    final selectedSubjects = subjects.take(2).toList();
    final reasonSubject = needsSupport
        ? 'A needs-support pattern'
        : selectedSubjects.isEmpty
        ? "Today's recovery needs"
        : selectedSubjects.length == 1
        ? selectedSubjects.first
        : '${selectedSubjects.first} and ${selectedSubjects.last}';

    return ExerciseRecoveryAssessment(
      hasPoorRecovery: true,
      needsRestorative: needsRestorative,
      strainAreaCount: strainAreaCount,
      reasonSubject: reasonSubject,
      reasonSubjectIsPlural:
          !needsSupport &&
          (selectedSubjects.length > 1 || selectedSubjects.isEmpty),
    );
  }

  static bool _isHeavyWorkload(String? value) {
    final normalized = _normalized(value);
    final match = RegExp(r'\d+').firstMatch(normalized);
    final startingHours = int.tryParse(match?.group(0) ?? '');
    return normalized.contains('heavy') ||
        (startingHours != null && startingHours >= 8);
  }

  static String _normalized(String? value) {
    return value?.trim().toLowerCase().replaceAll(RegExp(r'[-\s]+'), '_') ?? '';
  }
}
