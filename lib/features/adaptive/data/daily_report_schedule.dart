class DailyReportSchedule {
  const DailyReportSchedule._();

  static const int generationHour = 7;

  static String? reportDateDueAt(DateTime now) {
    final localNow = now.toLocal();
    final cutoff = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      generationHour,
    );
    if (localNow.isBefore(cutoff)) {
      return null;
    }

    final reportDate = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    ).subtract(const Duration(days: 1));
    return _dateKey(reportDate);
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
