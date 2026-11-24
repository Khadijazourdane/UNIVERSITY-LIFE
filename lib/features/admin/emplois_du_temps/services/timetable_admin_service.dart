import 'package:university_life/features/admin/emplois_du_temps/models/timetable_slot_model.dart';
import 'package:university_life/features/admin/services/admin_api.dart';

class TimetableAdminService {
  TimetableAdminService({AdminApi? api}) : _api = api ?? AdminApi.shared;

  static const _path = '/admin/emplois-du-temps';

  final AdminApi _api;

  Future<List<TimetableSlot>> fetchAll() =>
      _api.fetchAll(_path, TimetableSlot.fromJson);

  Future<void> create(Map<String, Object?> data) => _api.post(_path, data);

  Future<void> update(String id, Map<String, Object?> data) =>
      _api.put('$_path/$id', data);

  Future<void> delete(String id) => _api.delete('$_path/$id');
}
