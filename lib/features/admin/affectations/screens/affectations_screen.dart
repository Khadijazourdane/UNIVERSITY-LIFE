import 'package:flutter/material.dart';
import 'package:university_life/features/admin/affectations/models/assignment_model.dart';
import 'package:university_life/features/admin/affectations/services/assignment_service.dart';
import 'package:university_life/features/admin/etudiants/models/student_model.dart';
import 'package:university_life/features/admin/etudiants/services/student_service.dart';
import 'package:university_life/features/admin/groupes/services/group_service.dart';
import 'package:university_life/features/admin/modules/services/module_service.dart';
import 'package:university_life/features/admin/professeurs/services/teacher_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class AffectationsScreen extends StatelessWidget {
  const AffectationsScreen({super.key});

  Future<bool> _openAssignmentForm(
      BuildContext context,
      AssignmentService service, {
        Assignment? assignment,
      }) async {
    final teachers = await TeacherService().fetchAll();
    final modules = await ModuleService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: assignment == null
          ? 'Nouvelle affectation'
          : 'Modifier l’affectation',
      fields: [
        AdminField(
          key: 'teacherId',
          label: 'Professeur',
          type: AdminFieldType.dropdown,
          initialValue: assignment?.teacherId,
          options: [
            for (final teacher in teachers)
              AdminOption(value: teacher.id, label: teacher.fullName),
          ],
        ),
        AdminField(
          key: 'moduleId',
          label: 'Module',
          type: AdminFieldType.dropdown,
          initialValue: assignment?.moduleId,
          options: [
            for (final module in modules)
              AdminOption(value: module.id, label: module.name),
          ],
        ),
      ],
    );
    if (values == null) return false;

    if (assignment == null) {
      await service.create(values);
    } else {
      await service.update(assignment.id, values);
    }
    return true;
  }

  Future<bool> _openStudentGroupForm(
      BuildContext context,
      StudentService service,
      Student student,
      ) async {
    final groups = await GroupService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: 'Groupe de ${student.fullName}',
      fields: [
        AdminField(
          key: 'groupId',
          label: 'Groupe',
          type: AdminFieldType.dropdown,
          required: false,
          initialValue: student.groupId,
          options: [
            const AdminOption(value: '', label: 'Aucun groupe'),
            for (final group in groups)
              AdminOption(value: group.id, label: group.name),
          ],
        ),
      ],
    );
    if (values == null) return false;

    await service.assignGroup(student.id, values['groupId']!);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final assignmentService = AssignmentService();
    final studentService = StudentService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Affectations'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Professeurs'),
              Tab(text: 'Étudiants'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AdminListView<Assignment>(
              load: assignmentService.fetchAll,
              titleOf: (assignment) => assignment.moduleName,
              subtitleOf: (assignment) => assignment.teacherName,
              icon: Icons.assignment_ind_outlined,
              addLabel: 'Affecter un professeur',
              emptyMessage: 'Aucun professeur affecté à un module.',
              errorMessage: 'Impossible de charger les affectations.',
              onCreate: (context) =>
                  _openAssignmentForm(context, assignmentService),
              onEdit: (context, assignment) => _openAssignmentForm(
                context,
                assignmentService,
                assignment: assignment,
              ),
              onDelete: (assignment) => assignmentService.delete(assignment.id),
            ),
            AdminListView<Student>(
              load: studentService.fetchAll,
              titleOf: (student) => student.fullName,
              subtitleOf: (student) =>
              student.groupName.isEmpty ? 'Sans groupe' : student.groupName,
              icon: Icons.person_outline,
              emptyMessage: 'Aucun étudiant enregistré.',
              errorMessage: 'Impossible de charger les étudiants.',
              onEdit: (context, student) =>
                  _openStudentGroupForm(context, studentService, student),
            ),
          ],
        ),
      ),
    );
  }
}
