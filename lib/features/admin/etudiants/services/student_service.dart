import 'package:university_life/features/admin/etudiants/models/student_model.dart';
import 'package:university_life/features/admin/services/admin_api.dart';
class StudentService {
  StudentService({AdminApi? api}) : _api = api ?? AdminApi.shared;

  static const _path = '/admin/etudiants';

  final AdminApi _api;

  Future<List<Student>> fetchAll() => _api.fetchAll(_path, Student.fromJson);
  Future<void> create(Map<String, Object?> data) => _api.post(_path, data);
  Future<void> update(String id, Map<String, Object?> data) =>
      _api.put('$_path/$id', data);

  Future<void> delete(String id) => _api.delete('$_path/$id');
  Future<void> assignGroup(String studentId, String groupId) => _api.put(
    '$_path/$studentId/groupe',
    {'groupId': groupId.isEmpty ? null : groupId},
  );
}
