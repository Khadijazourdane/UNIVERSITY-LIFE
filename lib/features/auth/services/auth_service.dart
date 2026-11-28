import 'package:university_life/features/auth/models/auth_session.dart';

/// Auth operations used by the provider, independent of HTTP and storage.
abstract interface class AuthService {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> signIn({
    required String universityEmail,
    required String password,
  });

  Future<void> requestPasswordRecovery({required String universityEmail});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signOut();

  /// Forget the local credential or suppress cookie restoration on this browser.
  Future<void> forgetSession();
}
