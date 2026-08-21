import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthTokenValidity { missing, valid, expired, malformed }

class AuthTokenInspection {
  const AuthTokenInspection(this.validity, {this.expiresAt});

  final AuthTokenValidity validity;
  final DateTime? expiresAt;
}

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
        final normalizedSecureToken = secureToken!.trim();
        await _saveFallbackToken(normalizedSecureToken);
        return normalizedSecureToken;
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

    await _saveFallbackToken(normalizedToken);

    if (_useSecureStorage) {
      await _tryWriteSecureToken(normalizedToken);
    }
  }

  Future<void> clearToken() async {
    if (_useSecureStorage) {
      await _tryDeleteSecureToken();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<AuthTokenInspection> inspectStoredToken({DateTime? now}) async {
    return inspectToken(await readToken(), now: now);
  }

  AuthTokenInspection inspectToken(String? token, {DateTime? now}) {
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      return const AuthTokenInspection(AuthTokenValidity.missing);
    }

    try {
      final parts = normalizedToken.split('.');
      if (parts.length != 3) {
        return const AuthTokenInspection(AuthTokenValidity.malformed);
      }

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(payloadJson);
      if (payload is! Map<String, dynamic>) {
        return const AuthTokenInspection(AuthTokenValidity.malformed);
      }

      final rawExpiration = payload['exp'];
      final expirationSeconds = rawExpiration is int
          ? rawExpiration
          : int.tryParse(rawExpiration?.toString() ?? '');
      if (expirationSeconds == null || expirationSeconds <= 0) {
        return const AuthTokenInspection(AuthTokenValidity.malformed);
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expirationSeconds * Duration.millisecondsPerSecond,
        isUtc: true,
      );
      final effectiveNow = (now ?? DateTime.now()).toUtc();
      return AuthTokenInspection(
        !expiresAt.isAfter(effectiveNow)
            ? AuthTokenValidity.expired
            : AuthTokenValidity.valid,
        expiresAt: expiresAt,
      );
    } on FormatException {
      return const AuthTokenInspection(AuthTokenValidity.malformed);
    } on RangeError {
      return const AuthTokenInspection(AuthTokenValidity.malformed);
    }
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

  Future<void> _saveFallbackToken(String token) async {
    // Keep a fallback for cold starts and background entry points where secure
    // storage can be temporarily unavailable.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool _shouldUseSecureStorage() {
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return !kIsWeb && !bindingType.contains('TestWidgetsFlutterBinding');
  }
}
