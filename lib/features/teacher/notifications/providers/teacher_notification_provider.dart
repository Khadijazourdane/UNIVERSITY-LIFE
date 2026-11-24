import 'package:flutter/foundation.dart';

import '../models/teacher_notification_model.dart';
import '../services/teacher_notification_service.dart';

class TeacherNotificationProvider extends ChangeNotifier {
  TeacherNotificationProvider(this._service);

  final TeacherNotificationService _service;

  List<TeacherNotificationModel> notifications = [];
  bool isLoading = false;
  String? error;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      notifications = await _service.fetchNotifications();
    } catch (_) {
      error = 'Impossible de charger les notifications.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    await load();
  }
}
