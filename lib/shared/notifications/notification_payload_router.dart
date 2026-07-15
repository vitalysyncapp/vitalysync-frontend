import '../navigation/main_tab.dart';

MainTab tabForNotificationPayload(String? payload) {
  final normalized = payload?.toLowerCase().trim() ?? '';

  if (normalized.contains('nutrition') || normalized.contains('meal')) {
    return MainTab.nutrition;
  }

  if (normalized.contains('dashboard') ||
      normalized.contains('adaptive') ||
      normalized.contains('burnout')) {
    return MainTab.dashboard;
  }

  if (normalized.contains('daily_log') ||
      normalized.contains('hydration') ||
      normalized.contains('sleep') ||
      normalized.contains('recovery') ||
      normalized.contains('check_in')) {
    return MainTab.log;
  }

  return MainTab.home;
}

bool shouldOpenNutritionLog(String? payload) {
  final normalized = payload?.toLowerCase().trim() ?? '';
  return normalized.contains('nutrition_log') ||
      normalized.contains('meal_log');
}
