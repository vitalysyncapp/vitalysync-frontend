import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';

class AccountLifecycleException implements Exception {
  final String message;
  final String? code;

  const AccountLifecycleException(this.message, {this.code});

  @override
  String toString() => message;
}

class AccountReactivationChallenge {
  final String reactivationToken;
  final DateTime reactivationDeadline;
  final DateTime retentionExpiresAt;

  const AccountReactivationChallenge({
    required this.reactivationToken,
    required this.reactivationDeadline,
    required this.retentionExpiresAt,
  });

  static AccountReactivationChallenge? fromLoginResponse(
    int statusCode,
    Map<String, dynamic> data,
  ) {
    if (statusCode != 423 ||
        data['code']?.toString() != 'ACCOUNT_REACTIVATION_REQUIRED') {
      return null;
    }
    final token = data['reactivation_token']?.toString().trim() ?? '';
    final deadline = DateTime.tryParse(
      data['reactivation_deadline']?.toString() ?? '',
    );
    final retention = DateTime.tryParse(
      data['retention_expires_at']?.toString() ?? '',
    );
    if (token.isEmpty || deadline == null || retention == null) {
      return null;
    }
    return AccountReactivationChallenge(
      reactivationToken: token,
      reactivationDeadline: deadline,
      retentionExpiresAt: retention,
    );
  }
}

class AccountLifecycleApi {
  AccountLifecycleApi({http.Client? client})
    : _client = client ?? http.Client();

  static final AccountLifecycleApi instance = AccountLifecycleApi();

  final http.Client _client;

  Future<void> deactivate({
    required String currentPassword,
    required String confirmation,
  }) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.account('/deactivate')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({
        'current_password': currentPassword.trim(),
        'confirmation': confirmation.trim(),
      }),
    );
    _requireSuccess(response, 'Unable to deactivate this account.');
  }

  Future<Map<String, dynamic>> reactivate(
    AccountReactivationChallenge challenge,
  ) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.account('/reactivate')),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'reactivation_token': challenge.reactivationToken}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw AccountLifecycleException(
        data['message']?.toString() ?? 'Unable to reactivate this account.',
        code: data['code']?.toString(),
      );
    }
    return data;
  }

  Future<void> clearData({required String currentPassword}) async {
    final response = await _client.delete(
      Uri.parse(ApiConfig.account('/data')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({'current_password': currentPassword.trim()}),
    );
    _requireSuccess(response, 'Unable to clear this account data.');
  }

  void _requireSuccess(http.Response response, String fallback) {
    if (response.statusCode == 200) {
      return;
    }
    final data = _decode(response.body);
    throw AccountLifecycleException(
      data['message']?.toString() ?? fallback,
      code: data['code']?.toString(),
    );
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
