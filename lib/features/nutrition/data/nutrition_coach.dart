import 'nutrition_analyzer.dart';
import 'nutrition_api.dart';

class NutritionInsight {
  final String id;
  final String title;
  final String message;
  final NutritionConfidence confidence;
  final String source;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  const NutritionInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.confidence,
    required this.source,
    required this.generatedAt,
    this.metadata = const <String, dynamic>{},
  });

  factory NutritionInsight.fromJson(Map<String, dynamic> json) {
    return NutritionInsight(
      id: json['id']?.toString() ?? 'nutrition_insight',
      title: json['title']?.toString() ?? 'Nutrition Insight',
      message: json['message']?.toString() ?? '',
      confidence: _confidenceFromString(json['confidence']?.toString()),
      source: json['source']?.toString() ?? 'nutrition_coach',
      generatedAt:
          DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.now(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'confidence': confidence.label,
      'source': source,
      'generated_at': generatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  NutritionInsight copyWith({
    String? id,
    String? title,
    String? message,
    NutritionConfidence? confidence,
    String? source,
    DateTime? generatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return NutritionInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      confidence: confidence ?? this.confidence,
      source: source ?? this.source,
      generatedAt: generatedAt ?? this.generatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class NutritionCoach {
  const NutritionCoach._();

  static List<NutritionInsight> buildCandidates({
    required NutritionAnalysis analysis,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final today = analysis.today.summary;
    final candidates = <NutritionInsight>[];

    if (analysis.inactiveLoggingDays >= 2) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Nutrition check-in',
          message:
              'One quick meal log today is enough to restart your nutrition pattern.',
          confidence: NutritionConfidence.high,
          source: 'nutrition_inactivity',
          metadata: {'inactive_days': analysis.inactiveLoggingDays},
        ),
      );
    }

    if (analysis.missingBreakfastDays >= 2) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Breakfast rhythm',
          message:
              'Breakfast is missing from a few recent logs. A light morning meal may help keep energy steady.',
          confidence: analysis.missingBreakfastDays >= 4
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          source: 'nutrition_pattern',
          metadata: {'missing_breakfast_days': analysis.missingBreakfastDays},
        ),
      );
    }

    if (_hasSweetSnack(today)) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Snack balance',
          message:
              'You might try pairing sweet snacks with fruit or yogurt today.',
          confidence: NutritionConfidence.medium,
          source: 'nutrition_balance',
          metadata: {'signal': 'sweet_snack_name_match'},
        ),
      );
    }

    if (_looksLowProtein(today)) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Protein idea',
          message:
              'Try adding protein like eggs, fish, tofu, beans, or chicken next meal.',
          confidence: NutritionConfidence.medium,
          source: 'nutrition_balance',
          metadata: {
            'protein_g': today.totalProteinG,
            'calories': today.totalCalories,
          },
        ),
      );
    }

    if (_couldUseProduce(today)) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Meal balance',
          message:
              'Adding fruits or vegetables can help balance your meals today.',
          confidence: NutritionConfidence.low,
          source: 'nutrition_balance',
          metadata: {'signal': 'no_produce_name_match'},
        ),
      );
    }

    if (analysis.irregularTimingDays >= 2) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Meal timing',
          message:
              'Keeping meal times roughly steady may help your energy feel more predictable.',
          confidence: analysis.irregularTimingDays >= 4
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          source: 'nutrition_timing',
          metadata: {'irregular_timing_days': analysis.irregularTimingDays},
        ),
      );
    }

    if (today.meals.isNotEmpty) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Balanced energy',
          message:
              'A steady mix of protein, carbs, and fats can support your energy today.',
          confidence: NutritionConfidence.low,
          source: 'nutrition_balance',
        ),
      );
    }

    return candidates;
  }

  static List<NutritionInsight> buildAssistantCandidates({
    required NutritionAnalysis analysis,
    NutritionInsight? baseInsight,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final candidates = <NutritionInsight>[];
    final macroInsight = NutritionMacroNudgeBuilder.bestInsight(
      analysis: analysis,
      now: generatedAt,
    );

    if (macroInsight != null) {
      candidates.add(macroInsight);
    }

    if (analysis.noMealsLoggedToday) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Nutrition check-in',
          message:
              'If energy feels low, a balanced meal today may help steady it.',
          confidence: analysis.confidence,
          source: 'nutrition_assistant',
        ),
      );
    }

    if (analysis.missingBreakfastDays >= 2) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Nutrition check-in',
          message:
              'A light breakfast could be worth trying on a low-energy morning.',
          confidence: analysis.confidence,
          source: 'nutrition_assistant',
        ),
      );
    }

    if (baseInsight != null && baseInsight.message.trim().isNotEmpty) {
      candidates.add(
        baseInsight.copyWith(
          id: 'assistant_${baseInsight.id}',
          title: 'Nutrition check-in',
          source: 'nutrition_assistant',
          generatedAt: generatedAt,
        ),
      );
    }

    candidates.add(
      _insight(
        generatedAt: generatedAt,
        title: 'Nutrition check-in',
        message: 'A simple, balanced meal can be a small support for today.',
        confidence: NutritionConfidence.low,
        source: 'nutrition_assistant',
      ),
    );

    return candidates;
  }

  static NutritionInsight _insight({
    required DateTime generatedAt,
    required String title,
    required String message,
    required NutritionConfidence confidence,
    required String source,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final dateKey = generatedAt.toIso8601String().substring(0, 10);
    final safeSource = source.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');

    return NutritionInsight(
      id: '${dateKey}_$safeSource',
      title: title,
      message: message,
      confidence: confidence,
      source: source,
      generatedAt: generatedAt,
      metadata: metadata,
    );
  }

  static bool _looksLowProtein(DailyNutritionSummary summary) {
    if (summary.meals.isEmpty || summary.totalCalories < 300) {
      return false;
    }

    final proteinCalories = summary.totalProteinG * 4;
    final proteinShare = summary.totalCalories == 0
        ? 0
        : proteinCalories / summary.totalCalories;

    return summary.totalProteinG < 20 || proteinShare < 0.12;
  }

  static bool _couldUseProduce(DailyNutritionSummary summary) {
    if (summary.meals.isEmpty) {
      return false;
    }

    final foodNames = _foodNames(summary).join(' ');
    if (foodNames.trim().isEmpty) {
      return false;
    }

    return !_producePattern.hasMatch(foodNames);
  }

  static bool _hasSweetSnack(DailyNutritionSummary summary) {
    final snackNames = summary.meals
        .where((meal) => meal.mealType == 'snack')
        .expand((meal) => meal.items)
        .map((item) => item.foodName.toLowerCase())
        .join(' ');

    return _sweetSnackPattern.hasMatch(snackNames);
  }

  static Iterable<String> _foodNames(DailyNutritionSummary summary) {
    return summary.meals.expand(
      (meal) => meal.items.map((item) => item.foodName.toLowerCase()),
    );
  }

  static final RegExp _producePattern = RegExp(
    r'\b(fruit|apple|banana|orange|mango|berry|vegetable|salad|greens|spinach|kangkong|pechay|broccoli|carrot|tomato|beans|lentil|oats)\b',
  );

  static final RegExp _sweetSnackPattern = RegExp(
    r'\b(candy|chocolate|cookie|cake|donut|doughnut|soda|soft drink|juice|ice cream|sweet|dessert|brownie)\b',
  );
}

