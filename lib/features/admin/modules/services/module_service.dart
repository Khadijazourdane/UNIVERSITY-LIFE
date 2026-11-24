import 'package:university_life/features/admin/modules/models/module_model.dart';
import 'package:university_life/features/admin/services/admin_api.dart';

class ModuleService {
  ModuleService({AdminApi? api}) : _api = api ?? AdminApi.shared;

  static const _path = '/admin/modules';

  final AdminApi _api;

  Future<List<CourseModule>> fetchAll() =>
      _api.fetchAll(_path, CourseModule.fromJson);

  Future<void> create(Map<String, Object?> data) => _api.post(_path, data);

  Future<void> update(String id, Map<String, Object?> data) =>
      _api.put('$_path/$id', data);

  Future<void> delete(String id) => _api.delete('$_path/$id');
}
