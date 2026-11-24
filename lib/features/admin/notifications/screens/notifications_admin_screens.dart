import 'package:flutter/material.dart';
import 'package:university_life/features/admin/groupes/services/group_service.dart';
import 'package:university_life/features/admin/notifications/models/admin_notification_model.dart';
import 'package:university_life/features/admin/notifications/services/admin_notification_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class NotificationsAdminScreen extends StatelessWidget {
  const NotificationsAdminScreen({super.key});

  Future<bool> _openForm(
      BuildContext context,
      AdminNotificationService service,
      ) async {
    final groups = await GroupService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: 'Nouvelle annonce',
      submitLabel: 'Publier',
      fields: [
        const AdminField(key: 'title', label: 'Titre'),
        const AdminField(
          key: 'message',
          label: 'Message',
          type: AdminFieldType.multiline,
        ),
        AdminField(
          key: 'groupId',
          label: 'Destinataires',
          type: AdminFieldType.dropdown,
          required: false,
          initialValue: '',
          options: [
            const AdminOption(value: '', label: 'Tous les étudiants'),
            for (final group in groups)
              AdminOption(value: group.id, label: group.name),
          ],
        ),
      ],
    );
    if (values == null) return false;

    await service.publish(
      title: values['title']!,
      message: values['message']!,
      groupId: values['groupId'],
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = AdminNotificationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AdminListView<AdminNotification>(
        load: service.fetchAll,
        titleOf: (notification) => notification.title,
        subtitleOf: (notification) =>
        '${notification.audience}'
            '${notification.sentAt.isEmpty ? '' : ' · ${notification.sentAt}'}'
            '\n${notification.message}',
        icon: Icons.campaign_outlined,
        addLabel: 'Publier une annonce',
        emptyMessage: 'Aucune annonce publiée.',
        errorMessage: 'Impossible de charger les annonces.',
        onCreate: (context) => _openForm(context, service),
        onView: (context, notification) => showAdminDetailsDialog(
          context,
          title: notification.title,
          rows: {
            'Destinataires': notification.audience,
            'Date d’envoi': notification.sentAt,
            'Message': notification.message,
          },
        ),
      ),
    );
  }
}
