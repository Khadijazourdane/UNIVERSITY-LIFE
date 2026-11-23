/// Informations académiques d'un étudiant visibles par le professeur.
class StudentModel {
  const StudentModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.filiere,
    required this.group,
  });

  final String id;
  final String fullName;
  final String email;
  final String filiere;
  final String group;
}
