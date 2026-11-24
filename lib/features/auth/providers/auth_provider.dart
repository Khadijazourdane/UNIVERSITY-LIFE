import 'package:flutter/foundation.dart';

import 'package:university_life/features/auth/models/auth_session.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

@immutable
class AuthState {
  const AuthState.initializing()
    : status = AuthStatus.initializing,
      session = null;

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      session = null;

  const AuthState.authenticating()
    : status = AuthStatus.authenticating,
      session = null;

  const AuthState.authenticated(AuthSession authenticatedSession)
    : status = AuthStatus.authenticated,
      session = authenticatedSession;

  const AuthState.error() : status = AuthStatus.error, session = null;

  final AuthStatus status;
  final AuthSession? session;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;
}

/// Holds authentication state; screens do not mark a form as authenticated.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthState initialState = const AuthState.initializing()})
    : _state = initialState;

  AuthState _state;

  AuthState get state => _state;

  /// Called by the future authentication service after a confirmed result.
  void updateState(AuthState state) {
    if (identical(_state, state)) return;
    _state = state;
    notifyListeners();
  }

  /// Clears only in-memory state; backend revocation still requires a contract.
  void clearLocalSession() {
    updateState(const AuthState.unauthenticated());
  }
}
