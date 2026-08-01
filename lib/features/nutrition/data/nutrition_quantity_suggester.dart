class NutritionQuantitySuggester {
  NutritionQuantitySuggester._();

  static String? suggest(String mealName) {
    final normalizedName = mealName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    if (normalizedName.isEmpty) {
      return null;
    }

    for (final rule in _rules) {
      if (rule.matches(normalizedName)) {
        return rule.quantity;
      }
    }

    return null;
  }

  static const List<_QuantityRule> _rules = [
    _QuantityRule('1 bowl', [
      'soup',
      'soups',
      'broth',
      'stew',
      'stews',
      'chowder',
      'congee',
      'porridge',
      'ramen',
      'pho',
      'salad',
      'salads',
      'bowl',
    ]),
    _QuantityRule('1/2 cup', ['rice']),
    _QuantityRule('1 slice', [
      'bread',
      'toast',
      'pizza',
      'cake',
      'pie',
      'cheese',
      'bacon',
      'loaf',
      'sliced',
      'slice',
      'slices',
    ]),
    _QuantityRule('1 cup', [
      'pasta',
      'spaghetti',
      'macaroni',
      'noodle',
      'noodles',
      'oatmeal',
      'cereal',
      'beans',
      'lentils',
      'corn',
      'peas',
      'coffee',
      'tea',
      'milk',
      'juice',
      'smoothie',
      'shake',
    ]),
    _QuantityRule('1 piece', [
      'egg',
      'eggs',
      'apple',
      'apples',
      'banana',
      'bananas',
      'orange',
      'oranges',
      'pear',
      'pears',
      'mango',
      'mangoes',
      'chicken',
      'wing',
      'wings',
      'drumstick',
      'drumsticks',
      'fillet',
      'steak',
      'sausage',
      'sausages',
      'dumpling',
      'dumplings',
      'nugget',
      'nuggets',
      'meatball',
      'meatballs',
      'sushi',
      'cookie',
      'cookies',
      'cracker',
      'crackers',
      'biscuit',
      'biscuits',
      'sandwich',
      'sandwiches',
      'burger',
      'burgers',
      'taco',
      'tacos',
      'wrap',
      'wraps',
    ]),
  ];
}

class _QuantityRule {
  final String quantity;
  final List<String> keywords;

  const _QuantityRule(this.quantity, this.keywords);

  bool matches(String normalizedMealName) {
    final paddedName = ' $normalizedMealName ';
    return keywords.any((keyword) => paddedName.contains(' $keyword '));
  }
}
