import 'package:flutter/material.dart';
import 'package:university_life/features/admin/affectations/services/assignment_service.dart';
import 'package:university_life/features/admin/emplois_du_temps/models/timetable_slot_model.dart';
import 'package:university_life/features/admin/emplois_du_temps/services/timetable_admin_service.dart';
import 'package:university_life/features/admin/groupes/services/group_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class EmploisDuTempsScreen extends StatelessWidget {
  const EmploisDuTempsScreen({super.key});

  static const _days = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  Future<bool> _openForm(
      BuildContext context,
      TimetableAdminService service, {
        TimetableSlot? slot,
      }) async {
    final groups = await GroupService().fetchAll();
    final assignments = await AssignmentService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: slot == null ? 'Nouveau créneau' : 'Modifier le créneau',
      fields: [
        AdminField(
          key: 'groupId',
          label: 'Groupe',
          type: AdminFieldType.dropdown,
          initialValue: slot?.groupId,
          options: [
            for (final group in groups)
              AdminOption(value: group.id, label: group.name),
          ],
        ),
        AdminField(
          key: 'assignmentId',
          label: 'Module et professeur',
          type: AdminFieldType.dropdown,
          initialValue: slot?.assignmentId,
          options: [
            for (final assignment in assignments)
              AdminOption(value: assignment.id, label: assignment.label),
          ],
        ),
        AdminField(
          key: 'day',
          label: 'Jour',
          type: AdminFieldType.dropdown,
          initialValue: slot?.day,
          options: [
            for (final day in _days) AdminOption(value: day, label: day),
          ],
        ),
        AdminField(
          key: 'startTime',
          label: 'Heure de début',
          type: AdminFieldType.time,
          initialValue: slot?.startTime,
        ),
        AdminField(
          key: 'endTime',
          label: 'Heure de fin',
          type: AdminFieldType.time,
          initialValue: slot?.endTime,
        ),
        AdminField(key: 'room', label: 'Salle', initialValue: slot?.room),
      ],
      // Les heures sont au format HH:MM : la comparaison de texte suffit.
      formValidator: (values) =>
      values['endTime']!.compareTo(values['startTime']!) <= 0
          ? 'L’heure de fin doit être après l’heure de début.'
          : null,
    );
    if (values == null) return false;

    if (slot == null) {
      await service.create(values);
    } else {
      await service.update(slot.id, values);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = TimetableAdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('Emplois du temps')),
      body: AdminListView<TimetableSlot>(
        load: service.fetchAll,
        titleOf: (slot) => '${slot.day} · ${slot.startTime} – ${slot.endTime}',
        subtitleOf: (slot) =>
        '${slot.assignmentLabel}\n${slot.groupName} · ${slot.room}',
        icon: Icons.schedule,
        addLabel: 'Ajouter un créneau',
        emptyMessage: 'Aucun créneau planifié.',
        errorMessage: 'Impossible de charger les emplois du temps.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, slot) => _openForm(context, service, slot: slot),
        onDelete: (slot) => service.delete(slot.id),
      ),
    );
  }
}
