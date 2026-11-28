enum UserRole { student, teacher, administrator }

/// Identity confirmed by the server, without credentials or transport data.
class AuthSession {
  const AuthSession({required this.role, this.expiresAt});

  final UserRole role;
  final DateTime? expiresAt;
}
