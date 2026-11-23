import 'package:flutter/foundation.dart';

import '../models/student_model.dart';
import '../services/teacher_student_service.dart';

class TeacherStudentProvider extends ChangeNotifier {
  TeacherStudentProvider(this._service);

  final TeacherStudentService _service;

  List<StudentModel> students = [];
  bool isLoading = false;
  String? error;

  Future<void> load(String moduleId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      students = await _service.fetchStudents(moduleId);
    } catch (_) {
      error = 'Impossible de charger les étudiants.';
    }
    isLoading = false;
    notifyListeners();
  }
}
