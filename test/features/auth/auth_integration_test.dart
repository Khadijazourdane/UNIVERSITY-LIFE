import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:university_life/app.dart';
import 'package:university_life/core/navigation/app_routes.dart';
import 'package:university_life/core/network/api_client.dart';
import 'package:university_life/core/network/api_exception.dart';
import 'package:university_life/core/storage/session_token_store.dart';
import 'package:university_life/features/admin/dashboard/screens/admin_dashboard_screen.dart';
import 'package:university_life/features/auth/models/auth_session.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';
import 'package:university_life/features/auth/screens/login_screen.dart';
import 'package:university_life/features/auth/services/http_auth_service.dart';
import 'package:university_life/features/student/dashboard/screens/student_dashboard_screen.dart';
import 'package:university_life/features/teacher/teacher_shell.dart';

const _token = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
const _email = 'exemple@edu.uiz.ac.ma';
const _password = 'mot-de-passe-du-test';

class _MemoryStore implements SessionTokenStore {
  _MemoryStore([this.token]);
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

typedef _Responder = FutureOr<ResponseBody> Function(RequestOptions);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final _Responder reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async => reply(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, Object?> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody _session(String role, {bool login = false, DateTime? expiresAt}) =>
    _json(200, {
      'user': {'role': role},
      'expiresAt':
          (expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 1)))
              .toIso8601String(),
      if (login) 'accessToken': _token,
    });

ResponseBody _error(int status, String code) => _json(status, {
  'error': {
    'code': code,
    'message': 'Ce message brut ne doit pas être affiché.',
  },
});

HttpAuthService _service(SessionTokenStore? store, _Responder reply) {
  final client = ApiClient(baseUri: Uri.parse('https://auth.example.test'));
  client.dio.httpClientAdapter = _Adapter(reply);
  return HttpAuthService(client, tokenStore: store);
}

Future<void> _submitLogin(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), _email);
  await tester.enterText(fields.at(1), _password);
  final button = find.text('Se connecter →');
  await tester.ensureVisible(button);
  await tester.tap(button);
}

