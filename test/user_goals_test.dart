import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/shared/goals/user_goals.dart';

void main() {
  test('goals snapshot tracks auto-managed nutrition source', () {
    final goals = UserGoalsSnapshot.fromApi({
      'goals': {
        'nutrition_calories': {
          'target_value': 1800,
          'unit': 'kcal',
          'source': 'system_default',
          'metadata': {'balanced_kcal': 1950},
        },
      },
    });

    expect(goals.nutritionCalories, 1800);
    expect(goals.nutritionCaloriesSource, 'system_default');
    expect(goals.nutritionCaloriesIsAutoManaged, isTrue);
    expect(goals.balancedNutritionCalories, 1950);
    expect(goals.balancedNutritionLabel, '1,950 kcal');
  });

  test('goals payload can preserve an unchanged auto nutrition goal', () {
    final goals = UserGoalsSnapshot.defaults(
      wellnessGoals: const ['Improve sleep'],
      nutritionCalories: 1800,
      nutritionCaloriesSource: 'system_default',
    );

    final payload = goals.toApiGoals(includeNutritionCalories: false);

    expect(payload, isNot(contains('nutrition_calories')));
    expect(payload, contains('sleep_hours'));
    expect(payload, contains('hydration_liters'));
  });

  test('goals payload includes nutrition when user changes it manually', () {
    final goals = UserGoalsSnapshot.defaults(
      nutritionCalories: 2300,
      nutritionCaloriesSource: 'system_default',
    );

    final payload = goals.toApiGoals();

    expect(payload['nutrition_calories'], {
      'target_value': 2300,
      'unit': 'kcal',
      'source': 'profile',
    });
  });
}
