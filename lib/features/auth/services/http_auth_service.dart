import 'package:dio/dio.dart';

import 'package:university_life/core/network/api_client.dart';
import 'package:university_life/core/network/api_exception.dart';
import 'package:university_life/core/network/auth_platform.dart';
import 'package:university_life/core/storage/session_token_store.dart';
import 'package:university_life/features/auth/models/auth_session.dart';
import 'package:university_life/features/auth/services/auth_service.dart';

class HttpAuthService implements AuthService {
  HttpAuthService(ApiClient client, {this._tokenStore})
    : _client = client,
      _origin = Uri.parse(client.dio.options.baseUrl).origin {
    if (!Uri.parse(_origin).isScheme('https')) {
      throw ArgumentError('L’API Auth doit utiliser HTTPS.');
    }
  }

  final ApiClient _client;
  final SessionTokenStore? _tokenStore;
  final String _origin;
  bool get _usesCookie => _tokenStore == null;

  static const _sessionInvalid = ApiException(
    kind: ApiFailureKind.http,
    statusCode: 401,
    code: 'SESSION_INVALID',
  );
  static const _invalidResponse = ApiException(
    kind: ApiFailureKind.unknown,
    code: 'INVALID_AUTH_RESPONSE',
  );

  Future<Object?> _request(
    String action, {
    String method = 'POST',
    String? token,
    Map<String, String>? body,
    required int status,
  }) async {
    // Endpoints are private constants at the call sites and the base origin is
    // fixed at construction, even if another caller changes Dio’s baseUrl.
    final target = Uri.parse('$_origin/api/auth/$action');
    try {
      final response = await _client.dio.requestUri<Object?>(
        target,
        data: body,
        options: Options(
          method: method,
          responseType: ResponseType.json,
          contentType: body == null ? null : Headers.jsonContentType,
          followRedirects: false,
          maxRedirects: 0,
          validateStatus: (code) => code == status,
          headers: {
            if (method == 'POST')
              'X-Session-Transport': _usesCookie ? 'cookie' : 'bearer',
            if (!_usesCookie && token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  AuthSession _decodeSession(Object? payload) {
    if (payload is! Map<String, dynamic>) throw _invalidResponse;
    final user = payload['user'];
    final role = switch (user is Map<String, dynamic> ? user['role'] : null) {
      'etudiant' => UserRole.student,
      'professeur' => UserRole.teacher,
      'admin' => UserRole.administrator,
      _ => throw _invalidResponse,
    };
    final date = payload['expiresAt'];
    final expiresAt = date is String ? DateTime.tryParse(date) : null;
    if (expiresAt == null || !expiresAt.isUtc) throw _invalidResponse;
    if (!expiresAt.isAfter(DateTime.now())) throw _sessionInvalid;
    return AuthSession(role: role, expiresAt: expiresAt);
  }

  @override
  Future<AuthSession> signIn({
    required String universityEmail,
    required String password,
  }) async {
    final payload = await _request(
      'login',
      status: 200,
      body: {
        'email': universityEmail.trim().toLowerCase(),
        'password': password,
      },
    );
    final session = _decodeSession(payload);
    final store = _tokenStore;
    if (store == null) {
      setCookieSessionClosed(_origin, false);
    } else {
      final token = (payload as Map<String, dynamic>)['accessToken'];
      if (token is! String ||
          token.length != 43 ||
          !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(token)) {
        throw _invalidResponse;
      }
      await store.write(token);
    }
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (_usesCookie && isCookieSessionClosed(_origin)) return null;
    final token = await _tokenStore?.read();
    if (!_usesCookie && token == null) return null;
    try {
      return _decodeSession(
        await _request('me', method: 'GET', status: 200, token: token),
      );
    } on ApiException catch (error) {
      if (_usesCookie && error.statusCode == 401) return null;
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _tokenStore?.read();
    if (!_usesCookie && token == null) throw _sessionInvalid;
    await _request(
      'change-password',
      status: 204,
      token: token,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<void> signOut() async {
    await _request('logout', status: 204, token: await _tokenStore?.read());
  }

  @override
  Future<void> forgetSession() async {
    final store = _tokenStore;
    if (store == null) {
      setCookieSessionClosed(_origin, true);
    } else {
      await store.clear();
    }
  }

  @override
  Future<void> requestPasswordRecovery({
    required String universityEmail,
  }) async {
    throw const ApiException(
      kind: ApiFailureKind.unknown,
      code: 'RECOVERY_UNAVAILABLE',
    );
  }
}
