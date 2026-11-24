import 'package:flutter/material.dart';
import 'package:university_life/features/admin/semestres/models/semester_model.dart';
import 'package:university_life/features/admin/semestres/services/semester_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class SemestresScreen extends StatelessWidget {
  const SemestresScreen({super.key});

  Future<bool> _openForm(
      BuildContext context,
      SemesterService service, {
        Semester? semester,
      }) async {
    final values = await showAdminFormDialog(
      context,
      title: semester == null ? 'Nouveau semestre' : 'Modifier le semestre',
      fields: [
        AdminField(
          key: 'name',
          label: 'Nom du semestre',
          hintText: 'Semestre 1',
          initialValue: semester?.name,
        ),
        AdminField(
          key: 'startDate',
          label: 'Date de début',
          type: AdminFieldType.date,
          initialValue: semester?.startDate,
        ),
        AdminField(
          key: 'endDate',
          label: 'Date de fin',
          type: AdminFieldType.date,
          initialValue: semester?.endDate,
        ),
      ],
      // Les dates sont au format AAAA-MM-JJ : la comparaison de texte suffit.
      formValidator: (values) =>
      values['endDate']!.compareTo(values['startDate']!) < 0
          ? 'La date de fin doit être après la date de début.'
          : null,
    );
    if (values == null) return false;

    if (semester == null) {
      await service.create(values);
    } else {
      await service.update(semester.id, values);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = SemesterService();

    return Scaffold(
      appBar: AppBar(title: const Text('Semestres')),
      body: AdminListView<Semester>(
        load: service.fetchAll,
        titleOf: (semester) => semester.name,
        subtitleOf: (semester) =>
        'Du ${semester.startDate} au ${semester.endDate}',
        icon: Icons.date_range_outlined,
        addLabel: 'Ajouter un semestre',
        emptyMessage: 'Aucun semestre enregistré.',
        errorMessage: 'Impossible de charger les semestres.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, semester) =>
            _openForm(context, service, semester: semester),
        onDelete: (semester) => service.delete(semester.id),
      ),
    );
  }
}
