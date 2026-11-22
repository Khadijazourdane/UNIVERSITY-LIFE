import 'package:flutter_test/flutter_test.dart';
import 'package:university_life/features/auth/models/auth_session.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';

void main() {
  test('starts in an uninitialized state without a session', () {
    final provider = AuthProvider();
    addTearDown(provider.dispose);

    expect(provider.state.status, AuthStatus.initializing);
    expect(provider.state.session, isNull);
    expect(provider.state.isAuthenticated, isFalse);
  });

  test('publishes a confirmed domain session to listeners', () {
    final provider = AuthProvider(
      initialState: const AuthState.unauthenticated(),
    );
    addTearDown(provider.dispose);
    var notifications = 0;
    provider.addListener(() => notifications++);

    provider.updateState(
      const AuthState.authenticated(AuthSession(role: UserRole.teacher)),
    );

    expect(provider.state.status, AuthStatus.authenticated);
    expect(provider.state.session?.role, UserRole.teacher);
    expect(provider.state.isAuthenticated, isTrue);
    expect(notifications, 1);
  });

  test('clears only the in-memory session on local sign-out', () {
    final provider = AuthProvider(
      initialState: const AuthState.authenticated(
        AuthSession(role: UserRole.student),
      ),
    );
    addTearDown(provider.dispose);

    provider.clearLocalSession();

    expect(provider.state.status, AuthStatus.unauthenticated);
    expect(provider.state.session, isNull);
  });

  test('represents the pending authentication and error states', () {
    expect(const AuthState.authenticating().status, AuthStatus.authenticating);
    expect(const AuthState.error().status, AuthStatus.error);
  });
}
