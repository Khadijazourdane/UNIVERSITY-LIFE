import 'package:university_life/features/admin/semestres/models/semester_model.dart';
import 'package:university_life/features/admin/services/admin_api.dart';

class SemesterService {
  SemesterService({AdminApi? api}) : _api = api ?? AdminApi.shared;

  static const _path = '/admin/semestres';

  final AdminApi _api;

  Future<List<Semester>> fetchAll() => _api.fetchAll(_path, Semester.fromJson);

  Future<void> create(Map<String, Object?> data) => _api.post(_path, data);

  Future<void> update(String id, Map<String, Object?> data) =>
      _api.put('$_path/$id', data);

  Future<void> delete(String id) => _api.delete('$_path/$id');
}
