import '../models/teacher_module_model.dart';

/// Données fictives en mémoire (à remplacer par `ApiClient`).
class TeacherModuleService {
  static const List<TeacherModule> _modules = [
    TeacherModule(
      id: 'm1',
      name: 'Programmation mobile',
      code: 'INF301',
      groups: ['G1', 'G2'],
    ),
    TeacherModule(
      id: 'm2',
      name: 'Bases de données',
      code: 'INF205',
      groups: ['G1'],
    ),
  ];

  Future<List<TeacherModule>> fetchModules() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _modules;
  }
}
