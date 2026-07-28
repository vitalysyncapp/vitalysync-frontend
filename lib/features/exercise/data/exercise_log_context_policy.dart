class ExerciseLogContextPolicy {
  const ExerciseLogContextPolicy._();

  static const Duration recentWindow = Duration(days: 7);

  static Map<String, dynamic>? selectRecentFallback(
    Map<String, dynamic>? log, {
    DateTime? now,
  }) {
    if (log == null) {
      return null;
    }

    final rawLogDate = log['log_date']?.toString().trim() ?? '';
    if (rawLogDate.length < 10) {
      return null;
    }

    final parsedLogDate = DateTime.tryParse(rawLogDate.substring(0, 10));
    if (parsedLogDate == null) {
      return null;
    }

    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final loggedOn = DateTime(
      parsedLogDate.year,
      parsedLogDate.month,
      parsedLogDate.day,
    );
    final ageInDays = today.difference(loggedOn).inDays;
    if (ageInDays < 0 || ageInDays > recentWindow.inDays) {
      return null;
    }

    return log;
  }
}
