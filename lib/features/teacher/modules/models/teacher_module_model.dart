/// Module enseigné par le professeur.
class TeacherModule {
  const TeacherModule({
    required this.id,
    required this.name,
    required this.code,
    required this.groups,
    this.gradeScale = 20,
  });

  final String id;
  final String name;
  final String code;
  final List<String> groups;

  /// Barème maximal des notes (0 ≤ note ≤ barème).
  final double gradeScale;
}
