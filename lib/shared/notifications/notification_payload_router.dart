int tabIndexForNotificationPayload(String? payload) {
  final normalized = payload?.toLowerCase().trim() ?? '';

  if (normalized.contains('nutrition') || normalized.contains('meal')) {
    return 2;
  }

  if (normalized.contains('dashboard') ||
      normalized.contains('adaptive') ||
      normalized.contains('burnout')) {
    return 3;
  }

  if (normalized.contains('daily_log') ||
      normalized.contains('hydration') ||
      normalized.contains('sleep') ||
      normalized.contains('recovery') ||
      normalized.contains('check_in')) {
    return 1;
  }

  return 0;
}

bool shouldOpenNutritionLog(String? payload) {
  final normalized = payload?.toLowerCase().trim() ?? '';
  return normalized.contains('nutrition_log') ||
      normalized.contains('meal_log');
}
