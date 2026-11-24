import 'package:flutter/foundation.dart';

import '../../students/models/student_model.dart';
import '../../students/services/teacher_student_service.dart';
import '../services/teacher_grade_service.dart';

class TeacherGradeProvider extends ChangeNotifier {
  TeacherGradeProvider(this._gradeService, this._studentService);

  final TeacherGradeService _gradeService;
  final TeacherStudentService _studentService;

  List<StudentModel> students = [];
  final Map<String, String> _inputs = {};
  double scale = 20;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load(String moduleId, double gradeScale) async {
    scale = gradeScale;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      students = await _studentService.fetchStudents(moduleId);
      final grades = await _gradeService.fetchGrades(moduleId);
      _inputs
        ..clear()
        ..addEntries(
          grades.where((g) => g.value != null).map(
            (g) => MapEntry(g.studentId, g.value.toString()),
          ),
        );
    } catch (_) {
      error = 'Impossible de charger les notes.';
    }
    isLoading = false;
    notifyListeners();
  }

  String initialText(String studentId) => _inputs[studentId] ?? '';

  void setInput(String studentId, String text) {
    _inputs[studentId] = text;
    notifyListeners();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  /// Règle : 0 ≤ note ≤ barème. Champ vide = note non saisie (pas zéro).
  String? errorFor(String studentId) {
    final text = (_inputs[studentId] ?? '').trim();
    if (text.isEmpty) return null;
    final value = _parse(text);
    if (value == null) return 'Note invalide.';
    if (value < 0 || value > scale) return 'Entre 0 et ${scale.toStringAsFixed(0)}.';
    return null;
  }

  bool get hasErrors => students.any((s) => errorFor(s.id) != null);

  Future<bool> save(String moduleId) async {
    if (hasErrors) return false;
    isSaving = true;
    notifyListeners();
    try {
      final grades = <String, double>{};
      for (final s in students) {
        final value = _parse(_inputs[s.id] ?? '');
        if (value != null) grades[s.id] = value;
      }
      await _gradeService.saveGrades(moduleId, grades);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      error = 'L\'enregistrement a échoué.';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
