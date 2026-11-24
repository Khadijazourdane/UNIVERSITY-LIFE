import '../models/teacher_notification_model.dart';

/// Données fictives en mémoire (à remplacer par `ApiClient`).
class TeacherNotificationService {
  final List<TeacherNotificationModel> _items = [
    TeacherNotificationModel(
      id: 'n1',
      title: 'Nouveau groupe affecté',
      body: 'Le groupe G2 vous a été affecté pour Programmation mobile.',
      date: DateTime(2026, 11, 20),
    ),
    TeacherNotificationModel(
      id: 'n2',
      title: 'Changement d\'horaire',
      body: 'La séance du 24/11 est déplacée à 10h00.',
      date: DateTime(2026, 11, 18),
      isRead: true,
    ),
  ];

  Future<List<TeacherNotificationModel>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<TeacherNotificationModel>.from(_items);
  }

  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index != -1) _items[index] = _items[index].markAsRead();
  }
}
