import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class UserSessionSnapshot {
  final int? userId;
  final String? username;
  final String? email;
  final int? age;
  final String? gender;
  final String? userType;
  final String? authToken;
  final bool onboardingCompleted;

  const UserSessionSnapshot({
    required this.userId,
    required this.username,
    required this.email,
    required this.age,
    required this.gender,
    required this.userType,
    required this.authToken,
    required this.onboardingCompleted,
  });

  bool get isLoggedIn => userId != null && email != null && email!.isNotEmpty;
  bool get hasAuthToken => authToken != null && authToken!.trim().isNotEmpty;

  static const empty = UserSessionSnapshot(
    userId: null,
    username: null,
    email: null,
    age: null,
    gender: null,
    userType: null,
    authToken: null,
    onboardingCompleted: false,
  );
}

class UserSessionController {
  UserSessionController._();

  static final UserSessionController instance = UserSessionController._();

  static const String _emailKey = 'email';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';
  static const String _genderKey = 'gender';
  static const String _ageKey = 'age';
  static const String _authTokenKey = 'auth_access_token';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _legacyDemoModeKey = 'demo_mode_enabled';

  Future<UserSessionSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_legacyDemoModeKey) == true) {
      await clearSession();
      return UserSessionSnapshot.empty;
    }

    return UserSessionSnapshot(
      userId: prefs.getInt(_userIdKey),
      username: prefs.getString(_usernameKey),
      email: prefs.getString(_emailKey),
      age: prefs.getInt(_ageKey),
      gender: prefs.getString(_genderKey),
      userType: prefs.getString(_userTypeKey),
      authToken: prefs.getString(_authTokenKey),
      onboardingCompleted: prefs.getBool(_onboardingCompletedKey) ?? false,
    );
  }

  Future<void> saveUser(Map<String, dynamic> user, {String? authToken}) async {
    final prefs = await SharedPreferences.getInstance();

    final dynamic rawUserId = user['user_id'];
    final dynamic rawAge = user['age'];

    if (rawUserId is int) {
      await prefs.setInt(_userIdKey, rawUserId);
    }

    await prefs.setString(_emailKey, (user['email'] ?? '').toString());
    await prefs.setString(_usernameKey, (user['username'] ?? '').toString());

    final parsedAge = rawAge is int ? rawAge : int.tryParse('${rawAge ?? ''}');
    if (parsedAge != null) {
      await prefs.setInt(_ageKey, parsedAge);
    } else {
      await prefs.remove(_ageKey);
    }

    final gender = (user['gender'] ?? '').toString().trim();
    final userType = (user['user_type'] ?? '').toString().trim();
    final onboardingCompleted = user['onboarding_completed'] == true;

    if (gender.isEmpty) {
      await prefs.remove(_genderKey);
    } else {
      await prefs.setString(_genderKey, gender);
    }

    if (userType.isEmpty) {
      await prefs.remove(_userTypeKey);
    } else {
      await prefs.setString(_userTypeKey, userType);
    }

    await prefs.setBool(_onboardingCompletedKey, onboardingCompleted);
    await prefs.remove(_legacyDemoModeKey);

    if (authToken != null && authToken.trim().isNotEmpty) {
      await prefs.setString(_authTokenKey, authToken.trim());
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_authTokenKey);
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_legacyDemoModeKey);
  }

  Future<void> reauthenticateWithPassword({required String password}) async {
    final session = await load();
    final email = session.email?.trim() ?? '';
    final normalizedPassword = password.trim();

    if (!session.isLoggedIn || email.isEmpty) {
      throw Exception(
        'Account re-authentication is only available for signed-in accounts.',
      );
    }

    if (normalizedPassword.isEmpty) {
      throw Exception('Password is required.');
    }

    final response = await http.post(
      Uri.parse(ApiConfig.auth('/login')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({'email': email, 'password': normalizedPassword}),
    );

    final data = _decodeResponseBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Password verification failed.');
    }

    final token = data['access_token']?.toString();
    if (token != null && token.isNotEmpty) {
      await saveUser(
        Map<String, dynamic>.from(data['user'] as Map<String, dynamic>),
        authToken: token,
      );
    }
  }

  Future<void> deleteAccount({required String password}) async {
    final session = await load();
    final email = session.email?.trim() ?? '';
    final normalizedPassword = password.trim();

    if (!session.isLoggedIn || session.userId == null) {
      throw Exception(
        'Delete account is only available for signed-in accounts.',
      );
    }

    if (email.isEmpty || normalizedPassword.isEmpty) {
      throw Exception('Email and password are required.');
    }

    final response = await http.delete(
      Uri.parse(ApiConfig.auth('/account')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode({
        'user_id': session.userId,
        'email': email,
        'password': normalizedPassword,
      }),
    );

    final data = _decodeResponseBody(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to delete account.');
    }

    await clearSession();
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String username,
    required String email,
    int? age,
    String? gender,
    String? userType,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'username': username.trim(),
      'email': email.trim(),
      'age': age,
      'gender': _normalizedNullable(gender),
      'user_type': _normalizedNullable(userType),
    };

    final response = await http.put(
      Uri.parse(ApiConfig.auth('/profile')),
      headers: await ApiConfig.jsonHeaders(),
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }

    final user = Map<String, dynamic>.from(
      data['user'] as Map<String, dynamic>,
    );
    await saveUser(user);
    await saveSupplementalProfile(age: age, gender: gender, userType: userType);
    return user;
  }

  Future<void> updateOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, value);
  }

  Future<void> saveSupplementalProfile({
    int? age,
    String? gender,
    String? userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (age != null) {
      await prefs.setInt(_ageKey, age);
    }

    final normalizedGender = _normalizedNullable(gender);
    final normalizedUserType = _normalizedNullable(userType);

    if (normalizedGender == null) {
      await prefs.remove(_genderKey);
    } else {
      await prefs.setString(_genderKey, normalizedGender);
    }

    if (normalizedUserType == null) {
      await prefs.remove(_userTypeKey);
    } else {
      await prefs.setString(_userTypeKey, normalizedUserType);
    }
  }

  String? _normalizedNullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return const <String, dynamic>{};
  }
}
