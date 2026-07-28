class NutritionFeedbackPreferences {
  final Set<String> dismissedMacroFocuses;
  final Set<String> dismissedFoodGroups;
  final Set<String> dismissedNudgeTypes;
  final Set<String> acceptedMacroFocuses;
  final Set<String> acceptedFoodGroups;
  final Set<String> acceptedNudgeTypes;

  const NutritionFeedbackPreferences({
    this.dismissedMacroFocuses = const <String>{},
    this.dismissedFoodGroups = const <String>{},
    this.dismissedNudgeTypes = const <String>{},
    this.acceptedMacroFocuses = const <String>{},
    this.acceptedFoodGroups = const <String>{},
    this.acceptedNudgeTypes = const <String>{},
  });

  bool dismisses(Map<String, dynamic> metadata) {
    return dismissedMacroFocuses.contains(metadata['macro_focus']) ||
        dismissedFoodGroups.contains(metadata['food_group']) ||
        dismissedNudgeTypes.contains(metadata['nutrition_nudge_type']);
  }

  int acceptedMatchCount(Map<String, dynamic> metadata) {
    var count = 0;
    if (acceptedMacroFocuses.contains(metadata['macro_focus'])) {
      count += 1;
    }
    if (acceptedFoodGroups.contains(metadata['food_group'])) {
      count += 1;
    }
    if (acceptedNudgeTypes.contains(metadata['nutrition_nudge_type'])) {
      count += 1;
    }
    return count;
  }
}
