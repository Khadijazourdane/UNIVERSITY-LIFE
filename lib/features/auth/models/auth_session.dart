enum UserRole { student, teacher, administrator }

/// Domain session data that is independent from any API JSON representation.
///
/// The role values are domain concepts; mapping them from the backend response
/// must be implemented only after the response contract is confirmed.
class AuthSession {
  const AuthSession({required this.role});

  final UserRole role;
}
