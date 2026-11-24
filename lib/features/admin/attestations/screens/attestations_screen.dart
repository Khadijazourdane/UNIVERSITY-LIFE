import 'package:flutter/material.dart';
import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/admin/attestations/models/attestation_request_model.dart';
import 'package:university_life/features/admin/attestations/services/attestation_service.dart';
import 'package:university_life/features/admin/widgets/admin_dialogs.dart';
import 'package:university_life/features/admin/widgets/admin_list_view.dart';

class AttestationsScreen extends StatelessWidget {
  const AttestationsScreen({super.key});

  Future<void> _decide(
      BuildContext context,
      Future<void> Function() action,
      Future<void> Function() reload,
      ) async {
    try {
      await action();
      await reload();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opération impossible. Réessayez.')),
      );
    }
  }

  Future<void> _accept(
      BuildContext context,
      AttestationService service,
      AttestationRequest request,
      Future<void> Function() reload,
      ) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Accepter la demande',
      message:
      'Accepter la demande « ${request.type} » de ${request.studentName} ?',
      confirmLabel: 'Accepter',
    );
    if (!confirmed || !context.mounted) return;

    await _decide(context, () => service.accept(request.id), reload);
  }

  Future<void> _refuse(
      BuildContext context,
      AttestationService service,
      AttestationRequest request,
      Future<void> Function() reload,
      ) async {
    final values = await showAdminFormDialog(
      context,
      title: 'Refuser la demande',
      submitLabel: 'Refuser',
      fields: const [
        AdminField(
          key: 'reason',
          label: 'Motif du refus',
          type: AdminFieldType.multiline,
          required: false,
        ),
      ],
    );
    if (values == null || !context.mounted) return;

    await _decide(
      context,
          () => service.refuse(request.id, reason: values['reason']!),
      reload,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = AttestationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes d’attestations')),
      body: AdminListView<AttestationRequest>(
        load: service.fetchAll,
        titleOf: (request) => request.type,
        subtitleOf: (request) =>
        '${request.studentName}\n${request.requestedAt} · '
            '${request.status.label}',
        icon: Icons.description_outlined,
        emptyMessage: 'Aucune demande d’attestation.',
        errorMessage: 'Impossible de charger les demandes.',
        onView: (context, request) => showAdminDetailsDialog(
          context,
          title: request.type,
          rows: {
            'Étudiant': request.studentName,
            'Date de la demande': request.requestedAt,
            'Statut': request.status.label,
            if (request.status == AttestationStatus.refused)
              'Motif du refus': request.reason,
          },
        ),
        trailingBuilder: (context, request, reload) {
          if (request.status != AttestationStatus.pending) return null;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Accepter',
                icon: const Icon(Icons.check_circle_outline),
                color: AppColors.slate,
                onPressed: () => _accept(context, service, request, reload),
              ),
              IconButton(
                tooltip: 'Refuser',
                icon: const Icon(Icons.cancel_outlined),
                color: AppColors.slate,
                onPressed: () => _refuse(context, service, request, reload),
              ),
            ],
          );
        },
      ),
    );
  }
}
