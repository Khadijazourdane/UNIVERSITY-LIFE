import 'package:flutter/material.dart';
import 'package:university_life/features/admin/professeurs/models/teacher_model.dart';
import 'package:university_life/features/admin/professeurs/services/teacher_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class ProfesseursScreen extends StatelessWidget {
  const ProfesseursScreen({super.key});

  static String? _validateEmail(String value) {
    final atIndex = value.indexOf('@');
    if (atIndex <= 0 || atIndex == value.length - 1) {
      return 'Veuillez saisir une adresse email valide.';
    }
    return null;
  }

  Future<bool> _openForm(
      BuildContext context,
      TeacherService service, {
        Teacher? teacher,
      }) async {
    final values = await showAdminFormDialog(
      context,
      title: teacher == null ? 'Nouveau professeur' : 'Modifier le professeur',
      fields: [
        AdminField(
          key: 'lastName',
          label: 'Nom',
          initialValue: teacher?.lastName,
        ),
        AdminField(
          key: 'firstName',
          label: 'Prénom',
          initialValue: teacher?.firstName,
        ),
        AdminField(
          key: 'email',
          label: 'Adresse email',
          type: AdminFieldType.email,
          initialValue: teacher?.email,
          validator: _validateEmail,
        ),
        AdminField(
          key: 'speciality',
          label: 'Spécialité',
          required: false,
          initialValue: teacher?.speciality,
        ),
        // Mot de passe initial uniquement à la création du compte.
        if (teacher == null)
          const AdminField(
            key: 'password',
            label: 'Mot de passe initial',
            type: AdminFieldType.password,
          ),
      ],
    );
    if (values == null) return false;

    if (teacher == null) {
      await service.create(values);
    } else {
      await service.update(teacher.id, values);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = TeacherService();

    return Scaffold(
      appBar: AppBar(title: const Text('Professeurs')),
      body: AdminListView<Teacher>(
        load: service.fetchAll,
        titleOf: (teacher) => teacher.fullName,
        subtitleOf: (teacher) => teacher.speciality.isEmpty
            ? teacher.email
            : '${teacher.email}\n${teacher.speciality}',
        icon: Icons.person_outline,
        addLabel: 'Créer un compte professeur',
        emptyMessage: 'Aucun professeur enregistré.',
        errorMessage: 'Impossible de charger les professeurs.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, teacher) =>
            _openForm(context, service, teacher: teacher),
        onDelete: (teacher) => service.delete(teacher.id),
      ),
    );
  }
}
