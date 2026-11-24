import 'package:university_life/features/admin/services/admin_api.dart';

/// Annonce publiée par l'administrateur. Sans groupe, elle vise tous les
/// étudiants.
class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    this.groupId = '',
    this.groupName = '',
    this.sentAt = '',
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) =>
      AdminNotification(
        id: asText(json['id']),
        title: asText(json['title']),
        message: asText(json['message']),
        groupId: asText(json['groupId']),
        groupName: asText(json['groupName']),
        sentAt: asText(json['sentAt']),
      );

  final String id;
  final String title;
  final String message;
  final String groupId;
  final String groupName;
  final String sentAt;

  String get audience => groupName.isEmpty ? 'Tous les étudiants' : groupName;
}
