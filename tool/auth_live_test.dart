import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:university_life/core/config/app_config.dart';
import 'package:university_life/core/navigation/app_router.dart';
import 'package:university_life/core/navigation/app_routes.dart';
import 'package:university_life/core/network/api_client.dart';
import 'package:university_life/core/network/api_exception.dart';
import 'package:university_life/core/network/auth_platform.dart';
import 'package:university_life/core/storage/session_token_store.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';
import 'package:university_life/features/auth/services/http_auth_service.dart';

// The host-side Flutter test exercises live HTTPS. Native secure storage is
// replaced only here so a provider restart can use the same test credential.
class _TestStore implements SessionTokenStore {
  _TestStore([this.token]);
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

void main() {
  test('live Flutter Auth on the isolated PostgreSQL fixture', () async {
    final uri = AppConfig.apiBaseUri;
    if (uri.scheme != 'https' ||
        !{'127.0.0.1', 'localhost'}.contains(uri.host)) {
      throw StateError('The live test requires a local HTTPS API.');
    }
    final fixture = <String, String>{};
    for (final line in File('backend/.env.auth-test').readAsLinesSync()) {
      final separator = line.indexOf('=');
      if (separator > 0) {
        fixture[line.substring(0, separator)] = line.substring(separator + 1);
      }
    }
    if (fixture['PGDATABASE'] != 'university_life_auth_test' ||
        fixture['PGUSER'] != 'university_life_auth_test_app') {
      throw StateError('The live test requires the isolated Auth fixture.');
    }

    final client = ApiClient.fromConfig();
    configureAuthClient(client.dio);
    addTearDown(() => client.dio.close(force: true));

    for (final (role, path) in [
      ('ETUDIANT', AppRoutes.studentPath),
      ('PROFESSEUR', AppRoutes.teacherPath),
      ('ADMIN', AppRoutes.administratorPath),
    ]) {
      final store = _TestStore();
      final service = HttpAuthService(client, tokenStore: store);
      final provider = AuthProvider(service: service);
      addTearDown(provider.dispose);
      await provider.signIn(
        universityEmail: fixture['AUTH_TEST_${role}_EMAIL']!,
        password: fixture['AUTH_TEST_${role}_PASSWORD']!,
      );
      expect(provider.state.isAuthenticated, isTrue, reason: provider.message);
      expect(AppRouter.redirectFor(provider.state, AppRoutes.loginPath), path);
      final oldCredential = _TestStore(store.token);
      final restarted = AuthProvider(
        service: HttpAuthService(client, tokenStore: store),
      );
      addTearDown(restarted.dispose);
      expect(restarted.state.isAuthenticated, isFalse);
      await restarted.restoreSession();
      expect(
        restarted.state.isAuthenticated,
        isTrue,
        reason: restarted.message,
      );
      expect(AppRouter.redirectFor(restarted.state, AppRoutes.loginPath), path);
      await restarted.signOut();
      expect(restarted.state.isAuthenticated, isFalse);
      expect(store.token == null, isTrue);
      expect(AppRouter.redirectFor(restarted.state, path), AppRoutes.loginPath);
      final expired = AuthProvider(
        service: HttpAuthService(client, tokenStore: oldCredential),
      );
      addTearDown(expired.dispose);
      await expired.restoreSession();
      expect(expired.state.isAuthenticated, isFalse);
      expect(oldCredential.token == null, isTrue);
      expect(expired.message, contains('expiré'));
    }

    final email = fixture['AUTH_TEST_ETUDIANT_EMAIL']!;
    final original = fixture['AUTH_TEST_ETUDIANT_PASSWORD']!;
    final random = Random.secure();
    final replacement = List.generate(
      24,
      (_) => random.nextInt(36).toRadixString(36),
    ).join();
    final store = _TestStore();
    final service = HttpAuthService(client, tokenStore: store);
    final provider = AuthProvider(service: service);
    addTearDown(provider.dispose);
    await provider.signIn(universityEmail: email, password: original);
    expect(provider.state.isAuthenticated, isTrue, reason: provider.message);
    var changed = false;
    try {
      await service.changePassword(
        currentPassword: original,
        newPassword: replacement,
      );
      changed = true;
      await service.forgetSession();
      await expectLater(
        service.signIn(universityEmail: email, password: original),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'status',
            401,
          ),
        ),
      );
      final current = await service.signIn(
        universityEmail: email,
        password: replacement,
      );
      expect(current.role.name, 'student');
    } finally {
      if (changed) {
        if (await service.restoreSession() == null) {
          await service.signIn(universityEmail: email, password: replacement);
        }
        await service.changePassword(
          currentPassword: replacement,
          newPassword: original,
        );
        await service.forgetSession();
      }
    }
    expect(
      (await service.signIn(
        universityEmail: email,
        password: original,
      )).role.name,
      'student',
    );
    await service.signOut();
    await service.forgetSession();
  });
}
