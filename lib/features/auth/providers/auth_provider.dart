import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:university_life/core/network/api_exception.dart';
import 'package:university_life/features/auth/models/auth_session.dart';
import 'package:university_life/features/auth/services/auth_service.dart';

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

enum _Operation { restore, signIn, changePassword, signOut, localSignOut }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    this._service,
    AuthState initialState = const AuthState.initializing(),
  }) : _state = initialState;

  final AuthService? _service;
  AuthState _state;
  Timer? _expiry;
  bool _disposed = false;
  bool _busy = false;
  bool _canRetryRestore = false;
  bool _canCloseLocally = false;
  String? _message;

  AuthState get state => _state;
  bool get isBusy => _busy;
  bool get canRetryRestore => _canRetryRestore;
  bool get canCloseLocally => _canCloseLocally;
  String? get message => _message;

  void updateState(AuthState state) {
    if (_disposed || identical(_state, state)) return;
    _expiry?.cancel();
    _state = state;
    final expiresAt = state.session?.expiresAt;
    if (state.isAuthenticated && expiresAt != null) {
      _expiry = Timer(expiresAt.difference(DateTime.now()), () {
        _message = 'Votre session a expiré. Reconnectez-vous.';
        updateState(const AuthState.unauthenticated());
      });
    }
    notifyListeners();
  }

  Future<void> restoreSession() async {
    if (_state.isAuthenticated || _disposed) return;
    if (_service == null) {
      _message =
          'L’API Auth est indisponible. Vérifiez la configuration HTTPS.';
      updateState(const AuthState.unauthenticated());
      return;
    }
    await _run(_Operation.restore, (service) async {
      final session = await service.restoreSession();
      updateState(
        session == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(session),
      );
    });
  }

  Future<void> signIn({
    required String universityEmail,
    required String password,
  }) async {
    if (_state.isAuthenticated) return;
    await _run(_Operation.signIn, (service) async {
      final session = await service.signIn(
        universityEmail: universityEmail,
        password: password,
      );
      updateState(AuthState.authenticated(session));
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!_state.isAuthenticated) return;
    await _run(_Operation.changePassword, (service) async {
      await service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _finishSignOut(service, 'Mot de passe modifié. Reconnectez-vous.');
    });
  }

  Future<void> signOut() async {
    if (!_state.isAuthenticated) return;
    await _run(_Operation.signOut, (service) async {
      await service.signOut();
      await _finishSignOut(service, 'Vous êtes déconnecté.');
    });
  }

  // The existing admin dashboard uses this entry point for its logout button.
  Future<void> clearLocalSession() async {
    if (_service == null) {
      updateState(const AuthState.unauthenticated());
      return;
    }
    await signOut();
  }

  Future<void> closeSessionLocally() async {
    if (!_canCloseLocally) return;
    await _run(_Operation.localSignOut, (service) async {
      await service.forgetSession();
      _message = 'Session fermée sur cet appareil. La révocation distante n’a pas été confirmée.';
      updateState(const AuthState.unauthenticated());
    });
  }

  Future<void> _finishSignOut(AuthService service, String message) async {
    _message = message;
    updateState(const AuthState.unauthenticated());
    try {
      await service.forgetSession();
    } catch (_) {
      _message = '$message Le nettoyage du stockage local a échoué.';
    }
  }

  Future<void> _run(
    _Operation operation,
    Future<void> Function(AuthService) action,
  ) async {
    if (_busy || _disposed) return;
    final service = _service;
    if (service == null) {
      _message =
          'L’API Auth est indisponible. Vérifiez la configuration HTTPS.';
      notifyListeners();
      return;
    }

    _busy = true;
    _message = null;
    _canRetryRestore = false;
    _canCloseLocally = false;
    if (operation == _Operation.restore) {
      _state = const AuthState.initializing();
    }
    if (operation == _Operation.signIn) {
      _state = const AuthState.authenticating();
    }
    notifyListeners();

    try {
      await action(service);
    } catch (error) {
      if (error is ApiException &&
          error.statusCode == 401 &&
          (operation == _Operation.restore ||
              operation == _Operation.changePassword)) {
        await _finishSignOut(
          service,
          'Votre session a expiré. Reconnectez-vous.',
        );
      } else {
        _message = _errorMessage(error);
        if (operation == _Operation.restore || operation == _Operation.signIn) {
          _canRetryRestore = operation == _Operation.restore;
          updateState(const AuthState.error());
        } else if (operation == _Operation.signOut ||
            operation == _Operation.localSignOut) {
          _canCloseLocally = true;
          _message = operation == _Operation.signOut
              ? 'La révocation distante n’a pas été confirmée. $_message'
              : 'Impossible de fermer la session sur cet appareil. Réessayez.';
        }
      }
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  String _errorMessage(Object error) {
    if (error is! ApiException) return 'L’opération a échoué. Réessayez.';
    if (error.isNetworkFailure) {
      return 'Connexion au serveur impossible. Réessayez.';
    }
    return switch (error.code) {
      'INVALID_CREDENTIALS' => 'Adresse ou mot de passe incorrect.',
      'INVALID_AUTH_RESPONSE' =>
        'Le serveur a renvoyé une session non reconnue.',
      'CURRENT_PASSWORD_INVALID' => 'Mot de passe actuel incorrect.',
      'PASSWORD_POLICY' => 'Le nouveau mot de passe doit être différent et compter entre 8 et 256 caractères.',
      'PASSWORD_UPDATE_CONFLICT' =>
        'Le mot de passe a déjà changé. Reconnectez-vous si nécessaire.',
      'RATE_LIMITED' => 'Trop de tentatives. Réessayez plus tard.',
      'AUTH_UNAVAILABLE' =>
        'Le service d’authentification est indisponible. Réessayez.',
      'HTTPS_REQUIRED' || 'ORIGIN_FORBIDDEN' =>
        'La configuration sécurisée de l’API doit être vérifiée.',
      'INVALID_REQUEST' => 'Vérifiez les informations saisies.',
      _ => switch (error.statusCode) {
        401 => 'Adresse ou mot de passe incorrect.',
        409 => 'Le mot de passe a déjà changé. Reconnectez-vous si nécessaire.',
        429 => 'Trop de tentatives. Réessayez plus tard.',
        _ => 'Le service d’authentification n’a pas pu traiter la demande.',
      },
    };
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    super.dispose();
  }
}
