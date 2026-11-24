import '../models/course_file_model.dart';

/// Données fictives en mémoire (à remplacer par `ApiClient`).
class TeacherCourseService {
  final List<CourseFileModel> _courses = [
    CourseFileModel(
      id: 'c1',
      moduleId: 'm1',
      title: 'Introduction à Flutter',
      fileName: 'intro_flutter.pdf',
      group: 'G1',
      publishedAt: DateTime(2026, 11, 10),
    ),
  ];

  Future<List<CourseFileModel>> fetchCourses(String moduleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _courses.where((c) => c.moduleId == moduleId).toList();
  }

  Future<void> publish({
    required String moduleId,
    required String title,
    required String fileName,
    required String group,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _courses.add(
      CourseFileModel(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        moduleId: moduleId,
        title: title,
        fileName: fileName,
        group: group,
        publishedAt: DateTime.now(),
      ),
    );
  }

  Future<void> delete(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _courses.removeWhere((c) => c.id == courseId);
  }
}
