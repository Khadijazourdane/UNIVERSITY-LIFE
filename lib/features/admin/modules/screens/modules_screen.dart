import 'package:flutter/material.dart';
import 'package:university_life/features/admin/filieres/services/filiere_service.dart';
import 'package:university_life/features/admin/modules/models/module_model.dart';
import 'package:university_life/features/admin/modules/services/module_service.dart';
import 'package:university_life/features/admin/semestres/services/semester_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  Future<bool> _openForm(
      BuildContext context,
      ModuleService service, {
        CourseModule? module,
      }) async {
    final filieres = await FiliereService().fetchAll();
    final semesters = await SemesterService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: module == null ? 'Nouveau module' : 'Modifier le module',
      fields: [
        AdminField(
          key: 'name',
          label: 'Nom du module',
          initialValue: module?.name,
        ),
        AdminField(
          key: 'code',
          label: 'Code du module',
          hintText: 'INF101',
          initialValue: module?.code,
        ),
        AdminField(
          key: 'filiereId',
          label: 'Filière',
          type: AdminFieldType.dropdown,
          initialValue: module?.filiereId,
          options: [
            for (final filiere in filieres)
              AdminOption(value: filiere.id, label: filiere.name),
          ],
        ),
        AdminField(
          key: 'semesterId',
          label: 'Semestre',
          type: AdminFieldType.dropdown,
          initialValue: module?.semesterId,
          options: [
            for (final semester in semesters)
              AdminOption(value: semester.id, label: semester.name),
          ],
        ),
      ],
    );
    if (values == null) return false;

    if (module == null) {
      await service.create(values);
    } else {
      await service.update(module.id, values);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = ModuleService();

    return Scaffold(
      appBar: AppBar(title: const Text('Modules')),
      body: AdminListView<CourseModule>(
        load: service.fetchAll,
        titleOf: (module) => module.name,
        subtitleOf: (module) => [
          module.code,
          module.filiereName,
          module.semesterName,
        ].where((part) => part.isNotEmpty).join(' · '),
        icon: Icons.menu_book_outlined,
        addLabel: 'Ajouter un module',
        emptyMessage: 'Aucun module enregistré.',
        errorMessage: 'Impossible de charger les modules.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, module) =>
            _openForm(context, service, module: module),
        onDelete: (module) => service.delete(module.id),
      ),
    );
  }
}
