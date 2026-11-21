abstract final class UniversityEmailValidator {
  static final RegExp _emailFormatPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );
  static const String _universityDomain = 'edu.uiz.ac.ma';

  static String? validate(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Veuillez saisir votre adresse universitaire.';
    }

    if (!_emailFormatPattern.hasMatch(email)) {
      return 'Veuillez saisir une adresse email valide.';
    }

    final domain = email.substring(email.lastIndexOf('@') + 1).toLowerCase();
    if (domain != _universityDomain) {
      return 'Utilisez une adresse se terminant par @edu.uiz.ac.ma.';
    }

    return null;
  }
}
