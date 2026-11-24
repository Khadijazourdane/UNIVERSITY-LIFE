import 'package:university_life/features/admin/notifications/models/admin_notification_model.dart';
import 'package:university_life/features/admin/services/admin_api.dart';

class AdminNotificationService {
  AdminNotificationService({AdminApi? api}) : _api = api ?? AdminApi.shared;

  static const _path = '/admin/notifications';

  final AdminApi _api;

  Future<List<AdminNotification>> fetchAll() =>
      _api.fetchAll(_path, AdminNotification.fromJson);

  /// [groupId] null ou vide : l'annonce est envoyée à tous les étudiants.
  Future<void> publish({
    required String title,
    required String message,
    String? groupId,
  }) => _api.post(_path, {
    'title': title,
    'message': message,
    'groupId': (groupId == null || groupId.isEmpty) ? null : groupId,
  });
}
