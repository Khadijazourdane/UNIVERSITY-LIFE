import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:university_life/core/navigation/app_router.dart';
import 'package:university_life/core/navigation/app_routes.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/features/auth/models/auth_session.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';
import 'package:university_life/features/auth/screens/change_password_screen.dart';
import 'package:university_life/features/auth/screens/forgot_password_screen.dart';
import 'package:university_life/features/auth/screens/login_screen.dart';

Future<GoRouter> _pumpRouter(
  WidgetTester tester,
  AuthProvider authProvider,
) async {
  final router = AppRouter.create(authProvider: authProvider);
  addTearDown(() {
    router.dispose();
    authProvider.dispose();
  });
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  return router;
}

void main() {
  testWidgets('starts at login when the session is not initialized', (
    WidgetTester tester,
  ) async {
    final router = await _pumpRouter(tester, AuthProvider());

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loginPath);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('redirects an unauthenticated user away from protected spaces', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider(
      initialState: const AuthState.unauthenticated(),
    );
    final router = await _pumpRouter(tester, authProvider);

    router.go(AppRoutes.studentPath);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loginPath);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('keeps recovery public and supports returning to login', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider(
      initialState: const AuthState.unauthenticated(),
    );
    await _pumpRouter(tester, authProvider);

    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Retour à la connexion'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  test('redirects role routes according to the confirmed domain role', () {
    const rolePaths = {
      UserRole.student: AppRoutes.studentPath,
      UserRole.teacher: AppRoutes.teacherPath,
      UserRole.administrator: AppRoutes.administratorPath,
    };

    for (final role in UserRole.values) {
      final authState = AuthState.authenticated(AuthSession(role: role));
      final homePath = rolePaths[role]!;

      for (final entry in rolePaths.entries) {
        final redirect = AppRouter.redirectFor(authState, entry.value);
        expect(
          redirect,
          entry.key == role ? isNull : homePath,
          reason: '$role must not access ${entry.key} space.',
        );
      }
    }
  });

  testWidgets('opens the dashboard for an authenticated student', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider(
      initialState: const AuthState.authenticated(
        AuthSession(role: UserRole.student),
      ),
    );
    final router = await _pumpRouter(tester, authProvider);

    expect(find.text('Tableau de bord'), findsOneWidget);
    expect(find.text('Bonjour, Lina !'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Absences'), 100);
    expect(find.text('Absences'), findsOneWidget);

    router.go(AppRoutes.teacherPath);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.studentPath,
    );
    expect(find.text('Tableau de bord'), findsOneWidget);
  });

  testWidgets(
    'protects change-password and allows it for an authenticated role',
    (WidgetTester tester) async {
      final authProvider = AuthProvider(
        initialState: const AuthState.unauthenticated(),
      );
      final router = await _pumpRouter(tester, authProvider);

      router.go(AppRoutes.changePasswordPath);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      authProvider.updateState(
        const AuthState.authenticated(
          AuthSession(role: UserRole.administrator),
        ),
      );
      router.go(AppRoutes.changePasswordPath);
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    },
  );

  testWidgets('routes back to login after local session state is cleared', (
    WidgetTester tester,
  ) async {
    final authProvider = AuthProvider(
      initialState: const AuthState.authenticated(
        AuthSession(role: UserRole.administrator),
      ),
    );
    final router = await _pumpRouter(tester, authProvider);
    expect(find.text('Espace administrateur'), findsOneWidget);

    authProvider.clearLocalSession();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.loginPath);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('shows a recovery action for unknown locations', (
    WidgetTester tester,
  ) async {
    final router = await _pumpRouter(tester, AuthProvider());

    router.go('/unknown-location');
    await tester.pumpAndSettle();

    expect(find.text('Cette page n’existe pas.'), findsOneWidget);
    await tester.tap(find.text('Retour à la connexion'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
