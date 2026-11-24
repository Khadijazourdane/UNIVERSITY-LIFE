import 'package:flutter/material.dart';
import 'package:university_life/features/admin/filieres/services/filiere_service.dart';
import 'package:university_life/features/admin/groupes/models/group_model.dart';
import 'package:university_life/features/admin/groupes/services/group_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class GroupesScreen extends StatelessWidget {
  const GroupesScreen({super.key});

  Future<bool> _openForm(
      BuildContext context,
      GroupService service, {
        Group? group,
      }) async {
    final filieres = await FiliereService().fetchAll();
    if (!context.mounted) return false;

    final values = await showAdminFormDialog(
      context,
      title: group == null ? 'Nouveau groupe' : 'Modifier le groupe',
      fields: [
        AdminField(
          key: 'name',
          label: 'Nom du groupe',
          hintText: 'Groupe A',
          initialValue: group?.name,
        ),
        AdminField(
          key: 'filiereId',
          label: 'Filière',
          type: AdminFieldType.dropdown,
          initialValue: group?.filiereId,
          options: [
            for (final filiere in filieres)
              AdminOption(value: filiere.id, label: filiere.name),
          ],
        ),
      ],
    );
    if (values == null) return false;

    if (group == null) {
      await service.create(values);
    } else {
      await service.update(group.id, values);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = GroupService();

    return Scaffold(
      appBar: AppBar(title: const Text('Groupes')),
      body: AdminListView<Group>(
        load: service.fetchAll,
        titleOf: (group) => group.name,
        subtitleOf: (group) => group.filiereName,
        icon: Icons.groups_outlined,
        addLabel: 'Créer un groupe',
        emptyMessage: 'Aucun groupe enregistré.',
        errorMessage: 'Impossible de charger les groupes.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, group) => _openForm(context, service, group: group),
        onDelete: (group) => service.delete(group.id),
      ),
    );
  }
}
