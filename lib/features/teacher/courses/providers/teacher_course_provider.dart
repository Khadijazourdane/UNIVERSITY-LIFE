import 'package:flutter/foundation.dart';

import '../models/course_file_model.dart';
import '../services/teacher_course_service.dart';

class TeacherCourseProvider extends ChangeNotifier {
  TeacherCourseProvider(this._service);

  final TeacherCourseService _service;

  List<CourseFileModel> courses = [];
  bool isLoading = false;
  String? error;

  Future<void> load(String moduleId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      courses = await _service.fetchCourses(moduleId);
    } catch (_) {
      error = 'Impossible de charger les cours.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Retourne `true` si la publication a réussi.
  Future<bool> publish({
    required String moduleId,
    required String title,
    required String fileName,
    required String group,
  }) async {
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      error = 'Seuls les fichiers PDF sont acceptés.';
      notifyListeners();
      return false;
    }
    try {
      await _service.publish(
        moduleId: moduleId,
        title: title,
        fileName: fileName,
        group: group,
      );
      await load(moduleId);
      return true;
    } catch (_) {
      error = 'La publication a échoué. Réessayez.';
      notifyListeners();
      return false;
    }
  }

  Future<void> delete(String moduleId, String courseId) async {
    await _service.delete(courseId);
    await load(moduleId);
  }
}
