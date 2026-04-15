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
  final bool onboardingCompleted;
  final bool isDemoMode;

  const UserSessionSnapshot({
    required this.userId,
    required this.username,
    required this.email,
    required this.age,
    required this.gender,
    required this.userType,
    required this.onboardingCompleted,
    required this.isDemoMode,
  });

  bool get isLoggedIn => userId != null && email != null && email!.isNotEmpty;

  UserSessionSnapshot copyWith({
    int? userId,
    String? username,
    String? email,
    int? age,
    String? gender,
    String? userType,
    bool? onboardingCompleted,
    bool? isDemoMode,
  }) {
    return UserSessionSnapshot(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      userType: userType ?? this.userType,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }

  static const empty = UserSessionSnapshot(
    userId: null,
    username: null,
    email: null,
    age: null,
    gender: null,
    userType: null,
    onboardingCompleted: false,
    isDemoMode: false,
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
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _demoModeKey = 'demo_mode_enabled';

  Future<UserSessionSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSessionSnapshot(
      userId: prefs.getInt(_userIdKey),
      username: prefs.getString(_usernameKey),
      email: prefs.getString(_emailKey),
      age: prefs.getInt(_ageKey),
      gender: prefs.getString(_genderKey),
      userType: prefs.getString(_userTypeKey),
      onboardingCompleted: prefs.getBool(_onboardingCompletedKey) ?? false,
      isDemoMode: prefs.getBool(_demoModeKey) ?? false,
    );
  }

  Future<void> saveUser(Map<String, dynamic> user, {bool isDemoMode = false}) async {
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
    await prefs.setBool(_demoModeKey, isDemoMode);
  }

  Future<void> enableDemoMode() async {
    await saveUser(
      const {
        'user_id': 0,
        'username': 'Demo User',
        'email': 'demo@vitalysync.app',
        'age': 24,
        'gender': 'Other',
        'user_type': 'Student',
        'onboarding_completed': true,
      },
      isDemoMode: true,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_ageKey);
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_demoModeKey);
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String username,
    required String email,
    int? age,
    String? gender,
    String? userType,
    required bool isDemoMode,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'username': username.trim(),
      'email': email.trim(),
      'age': age,
      'gender': _normalizedNullable(gender),
      'user_type': _normalizedNullable(userType),
    };

    if (isDemoMode) {
      final user = Map<String, dynamic>.from(payload);
      await saveUser(user, isDemoMode: true);
      await saveSupplementalProfile(
        age: age,
        gender: gender,
        userType: userType,
      );
      return user;
    }

    final response = await http.put(
      Uri.parse(ApiConfig.auth('/profile')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }

    final user = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
    await saveUser(user, isDemoMode: false);
    await saveSupplementalProfile(
      age: age,
      gender: gender,
      userType: userType,
    );
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
}
