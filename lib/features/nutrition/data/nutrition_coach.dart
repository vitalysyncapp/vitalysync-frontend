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

    if (analysis.noMealsLoggedToday) {
      candidates.add(
        _insight(
          generatedAt: generatedAt,
          title: 'Nutrition check-in',
          message:
              'If energy feels low, a balanced meal today might help a bit 🙂',
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
