import '../models/grade_entry_model.dart';

/// Données fictives en mémoire (à remplacer par `ApiClient`).
class TeacherGradeService {
  final Map<String, Map<String, double>> _gradesByModule = {
    'm1': {'s1': 15.5, 's2': 12},
  };

  Future<List<GradeEntryModel>> fetchGrades(String moduleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final grades = _gradesByModule[moduleId] ?? {};
    return grades.entries
        .map((e) => GradeEntryModel(studentId: e.key, value: e.value))
        .toList();
  }

  Future<void> saveGrades(String moduleId, Map<String, double> grades) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _gradesByModule[moduleId] = Map<String, double>.from(grades);
  }
}
