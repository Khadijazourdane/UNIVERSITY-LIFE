import 'package:flutter/material.dart';
import 'package:university_life/features/admin/etudiants/models/student_model.dart';
import 'package:university_life/features/admin/etudiants/services/student_service.dart';
import 'package:university_life/features/admin/groupes/services/group_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';
import 'package:university_life/features/auth/validators/university_email_validator.dart';

class EtudiantsScreen extends StatelessWidget {
  const EtudiantsScreen({super.key});

  Future<bool> _openForm(
      BuildContext context,
      StudentService service, {
        Student? student,
      }) async {
    final groups = await GroupService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: student == null ? 'Nouvel étudiant' : 'Modifier l’étudiant',
      fields: [
        AdminField(
          key: 'lastName',
          label: 'Nom',
          initialValue: student?.lastName,
        ),
        AdminField(
          key: 'firstName',
          label: 'Prénom',
          initialValue: student?.firstName,
        ),
        AdminField(
          key: 'email',
          label: 'Adresse universitaire',
          type: AdminFieldType.email,
          hintText: 'prenom.nom@edu.uiz.ac.ma',
          initialValue: student?.email,
          validator: UniversityEmailValidator.validate,
        ),
        AdminField(
          key: 'groupId',
          label: 'Groupe',
          type: AdminFieldType.dropdown,
          required: false,
          initialValue: student?.groupId,
          options: [
            const AdminOption(value: '', label: 'Aucun groupe'),
            for (final group in groups)
              AdminOption(value: group.id, label: group.name),
          ],
        ),
        // Mot de passe initial uniquement à la création du compte.
        if (student == null)
          const AdminField(
            key: 'password',
            label: 'Mot de passe initial',
            type: AdminFieldType.password,
          ),
      ],
    );
    if (values == null) return false;

    final data = <String, Object?>{
      ...values,
      'groupId': values['groupId']!.isEmpty ? null : values['groupId'],
    };
    if (student == null) {
      await service.create(data);
    } else {
      await service.update(student.id, data);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = StudentService();

    return Scaffold(
      appBar: AppBar(title: const Text('Étudiants')),
      body: AdminListView<Student>(
        load: service.fetchAll,
        titleOf: (student) => student.fullName,
        subtitleOf: (student) => student.groupName.isEmpty
            ? student.email
            : '${student.email}\n${student.groupName}',
        icon: Icons.person_outline,
        addLabel: 'Ajouter un étudiant',
        emptyMessage: 'Aucun étudiant enregistré.',
        errorMessage: 'Impossible de charger les étudiants.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, student) =>
            _openForm(context, service, student: student),
        onDelete: (student) => service.delete(student.id),
        onView: (context, student) => showAdminDetailsDialog(
          context,
          title: student.fullName,
          rows: {
            'Adresse universitaire': student.email,
            'Filière': student.filiereName,
            'Groupe': student.groupName,
          },
        ),
      ),
    );
  }
}