void main() {
  test('isolates native secure storage per origin', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = SecureSessionTokenStore(
      Uri.parse('https://first.example.test'),
    );
    final second = SecureSessionTokenStore(
      Uri.parse('https://second.example.test'),
    );
    await first.write(_token);
    expect(await second.read(), isNull);
    expect(await first.read(), _token);
    await first.clear();
    expect(await first.read(), isNull);
  });

  test(
    'pins Auth requests to the HTTPS origin and rejects redirects',
    () async {
      final store = _MemoryStore(_token);
      final client = ApiClient(baseUri: Uri.parse('https://auth.example.test'));
      client.dio.httpClientAdapter = _Adapter((options) {
        expect(options.uri.origin, 'https://auth.example.test');
        expect(options.uri.path, '/api/auth/me');
        expect(options.followRedirects, isFalse);
        expect(options.headers['Authorization'], 'Bearer $_token');
        expect(options.responseType, ResponseType.json);
        return ResponseBody.fromString(
          '',
          307,
          headers: {
            'location': ['https://other.example.test'],
          },
        );
      });
      final service = HttpAuthService(client, tokenStore: store);
      client.dio.options.baseUrl = 'https://other.example.test';
      await expectLater(
        service.restoreSession(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 307)),
      );
      expect(store.token, _token);
      expect(
        () => HttpAuthService(
          ApiClient(baseUri: Uri.parse('http://auth.example.test')),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'uses the cookie transport without an Authorization header or local token',
    () async {
      final service = _service(null, (options) {
        expect(options.headers['Authorization'], isNull);
        if (options.method == 'POST') {
          expect(options.headers['X-Session-Transport'], 'cookie');
        }
        if (options.uri.path.endsWith('/logout')) {
          return ResponseBody.fromString('', 204);
        }
        return _session('professeur');
      });
      expect(
        (await service.signIn(
          universityEmail: _email,
          password: _password,
        )).role,
        UserRole.teacher,
      );
      expect((await service.restoreSession())?.role, UserRole.teacher);
      await service.signOut();
    },
  );

  test(
    'an unknown role leaves the user signed out and the token unstored',
    () async {
      final store = _MemoryStore();
      final provider = AuthProvider(
        service: _service(store, (_) => _session('administrator', login: true)),
      );
      addTearDown(provider.dispose);
      await provider.signIn(universityEmail: _email, password: _password);
      expect(provider.state.isAuthenticated, isFalse);
      expect(provider.message, contains('session non reconnue'));
      expect(store.token, isNull);
    },
  );

  test('restoration retries a network failure, retains the token and accepts only me', () async {
    final store = _MemoryStore(_token);
    var attempts = 0;
    final provider = AuthProvider(
      service: _service(store, (options) {
        expect(options.uri.path, '/api/auth/me');
        expect(options.headers['Authorization'], 'Bearer $_token');
        if (++attempts == 1) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return _session('admin');
      }),
    );
    addTearDown(provider.dispose);
    await provider.restoreSession();
    expect(provider.state.isAuthenticated, isFalse);
    expect(provider.canRetryRestore, isTrue);
    expect(store.token, _token);
    await provider.restoreSession();
    expect(provider.state.session?.role, UserRole.administrator);
    expect(provider.canRetryRestore, isFalse);
  });

  test('a confirmed 401 during restoration clears the token', () async {
    final store = _MemoryStore(_token);
    final provider = AuthProvider(
      service: _service(store, (_) => _error(401, 'SESSION_INVALID')),
    );
    addTearDown(provider.dispose);
    await provider.restoreSession();
    expect(store.token, isNull);
    expect(provider.state.isAuthenticated, isFalse);
    expect(provider.message, contains('expiré'));
  });

  test('sign-out can close locally when remote revocation fails', () async {
    final store = _MemoryStore(_token);
    final provider = AuthProvider(
      service: _service(store, (options) {
        if (options.method == 'GET') return _session('etudiant');
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }),
    );
    addTearDown(provider.dispose);
    await provider.restoreSession();
    await provider.signOut();
    expect(provider.canCloseLocally, isTrue);
    expect(store.token, _token);
    await provider.closeSessionLocally();
    expect(store.token, isNull);
    expect(provider.state.isAuthenticated, isFalse);
    expect(provider.message, contains('n’a pas été confirmée'));
  });

  for (final (status, code, notice) in [
    (401, 'SESSION_INVALID', 'session a expiré'),
    (409, 'PASSWORD_UPDATE_CONFLICT', 'déjà changé'),
    (422, 'CURRENT_PASSWORD_INVALID', 'actuel incorrect'),
    (429, 'RATE_LIMITED', 'Trop de tentatives'),
    (204, '', 'Mot de passe modifié'),
  ]) {
    test('password change handles HTTP $status', () async {
      final store = _MemoryStore(_token);
      final provider = AuthProvider(
        service: _service(store, (options) {
          if (options.method == 'GET') return _session('etudiant');
          expect(options.uri.path, '/api/auth/change-password');
          expect(options.headers['X-Session-Transport'], 'bearer');
          expect(options.headers['Authorization'], 'Bearer $_token');
          expect(options.data, {
            'currentPassword': _password,
            'newPassword': 'nouveau-test',
          });
          return status == 204
              ? ResponseBody.fromString('', 204)
              : _error(status, code);
        }),
      );
      addTearDown(provider.dispose);
      await provider.restoreSession();
      await provider.changePassword(
        currentPassword: _password,
        newPassword: 'nouveau-test',
      );
      expect(provider.message, contains(notice));
      expect(store.token, status == 204 || status == 401 ? isNull : _token);
    });
  }

  for (final (role, screen, path) in [
    ('etudiant', StudentDashboardScreen, AppRoutes.studentPath),
    ('professeur', TeacherShell, AppRoutes.teacherPath),
    ('admin', AdminDashboardScreen, AppRoutes.administratorPath),
  ]) {
    testWidgets('login opens only the space for $role', (tester) async {
      final store = _MemoryStore();
      final service = _service(store, (options) {
        if (options.uri.path.endsWith('/logout')) {
          return ResponseBody.fromString('', 204);
        }
        expect(options.uri.path, '/api/auth/login');
        expect(options.headers['X-Session-Transport'], 'bearer');
        expect(options.data, {'email': _email, 'password': _password});
        return _session(role, login: true);
      });
      await tester.pumpWidget(UniversityLifeApp(authService: service));
      await tester.pumpAndSettle();
      await _submitLogin(tester);
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
      final router = GoRouter.of(tester.element(find.byType(screen)));
      expect(router.routeInformationProvider.value.uri.path, path);
      if (role == 'admin') {
        await tester.tap(find.byTooltip('Se déconnecter'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(store.token, isNull);
        router.go(AppRoutes.administratorPath);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(router.canPop(), isFalse);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'repeated login taps send one request and render the public error',
    (tester) async {
      final pending = Completer<ResponseBody>();
      var calls = 0;
      final service = _service(_MemoryStore(), (options) {
        calls++;
        return pending.future;
      });
      await tester.pumpWidget(UniversityLifeApp(authService: service));
      await tester.pumpAndSettle();
      await _submitLogin(tester);
      await tester.pump();
      final button = find.widgetWithText(FilledButton, 'Se connecter →');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.tap(button);
      pending.complete(_error(401, 'INVALID_CREDENTIALS'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Adresse ou mot de passe incorrect.'), findsOneWidget);
      expect(
        find.text('Ce message brut ne doit pas être affiché.'),
        findsNothing,
      );
    },
  );

  testWidgets('the account menu connects the existing change-password screen', (
    tester,
  ) async {
    final store = _MemoryStore(_token);
    var changes = 0;
    final service = _service(store, (options) {
      if (options.method == 'GET') return _session('admin');
      expect(options.uri.path, '/api/auth/change-password');
      expect(options.headers['Authorization'], 'Bearer $_token');
      expect(options.data, {
        'currentPassword': _password,
        'newPassword': 'nouveau-test',
      });
      changes++;
      return ResponseBody.fromString('', 204);
    });
    await tester.pumpWidget(UniversityLifeApp(authService: service));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changer le mot de passe'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), _password);
    await tester.enterText(fields.at(1), 'nouveau-test');
    await tester.enterText(fields.at(2), 'nouveau-test');
      final button = find.widgetWithText(FilledButton, 'Changer le mot de passe');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(changes, 1);
    expect(store.token, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('Mot de passe modifié. Reconnectez-vous.'),
      findsOneWidget,
    );
  });
}
