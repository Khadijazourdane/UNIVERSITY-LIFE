import 'package:university_life/features/auth/models/auth_session.dart';

/// Application-level operations expected from the future backend integration.
///
/// This interface deliberately contains no endpoint paths or JSON field names.
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
}
