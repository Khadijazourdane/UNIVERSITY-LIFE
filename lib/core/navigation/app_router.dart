import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:university_life/core/navigation/app_routes.dart';
import 'package:university_life/features/auth/models/auth_session.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';
import 'package:university_life/features/auth/screens/change_password_screen.dart';
import 'package:university_life/features/auth/screens/forgot_password_screen.dart';
import 'package:university_life/features/auth/screens/login_screen.dart';
import 'package:university_life/features/student/dashboard/screens/student_dashboard_screen.dart';
import 'package:university_life/features/teacher/teacher_shell.dart';
import 'package:university_life/shared/widgets/app_button.dart';

abstract final class AppRouter {
  static GoRouter create({required AuthProvider authProvider}) {
    return GoRouter(
      initialLocation: AppRoutes.loginPath,
      refreshListenable: authProvider,
      redirect: (context, state) =>
          redirectFor(authProvider.state, state.matchedLocation),
      routes: [
        GoRoute(path: '/', redirect: (context, state) => AppRoutes.loginPath),
        GoRoute(
          path: AppRoutes.loginPath,
          name: AppRoutes.loginName,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPasswordPath,
          name: AppRoutes.forgotPasswordName,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.changePasswordPath,
          name: AppRoutes.changePasswordName,
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentPath,
          name: AppRoutes.studentName,
          builder: (context, state) => const StudentDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.teacherPath,
          name: AppRoutes.teacherName,
          builder: (context, state) => const TeacherShell(),   
        ),
        GoRoute(
          path: AppRoutes.administratorPath,
          name: AppRoutes.administratorName,
          builder: (context, state) =>
              const _RoleSpacePendingScreen(roleLabel: 'administrateur'),
        ),
      ],
      errorBuilder: (context, state) => const _UnknownRouteScreen(),
    );
  }

  /// Pure redirect policy, exposed so the route rules can be tested directly.
  static String? redirectFor(AuthState authState, String location) {
    const publicLocations = {AppRoutes.loginPath, AppRoutes.forgotPasswordPath};
    const protectedLocations = {
      AppRoutes.changePasswordPath,
      AppRoutes.studentPath,
      AppRoutes.teacherPath,
      AppRoutes.administratorPath,
    };
    const knownLocations = {'/', ...publicLocations, ...protectedLocations};

    if (!knownLocations.contains(location)) return null;

    final session = authState.isAuthenticated ? authState.session : null;
    if (session == null) {
      return protectedLocations.contains(location) ? AppRoutes.loginPath : null;
    }

    final homePath = _homePathFor(session.role);
    if (location == '/' || publicLocations.contains(location)) {
      return homePath;
    }

    final requiredRole = _roleForLocation(location);
    if (requiredRole != null && requiredRole != session.role) {
      return homePath;
    }

    return null;
  }

  static String _homePathFor(UserRole role) => switch (role) {
    UserRole.student => AppRoutes.studentPath,
    UserRole.teacher => AppRoutes.teacherPath,
    UserRole.administrator => AppRoutes.administratorPath,
  };

  static UserRole? _roleForLocation(String location) => switch (location) {
    AppRoutes.studentPath => UserRole.student,
    AppRoutes.teacherPath => UserRole.teacher,
    AppRoutes.administratorPath => UserRole.administrator,
    _ => null,
  };
}

class _RoleSpacePendingScreen extends StatelessWidget {
  const _RoleSpacePendingScreen({required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Espace $roleLabel')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'L’écran métier de cet espace reste à intégrer.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cette page n’existe pas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Retour à la connexion',
                onPressed: () => context.go(AppRoutes.loginPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