class NutritionMacroNudgeBuilder {
  const NutritionMacroNudgeBuilder._();

  static const List<String> proteinFoods = [
    'eggs',
    'chicken',
    'tuna or fish',
    'tofu',
    'beans',
    'Greek yogurt',
  ];
  static const List<String> carbFiberFoods = [
    'rice',
    'oats',
    'sweet potato',
    'banana',
    'whole-grain bread',
  ];
  static const List<String> healthyFatFoods = [
    'avocado',
    'nuts',
    'peanut butter',
    'olive oil',
    'eggs',
  ];
  static const List<String> produceFoods = [
    'leafy vegetables',
    'carrots',
    'tomatoes',
    'fruit',
  ];

  static NutritionInsight? bestInsight({
    required NutritionAnalysis analysis,
    DateTime? now,
    Set<String> dismissedMacroFocuses = const <String>{},
  }) {
    final generatedAt = now ?? DateTime.now();
    final candidates = buildInsights(analysis: analysis, now: generatedAt)
        .where(
          (candidate) => !dismissedMacroFocuses.contains(
            candidate.metadata['macro_focus'],
          ),
        );

    final ranked = candidates.toList()
      ..sort((left, right) {
        final leftScore = _metadataDouble(left, 'selection_score');
        final rightScore = _metadataDouble(right, 'selection_score');
        return rightScore.compareTo(leftScore);
      });

    if (ranked.isNotEmpty) {
      return ranked.first;
    }

    final fallback = buildInsights(analysis: analysis, now: generatedAt);
    return fallback.isEmpty ? null : fallback.first;
  }

