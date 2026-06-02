import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/offline_cache_store.dart';
import 'exercise_goal_model.dart';

class ExerciseGoalApi {
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const String _historyCache = 'exercise_goal_history';

  static Future<ExerciseGoalModel?> fetchToday({
    required int userId,
    required String logDate,
  }) async {
    final response = await http
        .get(
          Uri.parse(
            '${ApiConfig.exerciseGoals('/today/$userId')}?date=$logDate',
          ),
          headers: await ApiConfig.acceptJsonHeaders(),
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

  static Future<List<ExerciseGoalModel>> fetchHistory({
    required int userId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.exerciseGoals('/history/$userId')}?start=$startDate&end=$endDate',
            ),
            headers: await ApiConfig.acceptJsonHeaders(),
          )
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);

      if (response.statusCode != 200) {
        return await _readCachedHistory(userId, startDate, endDate);
      }

      final goals = data['goals'];
      if (goals is! List) {
        return const [];
      }

      await OfflineCacheStore.saveJson(
        namespace: _historyCache,
        scope: _historyScope(userId, startDate, endDate),
        data: {'goals': goals},
      );
      return _parseGoals(goals);
    } catch (_) {
      return _readCachedHistory(userId, startDate, endDate);
    }
  }

  static Future<ExerciseGoalModel> _sendGoal({
    required String method,
    required String path,
    required int userId,
    required Map<String, dynamic> body,
  }) async {
    final request =
        http.Request(method, Uri.parse(ApiConfig.exerciseGoals(path)))
          ..headers.addAll(await ApiConfig.jsonHeaders())
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

  static Future<List<ExerciseGoalModel>> _readCachedHistory(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _historyCache,
      scope: _historyScope(userId, startDate, endDate),
    );
    final goals = data?['goals'];
    if (goals is! List) {
      return const [];
    }

    return _parseGoals(goals);
  }

  static List<ExerciseGoalModel> _parseGoals(List<dynamic> goals) {
    return goals
        .whereType<Map>()
        .map(
          (item) => ExerciseGoalModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static String _historyScope(int userId, String startDate, String endDate) {
    return '${userId}_${startDate}_$endDate';
  }
}

class ExerciseGoalApiException implements Exception {
  final String message;
  final int statusCode;

  const ExerciseGoalApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
