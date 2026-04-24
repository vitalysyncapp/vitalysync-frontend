import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../shared/config/api_config.dart';
import '../../../shared/preferences/user_session.dart';

class NutritionReviewItem {
  String foodName;
  int? usdaFdcId;
  double servingQty;
  String servingUnit;
  double calories;
  double proteinG;
  double carbsG;
  double fatG;
  double? confidence;

  NutritionReviewItem({
    required this.foodName,
    required this.usdaFdcId,
    required this.servingQty,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
  });

  factory NutritionReviewItem.fromJson(Map<String, dynamic> json) {
    return NutritionReviewItem(
      foodName: (json['food_name'] ?? '').toString(),
      usdaFdcId: _parseNullableInt(json['usda_fdc_id']),
      servingQty: _parseDouble(json['serving_qty']),
      servingUnit: (json['serving_unit'] ?? 'serving').toString(),
      calories: _parseDouble(json['calories']),
      proteinG: _parseDouble(json['protein_g']),
      carbsG: _parseDouble(json['carbs_g']),
      fatG: _parseDouble(json['fat_g']),
      confidence: json['confidence'] == null
          ? null
          : _parseDouble(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName.trim(),
      'usda_fdc_id': usdaFdcId,
      'serving_qty': servingQty,
      'serving_unit': servingUnit.trim(),
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'confidence': confidence,
    };
  }
}

class NutritionMealLog {
  final int nutritionLogId;
  final String mealType;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final List<NutritionReviewItem> items;

  const NutritionMealLog({
    required this.nutritionLogId,
    required this.mealType,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.items,
  });

  factory NutritionMealLog.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List ? json['items'] as List : const [];

    return NutritionMealLog(
      nutritionLogId: _parseInt(json['nutrition_log_id']),
      mealType: (json['meal_type'] ?? '').toString(),
      totalCalories: _parseDouble(json['total_calories']),
      totalProteinG: _parseDouble(json['total_protein_g']),
      totalCarbsG: _parseDouble(json['total_carbs_g']),
      totalFatG: _parseDouble(json['total_fat_g']),
      items: rawItems
          .whereType<Map>()
          .map((item) => NutritionReviewItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class DailyNutritionSummary {
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final Map<String, bool> logged;
  final List<NutritionMealLog> meals;

  const DailyNutritionSummary({
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.logged,
    required this.meals,
  });

  factory DailyNutritionSummary.empty() {
    return const DailyNutritionSummary(
      totalCalories: 0,
      totalProteinG: 0,
      totalCarbsG: 0,
      totalFatG: 0,
      logged: {
        'breakfast': false,
        'lunch': false,
        'dinner': false,
        'snack': false,
      },
      meals: [],
    );
  }

  factory DailyNutritionSummary.fromJson(Map<String, dynamic> json) {
    final totals = json['day_totals'] is Map
        ? Map<String, dynamic>.from(json['day_totals'] as Map)
        : const <String, dynamic>{};
    final rawLogged = json['logged'] is Map
        ? Map<String, dynamic>.from(json['logged'] as Map)
        : const <String, dynamic>{};
    final rawMeals = json['meals'] is List ? json['meals'] as List : const [];

    return DailyNutritionSummary(
      totalCalories: _parseDouble(totals['total_calories']),
      totalProteinG: _parseDouble(totals['total_protein_g']),
      totalCarbsG: _parseDouble(totals['total_carbs_g']),
      totalFatG: _parseDouble(totals['total_fat_g']),
      logged: {
        'breakfast': rawLogged['breakfast'] == true,
        'lunch': rawLogged['lunch'] == true,
        'dinner': rawLogged['dinner'] == true,
        'snack': rawLogged['snack'] == true,
      },
      meals: rawMeals
          .whereType<Map>()
          .map((meal) => NutritionMealLog.fromJson(
                Map<String, dynamic>.from(meal),
              ))
          .toList(),
    );
  }
}

class NutritionAnalysisResult {
  final int attemptId;
  final List<NutritionReviewItem> items;

  const NutritionAnalysisResult({
    required this.attemptId,
    required this.items,
  });
}

class NutritionHistoryDay {
  final String logDate;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final int mealCount;

  const NutritionHistoryDay({
    required this.logDate,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.mealCount,
  });

  factory NutritionHistoryDay.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['log_date'] ?? '').toString();

    return NutritionHistoryDay(
      logDate: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      totalCalories: _parseDouble(json['total_calories']),
      totalProteinG: _parseDouble(json['total_protein_g']),
      totalCarbsG: _parseDouble(json['total_carbs_g']),
      totalFatG: _parseDouble(json['total_fat_g']),
      mealCount: _parseInt(json['meal_count']),
    );
  }
}

class NutritionApi {
  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static Future<int> _currentUserId() async {
    final session = await UserSessionController.instance.load();

    if (session.isDemoMode) {
      throw Exception('Nutrition image analysis is unavailable in demo mode.');
    }

    final userId = session.userId;
    if (userId == null || userId <= 0) {
      throw Exception('Please sign in before logging nutrition.');
    }

    return userId;
  }

