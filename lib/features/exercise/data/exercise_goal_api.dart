import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import 'exercise_goal_model.dart';

class ExerciseGoalApi {
  static const Duration _requestTimeout = Duration(seconds: 8);

  static Future<ExerciseGoalModel?> fetchToday({
    required int userId,
    required String logDate,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.exerciseGoals('/today/$userId')}?date=$logDate',
          ),
          headers: {'Accept': 'application/json'},
        )
        .timeout(_requestTimeout);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200) {
      throw ExerciseGoalApiException(
        data['message']?.toString() ?? 'Failed to fetch exercise goal',
        response.statusCode,
      );
    }

    final goal = data['goal'];
    if (goal is Map) {
      return ExerciseGoalModel.fromJson(Map<String, dynamic>.from(goal));
    }

    return null;
  }

  static Future<ExerciseGoalModel> choose({
    required int userId,
    required ExerciseGoalModel goal,
  }) {
    return _sendGoal(
      method: 'POST',
      path: '/choose',
      userId: userId,
      body: goal.toChooseJson(),
    );
  }

  static Future<ExerciseGoalModel> updateProgress({
    required int userId,
    required String logDate,
    required double distanceMeters,
  }) {
    return _sendGoal(
      method: 'PUT',
      path: '/progress',
      userId: userId,
      body: {'log_date': logDate, 'distance_meters': distanceMeters},
    );
  }

  static Future<ExerciseGoalModel> complete({
    required int userId,
    required String logDate,
  }) {
    return _sendGoal(
      method: 'PUT',
      path: '/complete',
      userId: userId,
      body: {'log_date': logDate},
    );
  }

  static Future<ExerciseGoalModel> cancel({
    required int userId,
    required String logDate,
  }) {
    return _sendGoal(
      method: 'PUT',
      path: '/cancel',
      userId: userId,
      body: {'log_date': logDate},
    );
  }

  static Future<ExerciseGoalModel> _sendGoal({
    required String method,
    required String path,
    required int userId,
    required Map<String, dynamic> body,
  }) async {
    final request =
        http.Request(method, Uri.parse(ApiConfig.exerciseGoals(path)))
          ..headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({'user_id': userId, ...body});

    final streamedResponse = await request.send().timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decodeResponseMap(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ExerciseGoalApiException(
        data['message']?.toString() ?? 'Failed to update exercise goal',
        response.statusCode,
      );
    }

    final goal = data['goal'];
    if (goal is Map) {
      return ExerciseGoalModel.fromJson(Map<String, dynamic>.from(goal));
    }

    throw const ExerciseGoalApiException(
      'Exercise goal response is missing goal data',
      500,
    );
  }

  static Map<String, dynamic> _decodeResponseMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Fall through to a readable fallback message.
    }

    return {'message': response.reasonPhrase ?? 'Unexpected server response'};
  }
}

class ExerciseGoalApiException implements Exception {
  final String message;
  final int statusCode;

  const ExerciseGoalApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