  static List<NutritionInsight> buildInsights({
    required NutritionAnalysis analysis,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    final summary = analysis.today.summary;
    final dateKey = generatedAt.toIso8601String().substring(0, 10);
    final candidates = <NutritionInsight>[];

    if (summary.meals.isEmpty || summary.totalCalories < 50) {
      return [
        _macroInsight(
          generatedAt: generatedAt,
          dateKey: dateKey,
          macroFocus: 'complete_meal',
          title: 'Build a simple plate',
          message:
              'No meals are logged yet. For your next meal, aim for protein, a fiber-rich carb, and produce, such as eggs with rice and leafy vegetables.',
          recommendedFoods: const ['eggs', 'rice', 'leafy vegetables', 'fruit'],
          score: 1,
          confidence: NutritionConfidence.low,
          summary: summary,
          metadata: const {'meal_signal': 'no_meals_logged'},
        ),
      ];
    }

    final shares = _macroShares(summary);

    if (shares.protein < 0.18 || summary.totalProteinG < 25) {
      final score = [
        0.20 - shares.protein,
        if (summary.totalProteinG < 25) 0.08,
      ].reduce((value, next) => value > next ? value : next);
      candidates.add(
        _macroInsight(
          generatedAt: generatedAt,
          dateKey: dateKey,
          macroFocus: 'protein',
          title: 'Add protein next',
          message:
              'Protein looks light compared with the rest of today\'s macros. At your next meal, add eggs, chicken, tuna or fish, tofu, beans, or Greek yogurt to make the plate steadier.',
          recommendedFoods: proteinFoods,
          score: score,
          confidence: score >= 0.12
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          summary: summary,
          metadata: {'protein_share': shares.protein},
        ),
      );
    }

    if (shares.carbs < 0.36) {
      final score = 0.42 - shares.carbs;
      candidates.add(
        _macroInsight(
          generatedAt: generatedAt,
          dateKey: dateKey,
          macroFocus: 'carbs_fiber',
          title: 'Add fiber-rich carbs',
          message:
              'Carbs are low in today\'s balance. A simple option like rice, oats, sweet potato, banana, or whole-grain bread can add steady energy.',
          recommendedFoods: carbFiberFoods,
          score: score,
          confidence: score >= 0.12
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          summary: summary,
          metadata: {'carbs_share': shares.carbs},
        ),
      );
    }

    if (shares.fat < 0.18) {
      final score = 0.22 - shares.fat;
      candidates.add(
        _macroInsight(
          generatedAt: generatedAt,
          dateKey: dateKey,
          macroFocus: 'healthy_fats',
          title: 'Add healthy fats',
          message:
              'Fat is low in today\'s macro mix. Add a small serving of avocado, nuts, peanut butter, olive oil, or eggs with your next meal.',
          recommendedFoods: healthyFatFoods,
          score: score,
          confidence: score >= 0.10
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          summary: summary,
          metadata: {'fat_share': shares.fat},
        ),
      );
    }

    if (shares.carbs > 0.58) {
      candidates.add(
        _macroInsight(
          generatedAt: generatedAt,
          dateKey: dateKey,
          macroFocus: 'protein_produce',
          title: 'Balance carbs with protein',
          message:
              'Carbs are carrying most of today\'s macros. Balance the next meal with protein and produce, such as eggs, tofu, chicken, leafy vegetables, tomatoes, or fruit.',
          recommendedFoods: const [
            'eggs',
            'tofu',
            'chicken',
            'leafy vegetables',
            'carrots',
            'tomatoes',
            'fruit',
          ],
          score: shares.carbs - 0.50,
          confidence: shares.carbs >= 0.68
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          summary: summary,
          metadata: {'carbs_share': shares.carbs},
        ),
      );
    }

    if (shares.fat > 0.42) {
      candidates.add(
        _macroInsight(
          generatedAt: generatedAt,
          dateKey: dateKey,
          macroFocus: 'fiber_produce',
          title: 'Lighten the next plate',
          message:
              'Fat is taking a large share today. Balance the next meal with fiber-rich carbs and produce like oats, sweet potato, rice, leafy vegetables, tomatoes, or fruit.',
          recommendedFoods: const [
            'oats',
            'sweet potato',
            'rice',
            'leafy vegetables',
            'carrots',
            'tomatoes',
            'fruit',
          ],
          score: shares.fat - 0.34,
          confidence: shares.fat >= 0.52
              ? NutritionConfidence.high
              : NutritionConfidence.medium,
          summary: summary,
          metadata: {'fat_share': shares.fat},
        ),
      );
    }

    if (!_hasProduceSignal(summary)) {
      candidates.add(
        _macroInsight(
          generatedAt: generatedAt,
          dateKey: dateKey,
          macroFocus: 'produce',
          title: 'Add produce',
          message:
              'Produce is missing from today\'s logged foods. Add leafy vegetables, carrots, tomatoes, or fruit to bring in fiber and color.',
          recommendedFoods: produceFoods,
          score: 0.09,
          confidence: NutritionConfidence.low,
          summary: summary,
          metadata: const {'produce_signal': 'not_found_in_food_names'},
        ),
      );
    }

    candidates.add(
      _macroInsight(
        generatedAt: generatedAt,
        dateKey: dateKey,
        macroFocus: 'balanced_plate',
        title: 'Keep the plate balanced',
        message:
            'Your macros look reasonably balanced today. Keep the next meal simple with protein, fiber-rich carbs, healthy fats, and produce.',
        recommendedFoods: const ['eggs', 'rice', 'avocado', 'leafy vegetables'],
        score: 0.01,
        confidence: NutritionConfidence.low,
        summary: summary,
      ),
    );

    return candidates;
  }

  static NutritionInsight _macroInsight({
    required DateTime generatedAt,
    required String dateKey,
    required String macroFocus,
    required String title,
    required String message,
    required List<String> recommendedFoods,
    required double score,
    required NutritionConfidence confidence,
    required DailyNutritionSummary summary,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return NutritionInsight(
      id: '${dateKey}_nutrition_$macroFocus',
      title: title,
      message: message,
      confidence: confidence,
      source: 'nutrition_assistant',
      generatedAt: generatedAt,
      metadata: {
        'macro_focus': macroFocus,
        'recommended_foods': recommendedFoods,
        'ai_enhanced': false,
        'deterministic_title': title,
        'deterministic_message': message,
        'total_calories': summary.totalCalories,
        'total_protein_g': summary.totalProteinG,
        'total_carbs_g': summary.totalCarbsG,
        'total_fat_g': summary.totalFatG,
        'selection_score': double.parse(score.toStringAsFixed(3)),
        ...metadata,
      },
    );
  }

  static _MacroShares _macroShares(DailyNutritionSummary summary) {
    final proteinCalories = summary.totalProteinG * 4;
    final carbCalories = summary.totalCarbsG * 4;
    final fatCalories = summary.totalFatG * 9;
    final macroCalories = proteinCalories + carbCalories + fatCalories;
    final denominator = macroCalories > 0
        ? macroCalories
        : summary.totalCalories;

    if (denominator <= 0) {
      return const _MacroShares(protein: 0, carbs: 0, fat: 0);
    }

    return _MacroShares(
      protein: proteinCalories / denominator,
      carbs: carbCalories / denominator,
      fat: fatCalories / denominator,
    );
  }

  static bool _hasProduceSignal(DailyNutritionSummary summary) {
    final names = summary.meals
        .expand((meal) => meal.items)
        .map((item) => item.foodName.toLowerCase())
        .join(' ');

    if (names.trim().isEmpty) {
      return false;
    }

    return _producePattern.hasMatch(names);
  }

  static double _metadataDouble(NutritionInsight insight, String key) {
    final value = insight.metadata[key];
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static final RegExp _producePattern = RegExp(
    r'\b(fruit|apple|banana|orange|mango|berry|vegetable|salad|greens|spinach|kangkong|pechay|broccoli|carrot|tomato|beans|lentil|okra|cabbage)\b',
  );
}

class _MacroShares {
  final double protein;
  final double carbs;
  final double fat;

  const _MacroShares({
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

NutritionConfidence _confidenceFromString(String? value) {
  switch (value) {
    case 'high':
      return NutritionConfidence.high;
    case 'medium':
      return NutritionConfidence.medium;
    default:
      return NutritionConfidence.low;
  }
}
