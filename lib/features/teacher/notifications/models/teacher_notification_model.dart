/// Notification reçue par le professeur (nouvelle demande, changement de module...).
class TeacherNotificationModel {
  const TeacherNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;

  TeacherNotificationModel markAsRead() => TeacherNotificationModel(
    id: id,
    title: title,
    body: body,
    date: date,
    isRead: true,
  );
}
