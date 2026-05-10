import 'nutrition_api.dart';

enum NutritionConfidence { low, medium, high }

enum NutritionPatternType {
  missingSingleMeal,
  repeatedMissingBreakfast,
  inactiveLogging,
  irregularMealTiming,
}

extension NutritionConfidenceLabel on NutritionConfidence {
  String get label {
    switch (this) {
      case NutritionConfidence.high:
        return 'high';
      case NutritionConfidence.medium:
        return 'medium';
      case NutritionConfidence.low:
        return 'low';
    }
  }
}

class NutritionDaySnapshot {
  final DateTime date;
  final DailyNutritionSummary summary;

  const NutritionDaySnapshot({required this.date, required this.summary});

  bool get breakfastLogged => summary.logged['breakfast'] == true;
  bool get lunchLogged => summary.logged['lunch'] == true;
  bool get dinnerLogged => summary.logged['dinner'] == true;
  bool get snacksLogged => summary.logged['snack'] == true;
  int get dailyMealCount => summary.meals.length;
  bool get isMealLoggingInactive => dailyMealCount == 0;

  bool get hasIrregularMealTiming {
    final gap = largestMealLogGap;
    return gap != null && gap.inHours >= 7;
  }

  Duration? get largestMealLogGap {
    final timestamps =
        summary.meals
            .map((meal) => meal.createdAt)
            .whereType<DateTime>()
            .toList()
          ..sort();

    if (timestamps.length < 2) {
      return null;
    }

    Duration largest = Duration.zero;
    for (var index = 1; index < timestamps.length; index += 1) {
      final gap = timestamps[index].difference(timestamps[index - 1]);
      if (gap > largest) {
        largest = gap;
      }
    }

    return largest;
  }
}

class NutritionPattern {
  final NutritionPatternType type;
  final NutritionConfidence confidence;
  final int occurrences;
  final String reason;

  const NutritionPattern({
    required this.type,
    required this.confidence,
    required this.occurrences,
    required this.reason,
  });
}

class NutritionAnalysis {
  final DateTime generatedAt;
  final NutritionDaySnapshot today;
  final List<NutritionDaySnapshot> days;
  final List<NutritionPattern> patterns;
  final NutritionConfidence confidence;
  final int missingBreakfastDays;
  final int inactiveLoggingDays;
  final int irregularTimingDays;

  const NutritionAnalysis({
    required this.generatedAt,
    required this.today,
    required this.days,
    required this.patterns,
    required this.confidence,
    required this.missingBreakfastDays,
    required this.inactiveLoggingDays,
    required this.irregularTimingDays,
  });

  bool get breakfastLoggedToday => today.breakfastLogged;
  bool get lunchLoggedToday => today.lunchLogged;
  bool get dinnerLoggedToday => today.dinnerLogged;
  bool get snacksLoggedToday => today.snacksLogged;
  int get dailyMealCount => today.dailyMealCount;
  bool get noMealsLoggedToday => dailyMealCount == 0;
  bool get isMealLoggingInactive => inactiveLoggingDays >= 2;
  bool get hasNutritionSignal =>
      patterns.isNotEmpty ||
      today.dailyMealCount > 0 ||
      inactiveLoggingDays > 0;

  NutritionPattern? firstPatternOf(NutritionPatternType type) {
    for (final pattern in patterns) {
      if (pattern.type == type) {
        return pattern;
      }
    }

    return null;
  }
}

class NutritionAnalyzer {
  const NutritionAnalyzer._();

