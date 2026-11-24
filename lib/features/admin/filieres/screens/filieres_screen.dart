import 'package:flutter/material.dart';
import 'package:university_life/features/admin/filieres/models/filiere_model.dart';
import 'package:university_life/features/admin/filieres/services/filiere_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class FilieresScreen extends StatelessWidget {
  const FilieresScreen({super.key});

  Future<bool> _openForm(
      BuildContext context,
      FiliereService service, {
        Filiere? filiere,
      }) async {
    final values = await showAdminFormDialog(
      context,
      title: filiere == null ? 'Nouvelle filière' : 'Modifier la filière',
      fields: [
        AdminField(
          key: 'name',
          label: 'Nom de la filière',
          initialValue: filiere?.name,
        ),
        AdminField(
          key: 'description',
          label: 'Description',
          type: AdminFieldType.multiline,
          required: false,
          initialValue: filiere?.description,
        ),
      ],
    );
    if (values == null) return false;

    if (filiere == null) {
      await service.create(values);
    } else {
      await service.update(filiere.id, values);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = FiliereService();

    return Scaffold(
      appBar: AppBar(title: const Text('Filières')),
      body: AdminListView<Filiere>(
        load: service.fetchAll,
        titleOf: (filiere) => filiere.name,
        subtitleOf: (filiere) => filiere.description,
        icon: Icons.school_outlined,
        addLabel: 'Ajouter une filière',
        emptyMessage: 'Aucune filière enregistrée.',
        errorMessage: 'Impossible de charger les filières.',
        onCreate: (context) => _openForm(context, service),
        onEdit: (context, filiere) =>
            _openForm(context, service, filiere: filiere),
        onDelete: (filiere) => service.delete(filiere.id),
      ),
    );
  }
}
