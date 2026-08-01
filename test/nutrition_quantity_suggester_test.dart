import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_quantity_suggester.dart';

void main() {
  group('NutritionQuantitySuggester', () {
    test('suggests a half cup for rice', () {
      expect(NutritionQuantitySuggester.suggest('White rice'), '1/2 cup');
      expect(NutritionQuantitySuggester.suggest('fried RICE'), '1/2 cup');
    });

    test('prefers the meal container for soups and bowls', () {
      expect(NutritionQuantitySuggester.suggest('Tomato soup'), '1 bowl');
      expect(NutritionQuantitySuggester.suggest('Bone broth'), '1 bowl');
      expect(NutritionQuantitySuggester.suggest('Chicken rice bowl'), '1 bowl');
    });

    test('uses slice, cup, and piece for matching foods', () {
      expect(NutritionQuantitySuggester.suggest('Wheat toast'), '1 slice');
      expect(NutritionQuantitySuggester.suggest('Pasta'), '1 cup');
      expect(NutritionQuantitySuggester.suggest('Banana'), '1 piece');
    });

    test('does not guess when the meal has no reliable serving match', () {
      expect(NutritionQuantitySuggester.suggest('Beef caldereta'), isNull);
      expect(NutritionQuantitySuggester.suggest(''), isNull);
    });
  });
}
