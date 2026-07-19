import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStore {
  AuthTokenStore({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
    bool? useSecureStorage,
  }) : _secureStorage = secureStorage,
       _useSecureStorage = useSecureStorage ?? _shouldUseSecureStorage();

  static final AuthTokenStore instance = AuthTokenStore();

  static const String tokenKey = 'auth_access_token';
  static const Duration _secureStorageTimeout = Duration(seconds: 1);

  final FlutterSecureStorage _secureStorage;
  final bool _useSecureStorage;

  Future<String?> readToken() async {
    if (_useSecureStorage) {
      final secureToken = await _readSecureToken();
      if (_hasValue(secureToken)) {
        return secureToken!.trim();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(tokenKey)?.trim();
    if (!_hasValue(legacyToken)) {
      return null;
    }

    return legacyToken;
  }

  Future<void> saveToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await clearToken();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_useSecureStorage && await _tryWriteSecureToken(normalizedToken)) {
      await prefs.remove(tokenKey);
      return;
    }

    await prefs.setString(tokenKey, normalizedToken);
  }

  Future<void> clearToken() async {
    if (_useSecureStorage) {
      await _tryDeleteSecureToken();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<String?> _readSecureToken() async {
    try {
      return await _secureStorage
          .read(key: tokenKey)
          .timeout(_secureStorageTimeout);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on TimeoutException {
      return null;
    }
  }

  Future<bool> _tryWriteSecureToken(String token) async {
    try {
      await _secureStorage
          .write(key: tokenKey, value: token)
          .timeout(_secureStorageTimeout);
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> _tryDeleteSecureToken() async {
    try {
      await _secureStorage.delete(key: tokenKey).timeout(_secureStorageTimeout);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    } on TimeoutException {
      return;
    }
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool _shouldUseSecureStorage() {
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return !kIsWeb && !bindingType.contains('TestWidgetsFlutterBinding');
  }
}
