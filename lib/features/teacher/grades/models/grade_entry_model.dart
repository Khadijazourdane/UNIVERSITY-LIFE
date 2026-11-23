/// Note d'un étudiant pour un module. `value == null` : note non saisie.
class GradeEntryModel {
  const GradeEntryModel({required this.studentId, this.value});

  final String studentId;
  final double? value;
}
