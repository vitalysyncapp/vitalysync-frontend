import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/config/api_config.dart';
import '../../../shared/offline/fetch_policy.dart';
import '../../../shared/preferences/user_session.dart';
import 'assessment_models.dart';

class AssessmentApiException implements Exception {
  final String message;
  final int status;
  final String? code;
  const AssessmentApiException(this.message, this.status, [this.code]);
  @override
  String toString() => message;
}

class AssessmentApi {
  final http.Client _client;
  AssessmentApi({http.Client? client}) : _client = client ?? http.Client();
  static final instance = AssessmentApi();

  Future<Map<String, String>> _headers(int userId) async {
    if ((await UserSessionController.instance.load()).userId != userId) {
      throw const AssessmentApiException(
        'Sign in to the account that completed this assessment.',
        401,
      );
    }
    return ApiConfig.jsonHeaders();
  }

  Map<String, dynamic> _decode(http.Response response) {
    final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AssessmentApiException(
        json['message']?.toString() ?? 'Assessment request failed.',
        response.statusCode,
        json['code']?.toString(),
      );
    }
    return json;
  }

  Future<AssessmentDefinition> definition(int userId) async {
    final response = await _client
        .get(
          Uri.parse(ApiConfig.assessments('/definition')),
          headers: await _headers(userId),
        )
        .timeout(ApiRequestTimeouts.standard);
    return AssessmentDefinition.fromJson(
      Map<String, dynamic>.from(_decode(response)['definition'] as Map),
    );
  }

  Future<Map<String, dynamic>> submit(
    int userId,
    AssessmentSubmission submission, {
    Map<String, dynamic>? profile,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
            profile == null
                ? ApiConfig.assessments('')
                : ApiConfig.onboarding('/submit'),
          ),
          headers: await _headers(userId),
          body: jsonEncode(
            profile == null
                ? submission.toJson()
                : {'profile': profile, 'assessment': submission.toJson()},
          ),
        )
        .timeout(ApiRequestTimeouts.standard);
    return _decode(response);
  }

  Future<AssessmentRecord?> latest(int userId) async {
    final response = await _client
        .get(
          Uri.parse(ApiConfig.assessments('/latest')),
          headers: await _headers(userId),
        )
        .timeout(ApiRequestTimeouts.standard);
    final record = _decode(response)['assessment'];
    return record == null
        ? null
        : AssessmentRecord.fromJson(Map<String, dynamic>.from(record as Map));
  }

  Future<AssessmentHistory> history(int userId, {String? cursor}) async {
    final uri = Uri.parse(
      ApiConfig.assessments('/history'),
    ).replace(queryParameters: {'cursor': ?cursor});
    final response = await _client
        .get(uri, headers: await _headers(userId))
        .timeout(ApiRequestTimeouts.standard);
    final json = _decode(response);
    return AssessmentHistory(
      (json['assessments'] as List)
          .map(
            (item) => AssessmentRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      json['next_cursor'] as String?,
    );
  }
}