  static Future<NutritionAnalysisResult> analyzeMeal({
    required File image,
    required String mealType,
    required String logDate,
  }) async {
    final userId = await _currentUserId();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.nutrition('/analyze')),
    );

    request.fields['user_id'] = userId.toString();
    request.fields['meal_type'] = mealType;
    request.fields['log_date'] = logDate;
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Food analysis failed.');
    }

    final rawAttempt = data['attempt'] is Map
        ? Map<String, dynamic>.from(data['attempt'] as Map)
        : const <String, dynamic>{};
    final rawItems = data['items'] is List ? data['items'] as List : const [];

    return NutritionAnalysisResult(
      attemptId: _parseInt(rawAttempt['attempt_id']),
      items: rawItems
          .whereType<Map>()
          .map((item) => NutritionReviewItem.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  static Future<void> confirmMeal({
    required int attemptId,
    required String mealType,
    required String logDate,
    required List<NutritionReviewItem> items,
    String notes = '',
  }) async {
    final userId = await _currentUserId();
    final response = await http.post(
      Uri.parse(ApiConfig.nutrition('/confirm')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'attempt_id': attemptId,
        'meal_type': mealType,
        'log_date': logDate,
        'items': items.map((item) => item.toJson()).toList(),
        'notes': notes,
      }),
    );
    final data = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to save nutrition log.');
    }
  }

  static Future<void> discardAttempt(int attemptId) async {
    final userId = await _currentUserId();
    final response = await http.post(
      Uri.parse(ApiConfig.nutrition('/discard-attempt')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'attempt_id': attemptId,
      }),
    );
    final data = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to cancel nutrition attempt.');
    }
  }

  static Future<DailyNutritionSummary> fetchDaily({String? date}) async {
    final userId = await _currentUserId();
    final logDate = date ?? todayKey();
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.nutrition('/daily')}?user_id=$userId&date=$logDate',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    final data = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load daily nutrition.');
    }

    return DailyNutritionSummary.fromJson(data);
  }

  static Future<List<NutritionHistoryDay>> fetchHistory({
    required String start,
    required String end,
  }) async {
    final userId = await _currentUserId();
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.nutrition('/history')}?user_id=$userId&start=$start&end=$end',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    final data = _decodeBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load nutrition history.');
    }

    final rawDays = data['days'] is List ? data['days'] as List : const [];
    return rawDays
        .whereType<Map>()
        .map((day) => NutritionHistoryDay.fromJson(
              Map<String, dynamic>.from(day),
            ))
        .toList();
  }

  static Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('${value ?? ''}') ?? 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

double _parseDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('${value ?? ''}') ?? 0;
}
