import '../../activity/data/activity_api.dart';
import '../../activity/data/activity_log.dart';
import '../../log/data/log_api.dart';

class WeeklyUserMetrics {
  final List<DailyUserMetric> days;

  const WeeklyUserMetrics({required this.days});

  int get loggedDays => days.where((day) => day.hasLog).length;

  double get averageSleep {
    final values = days
        .map((day) => day.sleepHours)
        .where((value) => value > 0)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double get averageHydration {
    final values = days
        .map((day) => day.hydrationLiters)
        .where((value) => value > 0)
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double get averageMood {
    final values = days
        .map((day) => day.moodIndex)
        .where((value) => value != null)
        .cast<int>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int get moodRange {
    final values = days
        .map((day) => day.moodIndex)
        .where((value) => value != null)
        .cast<int>()
        .toList();
    if (values.length < 2) return 0;
    values.sort();
    return values.last - values.first;
  }

  String get moodTrendLabel {
    final values = days
        .map((day) => day.moodIndex)
        .where((value) => value != null)
        .cast<int>()
        .toList();
    if (values.length < 2) return 'Needs more logs';
    final mid = (values.length / 2).floor();
    final first = values.take(mid).toList();
    final second = values.skip(mid).toList();
    final firstAvg = first.reduce((a, b) => a + b) / first.length;
    final secondAvg = second.reduce((a, b) => a + b) / second.length;
    final delta = secondAvg - firstAvg;
    if (delta >= 0.4) return 'Improving';
    if (delta <= -0.4) return 'Lower';
    return 'Stable';
  }

  String get moodStabilityLabel {
    if (loggedDays < 2) return 'Needs more logs';
    if (moodRange <= 1) return 'Stable';
    if (moodRange == 2) return 'Mixed';
    return 'Variable';
  }

  int get exerciseDays {
    return days.where((day) {
      if (day.activity?.goalCompleted == true) return true;
      if (day.exerciseGoalCompleted == true) return true;
      return day.exerciseNames.any((name) => name.toLowerCase() != 'none');
    }).length;
  }

  int get activityGoalDays {
    return days.where((day) => day.activity?.goalCompleted == true).length;
  }

  int get totalSteps {
    return days.fold(0, (sum, day) => sum + (day.activity?.steps ?? 0));
  }

  int get averageSteps {
    if (days.isEmpty) return 0;
    return (totalSteps / days.length).round();
  }

  int get consistencyScore {
    final logScore = loggedDays / 7;
    final movementScore = exerciseDays / 7;
    final sleepScore = (averageSleep / 8).clamp(0.0, 1.0);
    final hydrationScore = (averageHydration / 2.5).clamp(0.0, 1.0);
    return ((logScore * 0.35 +
                movementScore * 0.25 +
                sleepScore * 0.25 +
                hydrationScore * 0.15) *
            100)
        .round();
  }

  int get sleepIndex => ((averageSleep / 8).clamp(0.0, 1.0) * 100).round();

  int get moodIndex => (((averageMood + 1) / 5).clamp(0.0, 1.0) * 100).round();

  int get energyIndex {
    final values = days
        .map((day) => day.energyLevel)
        .where((value) => value != null)
        .cast<int>()
        .toList();
    if (values.isEmpty) return 0;
    final average = values.reduce((a, b) => a + b) / values.length;
    return (((average + 1) / 3).clamp(0.0, 1.0) * 100).round();
  }

  int get hydrationIndex {
    return ((averageHydration / 2.5).clamp(0.0, 1.0) * 100).round();
  }

  int get exerciseIndex => ((exerciseDays / 7) * 100).round();

  int get recoveryIndex {
    final sleep = sleepIndex;
    final breakValues = days
        .map((day) => day.breakQualityLevel)
        .where((value) => value != null)
        .cast<int>()
        .toList();
    if (breakValues.isEmpty) return sleep;
    final breakAverage =
        breakValues.reduce((a, b) => a + b) / breakValues.length;
    final breakScore = ((breakAverage / 5).clamp(0.0, 1.0) * 100).round();
    return ((sleep + breakScore) / 2).round();
  }

  Map<String, int> get symptomCounts {
    final counts = <String, int>{};
    for (final day in days) {
      for (final symptom in day.symptomNames) {
        final normalized = symptom.trim();
        if (normalized.isEmpty || normalized.toLowerCase() == 'none') continue;
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }
    }
    return counts;
  }

  String get weeklyNote {
    if (loggedDays == 0) {
      return 'Add daily logs to unlock your weekly view.';
    }
    if (consistencyScore >= 75) {
      return 'You kept a steady routine this week.';
    }
    if (averageSleep > 0 && averageSleep < 6) {
      return 'Sleep was the main area to protect this week.';
    }
    if (exerciseDays < 3) {
      return 'A few more movement days would improve next week.';
    }
    return 'You have enough data to spot useful patterns.';
  }
}

class DailyUserMetric {
  final DateTime date;
  final String dateKey;
  final String dayLabel;
  final Map<String, dynamic>? log;
  final ActivityLog? activity;

  const DailyUserMetric({
    required this.date,
    required this.dateKey,
    required this.dayLabel,
    required this.log,
    required this.activity,
  });

  bool get hasLog => log != null;

  double get sleepHours => LogApi.parseDouble(log?['sleep_hours']);

  double get hydrationLiters => LogApi.parseDouble(log?['hydration_liters']);

  int? get moodIndex =>
      log == null ? null : LogApi.parseInt(log?['mood_index']);

  int? get energyLevel =>
      log == null ? null : LogApi.parseInt(log?['energy_level']);

  int? get breakQualityLevel => LogApi.parseLikert(log?['break_quality_level']);

  bool? get exerciseGoalCompleted {
    final value = log?['exercise_goal_completed'];
    if (value is bool) return value;
    if (value == null) return null;
    return value.toString().toLowerCase() == 'true';
  }

  List<String> get exerciseNames => _stringList(log?['exercise_names']);

  List<String> get symptomNames => _stringList(log?['symptom_names']);
}

class WeeklyUserMetricsService {
  static Future<WeeklyUserMetrics> loadCurrentWeek() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    return loadRange(start: start, end: today);
  }

  static Future<WeeklyUserMetrics> loadRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);
    final logs = await LogApi.fetchHistory(
      startDate: startKey,
      endDate: endKey,
      limit: 7,
    );
    final logByDate = {
      for (final log in logs)
        if (LogApi.normalizeDateString(log['log_date']) != null)
          LogApi.normalizeDateString(log['log_date'])!: log,
    };

    final activityByDate = <String, ActivityLog>{};
    final userId = await LogApi.getStoredUserId();
    if (userId != null) {
      try {
        final activityLogs = await ActivityApi.fetchHistory(
          userId: userId,
          startDate: startKey,
          endDate: endKey,
        );
        for (final activity in activityLogs) {
          activityByDate[activity.logDate] = activity;
        }
      } catch (_) {
        // Activity is optional for the chart. Logs still make the cards useful.
      }
    }

    final days = List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final key = _dateKey(date);
      return DailyUserMetric(
        date: date,
        dateKey: key,
        dayLabel: _dayLabel(date),
        log: logByDate[key],
        activity: activityByDate[key],
      );
    });

    return WeeklyUserMetrics(days: days);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _dayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  return const [];
}
