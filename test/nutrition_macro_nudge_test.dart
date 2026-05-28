import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/adaptive/data/adaptive_nudge_api.dart';
import 'package:vitalysync/features/exercise/data/exercise_recommendation_model.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_analyzer.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_api.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_coach.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 5, 22, 12);

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  NutritionAnalysis analysis({
    double calories = 500,
    double protein = 25,
    double carbs = 55,
    double fat = 18,
    String foodName = 'rice bowl',
    bool noMeals = false,
  }) {
    final summary = noMeals
        ? DailyNutritionSummary.empty()
        : DailyNutritionSummary(
            totalCalories: calories,
            totalProteinG: protein,
            totalCarbsG: carbs,
            totalFatG: fat,
            logged: const {
              'breakfast': false,
              'lunch': true,
              'dinner': false,
              'snack': false,
            },
            meals: [
              NutritionMealLog(
                nutritionLogId: 1,
                mealType: 'lunch',
                totalCalories: calories,
                totalProteinG: protein,
                totalCarbsG: carbs,
                totalFatG: fat,
                createdAt: now,
                updatedAt: now,
                items: [
                  NutritionReviewItem(
                    foodName: foodName,
                    usdaFdcId: null,
                    servingQty: 1,
                    servingUnit: 'serving',
                    calories: calories,
                    proteinG: protein,
                    carbsG: carbs,
                    fatG: fat,
                    confidence: 1,
                  ),
                ],
              ),
            ],
          );

    return NutritionAnalyzer.analyze(
      days: [NutritionDaySnapshot(date: now, summary: summary)],
      now: now,
    );
  }

  test('macro nudge recommends protein when protein is low', () {
    final insight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis(protein: 5, carbs: 45, fat: 15),
      now: now,
    );

    expect(insight?.metadata['macro_focus'], 'protein');
    expect(insight?.metadata['recommended_foods'], contains('eggs'));
  });

  test('macro nudge recommends fiber carbs when carbs are low', () {
    final insight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis(protein: 40, carbs: 8, fat: 20, foodName: 'egg salad'),
      now: now,
    );

    expect(insight?.metadata['macro_focus'], 'carbs_fiber');
    expect(insight?.metadata['recommended_foods'], contains('oats'));
  });

  test('macro nudge recommends healthy fats when fat is low', () {
    final insight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis(
        protein: 35,
        carbs: 60,
        fat: 2,
        foodName: 'chicken rice tomato',
      ),
      now: now,
    );

    expect(insight?.metadata['macro_focus'], 'healthy_fats');
    expect(insight?.metadata['recommended_foods'], contains('avocado'));
  });

  test('macro nudge balances high carbs with protein and produce', () {
    final insight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis(protein: 28, carbs: 140, fat: 8),
      now: now,
    );

    expect(insight?.metadata['macro_focus'], 'protein_produce');
    expect(insight?.metadata['recommended_foods'], contains('tofu'));
  });

  test('macro nudge balances high fat with fiber and produce', () {
    final insight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis(
        protein: 40,
        carbs: 35,
        fat: 55,
        foodName: 'egg pork tomato',
      ),
      now: now,
    );

    expect(insight?.metadata['macro_focus'], 'fiber_produce');
    expect(insight?.metadata['recommended_foods'], contains('sweet potato'));
  });

  test('macro nudge handles no meals logged', () {
    final insight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis(noMeals: true),
      now: now,
    );

    expect(insight?.metadata['macro_focus'], 'complete_meal');
    expect(insight?.message, contains('No meals are logged yet'));
  });

  test('macro nudge suppresses dismissed focus when another option exists', () {
    final insight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis(protein: 5, carbs: 45, fat: 15),
      dismissedMacroFocuses: const {'protein'},
      now: now,
    );

    expect(insight?.metadata['macro_focus'], isNot('protein'));
  });

  testWidgets('assistant dialog nudge cards keep long text visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'user_id': 1});

    const smartMessage =
        'This is a longer smart nudge that should remain fully visible inside the assistant panel instead of being clipped after only a few lines. It includes enough wording to wrap naturally.';
    const nutritionMessage =
        'This is a longer nutrition nudge that recommends balancing macros with common healthy foods and should stay readable when the card grows inside the scrollable assistant dialog.';
    final smart = AdaptiveNudgeRecommendation(
      nudgeEventId: 99,
      nudgeType: 'recovery_break',
      priority: 'medium',
      title: 'Protect a recovery break',
      message: smartMessage,
      actionLabel: 'Take a short reset',
      triggerReason: 'Recent workload and recovery pattern',
      recommendedFocus: 'recovery',
      patternType: 'workload_recovery_mismatch',
      severity: 'moderate',
      confidenceScore: 76,
      metadata: const {
        'ai_enhanced': true,
        'ai_why_this_matters':
            'A small recovery break can reduce pressure before the next demanding block.',
        'ai_action_steps': ['Drink water', 'Take five quiet minutes'],
      },
    );
    final nutrition = NutritionInsight(
      id: '2026-05-22_nutrition_protein',
      title: 'Add protein next',
      message: nutritionMessage,
      confidence: NutritionConfidence.medium,
      source: 'nutrition_assistant',
      generatedAt: now,
      metadata: const {
        'macro_focus': 'protein',
        'recommended_foods': ['eggs', 'chicken', 'tofu'],
      },
    );

    await pumpTestApp(
      tester,
      SizedBox(
        width: 390,
        height: 520,
        child: AssistantExperiencePanel(
          message: 'Fallback message',
          emoji: 'heart',
          recommendations: const <ExerciseRecommendationModel>[],
          adaptiveNudges: [smart],
          nutritionInsight: nutrition,
          onRefreshRecommendations: () async =>
              const <ExerciseRecommendationModel>[],
          onRefreshAdaptiveNudges: ({bool forceRefresh = false}) async => [
            smart,
          ],
          onRefreshNutritionInsight: ({bool forceRefresh = false}) async =>
              nutrition,
          onRefreshEnvironment: () async => null,
          onLogMealRequested: () {},
          onLogPageRequested: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(smartMessage), findsOneWidget);
    expect(find.text(nutritionMessage), findsOneWidget);
    expect(find.text('Drink water'), findsOneWidget);
    expect(find.text('eggs'), findsOneWidget);
  });

  testWidgets('assistant dialog does not refetch loaded empty nudge state', (
    tester,
  ) async {
    var adaptiveFetches = 0;
    var nutritionFetches = 0;

    await pumpTestApp(
      tester,
      SizedBox(
        width: 390,
        height: 520,
        child: AssistantExperiencePanel(
          message: 'Fallback message',
          emoji: 'heart',
          recommendations: const <ExerciseRecommendationModel>[],
          adaptiveNudges: const <AdaptiveNudgeRecommendation>[],
          nutritionInsight: null,
          hasLoadedAdaptiveNudges: true,
          hasLoadedNutritionInsight: true,
          onRefreshRecommendations: () async =>
              const <ExerciseRecommendationModel>[],
          onRefreshAdaptiveNudges: ({bool forceRefresh = false}) async {
            adaptiveFetches += 1;
            return const <AdaptiveNudgeRecommendation>[];
          },
          onRefreshNutritionInsight: ({bool forceRefresh = false}) async {
            nutritionFetches += 1;
            return null;
          },
          onRefreshEnvironment: () async => null,
          onLogMealRequested: () {},
          onLogPageRequested: () {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(adaptiveFetches, 0);
    expect(nutritionFetches, 0);
  });
}