  static NutritionAnalysis analyze({
    required List<NutritionDaySnapshot> days,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final normalizedDays = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final today = _findToday(normalizedDays, generatedAt);
    final inactiveLoggingDays = _consecutiveInactiveDays(
      normalizedDays,
      generatedAt,
    );
    final missingBreakfastDays = normalizedDays
        .where((day) => day.dailyMealCount > 0 && !day.breakfastLogged)
        .length;
    final irregularTimingDays = normalizedDays
        .where((day) => day.hasIrregularMealTiming)
        .length;
    final patterns = <NutritionPattern>[];

    if (_hasSingleExpectedMealMissing(today, generatedAt)) {
      patterns.add(
        const NutritionPattern(
          type: NutritionPatternType.missingSingleMeal,
          confidence: NutritionConfidence.low,
          occurrences: 1,
          reason: 'An expected meal window has passed without a log today.',
        ),
      );
    }

    if (missingBreakfastDays >= 2) {
      patterns.add(
        NutritionPattern(
          type: NutritionPatternType.repeatedMissingBreakfast,
          confidence: missingBreakfastDays >= 4
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          occurrences: missingBreakfastDays,
          reason:
              'Breakfast is missing from $missingBreakfastDays logged days in the 7-day window.',
        ),
      );
    }

    if (inactiveLoggingDays >= 2) {
      patterns.add(
        NutritionPattern(
          type: NutritionPatternType.inactiveLogging,
          confidence: NutritionConfidence.high,
          occurrences: inactiveLoggingDays,
          reason:
              'No meal logs were found for $inactiveLoggingDays consecutive days.',
        ),
      );
    }

    if (irregularTimingDays >= 2) {
      patterns.add(
        NutritionPattern(
          type: NutritionPatternType.irregularMealTiming,
          confidence: irregularTimingDays >= 4
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          occurrences: irregularTimingDays,
          reason:
              'Large gaps appeared between meal log timestamps on $irregularTimingDays days.',
        ),
      );
    }

    return NutritionAnalysis(
      generatedAt: generatedAt,
      today: today,
      days: normalizedDays,
      patterns: patterns,
      confidence: _overallConfidence(patterns),
      missingBreakfastDays: missingBreakfastDays,
      inactiveLoggingDays: inactiveLoggingDays,
      irregularTimingDays: irregularTimingDays,
    );
  }

  static NutritionDaySnapshot _findToday(
    List<NutritionDaySnapshot> days,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    for (final day in days.reversed) {
      if (_isSameDate(day.date, today)) {
        return day;
      }
    }

    return NutritionDaySnapshot(
      date: today,
      summary: DailyNutritionSummary.empty(),
    );
  }

  static int _consecutiveInactiveDays(
    List<NutritionDaySnapshot> days,
    DateTime now,
  ) {
    final byDate = {for (final day in days) _dateKey(day.date): day};
    var count = 0;
    final today = DateTime(now.year, now.month, now.day);

    for (var offset = 0; offset < 7; offset += 1) {
      final date = today.subtract(Duration(days: offset));
      final day = byDate[_dateKey(date)];
      if (day == null || day.dailyMealCount == 0) {
        count += 1;
      } else {
        break;
      }
    }

    return count;
  }

  static bool _hasSingleExpectedMealMissing(
    NutritionDaySnapshot today,
    DateTime now,
  ) {
    if (today.dailyMealCount == 0) {
      return false;
    }

    final minutes = now.hour * 60 + now.minute;
    final breakfastWindowPassed = minutes >= 10 * 60;
    final lunchWindowPassed = minutes >= 14 * 60;
    final dinnerWindowPassed = minutes >= 20 * 60;

    return (breakfastWindowPassed && !today.breakfastLogged) ||
        (lunchWindowPassed && !today.lunchLogged) ||
        (dinnerWindowPassed && !today.dinnerLogged);
  }

  static NutritionConfidence _overallConfidence(
    List<NutritionPattern> patterns,
  ) {
    if (patterns.any(
      (pattern) => pattern.confidence == NutritionConfidence.high,
    )) {
      return NutritionConfidence.high;
    }
    if (patterns.any(
      (pattern) => pattern.confidence == NutritionConfidence.medium,
    )) {
      return NutritionConfidence.medium;
    }

    return NutritionConfidence.low;
  }

  static bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().substring(0, 10);
  }
}
