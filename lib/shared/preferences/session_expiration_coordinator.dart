import 'dart:async';

import 'auth_token_store.dart';
import 'user_session.dart';

typedef SessionExpiredCallback = Future<void> Function();

enum SessionExpirationCheck { active, signedOut, ended }

class SessionExpirationCoordinator {
  SessionExpirationCoordinator._();

  static final SessionExpirationCoordinator instance =
      SessionExpirationCoordinator._();

  Timer? _expirationTimer;
  SessionExpiredCallback? _onExpired;
  Future<SessionExpirationCheck>? _pendingCheck;
  bool _isHandlingExpiration = false;

  void configure({required SessionExpiredCallback onExpired}) {
    _onExpired = onExpired;
  }

  Future<SessionExpirationCheck> checkNow() async {
    final pendingCheck = _pendingCheck;
    if (pendingCheck != null) {
      return pendingCheck;
    }

    final check = _checkStoredSession();
    _pendingCheck = check;
    try {
      return await check;
    } finally {
      if (identical(_pendingCheck, check)) {
        _pendingCheck = null;
      }
    }
  }

  void cancel() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }

  void detach() {
    cancel();
    _onExpired = null;
  }

  Future<SessionExpirationCheck> _checkStoredSession() async {
    final session = await UserSessionController.instance.load();
    final inspection = AuthTokenStore.instance.inspectToken(session.authToken);

    if (inspection.validity == AuthTokenValidity.missing) {
      cancel();
      return session.isLoggedIn
          ? _endUnusableSession()
          : SessionExpirationCheck.signedOut;
    }

    if (inspection.validity != AuthTokenValidity.valid ||
        !session.isLoggedIn ||
        inspection.expiresAt == null) {
      cancel();
      return _endUnusableSession();
    }

    _scheduleExpiration(inspection.expiresAt!);
    return SessionExpirationCheck.active;
  }

  void _scheduleExpiration(DateTime expiresAt) {
    cancel();
    final remaining = expiresAt.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      unawaited(checkNow());
      return;
    }

    _expirationTimer = Timer(remaining, () => unawaited(checkNow()));
  }

  Future<SessionExpirationCheck> _endUnusableSession() async {
    if (_isHandlingExpiration) {
      return SessionExpirationCheck.ended;
    }

    _isHandlingExpiration = true;
    try {
      await _onExpired?.call();
    } finally {
      _isHandlingExpiration = false;
    }
    return SessionExpirationCheck.ended;
  }
}
