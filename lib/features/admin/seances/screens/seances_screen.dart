import 'package:flutter/material.dart';
import 'package:university_life/features/admin/affectations/services/assignment_service.dart';
import 'package:university_life/features/admin/groupes/services/group_service.dart';
import 'package:university_life/features/admin/professeurs/services/teacher_service.dart';
import 'package:university_life/features/admin/seances/models/course_session_model.dart';
import 'package:university_life/features/admin/seances/services/course_session_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class SeancesScreen extends StatelessWidget {
  const SeancesScreen({super.key});

  Future<bool> _openForm(
      BuildContext context,
      CourseSessionService service, {
        CourseSession? session,
      }) async {
    final teachers = await TeacherService().fetchAll();
    final groups = await GroupService().fetchAll();
    final assignments = await AssignmentService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: session == null ? 'Nouvelle séance' : 'Modifier la séance',
      fields: [
        AdminField(
          key: 'date',
          label: 'Date',
          type: AdminFieldType.date,
          initialValue: session?.date,
        ),
        AdminField(
          key: 'startTime',
          label: 'Heure de début',
          type: AdminFieldType.time,
          initialValue: session?.startTime,
        ),
        AdminField(
          key: 'endTime',
          label: 'Heure de fin',
          type: AdminFieldType.time,
          initialValue: session?.endTime,
        ),
        AdminField(key: 'room', label: 'Salle', initialValue: session?.room),
        AdminField(
          key: 'teacherId',
          label: 'Professeur',
          type: AdminFieldType.dropdown,
          initialValue: session?.teacherId,
          options: [
            for (final teacher in teachers)
              AdminOption(value: teacher.id, label: teacher.fullName),
          ],
        ),
        AdminField(
          key: 'groupId',
          label: 'Groupe',
          type: AdminFieldType.dropdown,
          initialValue: session?.groupId,
          options: [
            for (final group in groups)
              AdminOption(value: group.id, label: group.name),
          ],
        ),
        AdminField(
          key: 'assignmentId',
          label: 'Affectation (module et professeur)',
          type: AdminFieldType.dropdown,
          initialValue: session?.assignmentId,
          options: [
            for (final assignment in assignments)
              AdminOption(value: assignment.id, label: assignment.label),
          ],
        ),
      ],
      formValidator: (values) =>
      values['endTime']!.compareTo(values['startTime']!) <= 0
          ? 'L’heure de fin doit être après l’heure de début.'
          : null,
    );
    if (values == null) return false;

    if (session == null) {
      await service.create(values);
    } else {
      await service.update(session.id, values);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = CourseSessionService();

    return Scaffold(
      appBar: AppBar(title: const Text('Séances')),
      body: AdminListView<CourseSession>(
        load: service.fetchAll,
        titleOf: (session) =>
        '${session.date} · ${session.startTime} – ${session.endTime}',
        subtitleOf: (session) =>
        '${session.assignmentLabel}\n'
            '${session.teacherName} · ${session.groupName} · ${session.room}',
        icon: Icons.event_outlined,
        addLabel: 'Planifier une séance',
        emptyMessage: 'Aucune séance planifiée.',
        errorMessage: 'Impossible de charger les séances.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, session) =>
            _openForm(context, service, session: session),
        onDelete: (session) => service.delete(session.id),
      ),
    );
  }
}
