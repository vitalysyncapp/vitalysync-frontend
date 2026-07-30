import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';

class PasswordResetApi {
  const PasswordResetApi._();

  static Future<String> requestCode(String email) async {
    final response = await http.post(
      Uri.parse(ApiConfig.auth('/password-reset/request')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Unable to send reset code.');
    }
    return data['message']?.toString() ??
        'If this email belongs to a VitalySync account, a password reset code has been sent.';
  }

  static Future<String> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse(ApiConfig.auth('/password-reset/verify-code')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({'email': email, 'code': code}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Unable to verify this code.');
    }
    final resetToken = data['reset_token']?.toString().trim() ?? '';
    if (resetToken.isEmpty) {
      throw Exception('The password reset session could not be started.');
    }
    return resetToken;
  }

  static Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.auth('/password-reset/confirm')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({
        'reset_token': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      }),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Unable to reset this password.');
    }
    return data['message']?.toString() ?? 'Password reset successfully.';
  }

  static Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return const {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}
