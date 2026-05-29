part of 'profile_page.dart';

String? _emptyToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String _workIntensityFromHours(int hours) => hours >= 10
    ? 'High'
    : hours >= 7
    ? 'Medium'
    : 'Low';

String _workIntensityFromLevel(int? level) => level == null
    ? 'Medium'
    : level >= 4
    ? 'High'
    : level <= 2
    ? 'Low'
    : 'Medium';

int _workloadLevelFromIntensity(String intensity) =>
    intensity.toLowerCase() == 'high'
    ? 4
    : intensity.toLowerCase() == 'low'
    ? 2
    : 3;

String _waterGoalFromActivity(String activity) =>
    activity.toLowerCase().contains('active') &&
        activity.toLowerCase() != 'sedentary'
    ? '3.0 L'
    : activity.toLowerCase() == 'sedentary'
    ? '2.0 L'
    : '2.5 L';

int _parseIntValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return double.tryParse('${value ?? ''}')?.round() ?? 0;
}

String? _dropdownValueOrNull(
  String? value,
  List<String> options, {
  Map<String, String> aliases = const {},
}) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  for (final option in options) {
    if (option.toLowerCase() == normalized.toLowerCase()) {
      return option;
    }
  }

  final aliasMatch = aliases[normalized.toLowerCase()];
  if (aliasMatch == null) return null;

  for (final option in options) {
    if (option.toLowerCase() == aliasMatch.toLowerCase()) {
      return option;
    }
  }

  return null;
}

String _formatTimeForDisplay(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return value;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return value;
  final period = hour >= 12 ? 'PM' : 'AM';
  final normalizedHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$normalizedHour:${minute.toString().padLeft(2, '0')} $period';
}

String _buildSleepSchedule({
  required String? sleepTime,
  required String? wakeTime,
  required String fallback,
}) {
  if (sleepTime == null || wakeTime == null) return fallback;
  return '${_formatTimeForDisplay(sleepTime)} - ${_formatTimeForDisplay(wakeTime)}';
}

String? _convertDisplayTimeTo24Hour(String value) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
  ).firstMatch(value.trim().toUpperCase());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  final period = match.group(3);
  if (hour == null || minute == null || period == null) return null;
  var militaryHour = hour % 12;
  if (period == 'PM') militaryHour += 12;
  return '${militaryHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

Map<String, String?> _parseSleepSchedule(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return const {'sleep': null, 'wake': null};
  return {
    'sleep': _convertDisplayTimeTo24Hour(parts[0]),
    'wake': _convertDisplayTimeTo24Hour(parts[1]),
  };
}

int _parseExerciseDays(String value) =>
    int.tryParse(RegExp(r'(\d+)').firstMatch(value)?.group(1) ?? '') ?? 3;

double _parseLiters(String value) {
  final parsed = double.tryParse(
    RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value)?.group(1) ?? '',
  );
  if (parsed == null) return 2.5;

  return value.toLowerCase().contains('ml') ? parsed / 1000 : parsed;
}

String _formatLiters(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) {
    return '${rounded.round()} L';
  }

  return '${rounded.toStringAsFixed(1)} L';
}
