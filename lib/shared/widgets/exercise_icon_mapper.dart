import 'package:flutter/material.dart';

IconData exerciseIconFor({required String name, String? category}) {
  final normalizedCategory = category?.trim().toLowerCase() ?? '';
  final normalizedName = name.trim().toLowerCase();
  final activity = normalizedCategory.isNotEmpty
      ? normalizedCategory
      : normalizedName;

  if (activity == 'none' || normalizedName.contains('none today')) {
    return Icons.block_rounded;
  }
  if (activity == 'walking' || normalizedName.contains('walk')) {
    return Icons.directions_walk_rounded;
  }
  if (activity == 'jogging' || normalizedName.contains('jog')) {
    return Icons.directions_run_rounded;
  }
  if (activity == 'running' || normalizedName.contains('run')) {
    return Icons.run_circle_rounded;
  }
  if (activity == 'bodyweight' ||
      normalizedName.contains('bodyweight') ||
      normalizedName.contains('push-up') ||
      normalizedName.contains('squat')) {
    return Icons.sports_gymnastics_rounded;
  }
  if (activity == 'stretching' || normalizedName.contains('stretch')) {
    return Icons.accessibility_new_rounded;
  }
  if (activity == 'breathing' || normalizedName.contains('breath')) {
    return Icons.air_rounded;
  }
  if (activity == 'yoga' || normalizedName.contains('yoga')) {
    return Icons.self_improvement_rounded;
  }
  if (activity == 'strength' ||
      activity == 'gym' ||
      normalizedName.contains('strength') ||
      normalizedName.contains('gym')) {
    return Icons.fitness_center_rounded;
  }
  if (activity == 'cycling' || normalizedName.contains('cycl')) {
    return Icons.directions_bike_rounded;
  }
  if (activity == 'swimming' || normalizedName.contains('swim')) {
    return Icons.pool_rounded;
  }
  if (activity == 'mobility' || normalizedName.contains('mobility')) {
    return Icons.transfer_within_a_station_rounded;
  }
  if (activity == 'cardio' || normalizedName.contains('cardio')) {
    return Icons.favorite_rounded;
  }
  if (activity == 'conditioning' || normalizedName.contains('conditioning')) {
    return Icons.bolt_rounded;
  }

  return Icons.fitness_center_rounded;
}
