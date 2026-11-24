import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_segmented_tabs.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../modules/models/teacher_module_model.dart';
import '../../widgets/form_helpers.dart';
import '../providers/teacher_attendance_provider.dart';

/// « Faire l'appel » : présence des étudiants à une séance.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.module});

  final TeacherModule module;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherAttendanceProvider>().load(widget.module.id);
    });
  }

  Future<void> _save() async {
    final provider = context.read<TeacherAttendanceProvider>();
    final ok = await provider.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Appel enregistré.' : (provider.error ?? 'Erreur.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherAttendanceProvider>();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final module = widget.module;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Faire l\'appel',
              subtitle: '${module.name} · ${module.groups.join(', ')}',
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) return const LoadingView();
                  if (provider.sessions.isEmpty) {
                    return ErrorView(provider.error ?? 'Aucune séance.');
                  }
                  final session = provider.selectedSession;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(
                            AppDimensions.phoneHorizontalMargin,
                          ),
                          children: [
                            const FormFieldLabel('Séance'),
                            DropdownButtonFormField<String>(
                              initialValue: session?.id,
                              decoration: formInputDecoration(),
                              items: [
                                for (final s in provider.sessions)
                                  DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.label} · ${dateFormat.format(s.date)}',
                                    ),
                                  ),
                              ],
                              onChanged: (id) {
                                final selected = provider.sessions.firstWhere(
                                  (s) => s.id == id,
                                );
                                provider.selectSession(selected);
                              },
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            AppBanner(
                              eyebrow: 'Appel en cours',
                              title: '${provider.students.length} étudiants',
                              subtitle: session == null
                                  ? null
                                  : '${session.label} · ${dateFormat.format(session.date)}',
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            for (final s in provider.students) ...[
                              AppCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.space16,
                                  vertical: AppDimensions.space12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.fullName,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppDimensions.space8),
                                    // Le statut est toujours écrit en toutes lettres.
                                    AppSegmentedTabs<bool>(
                                      compact: true,
                                      values: const [true, false],
                                      labelOf: (v) => v ? 'Présent' : 'Absent',
                                      selected: provider.isPresent(s.id),
                                      onChanged: (v) =>
                                          provider.setPresent(s.id, v),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimensions.space12),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(
                          AppDimensions.phoneHorizontalMargin,
                        ),
                        child: AppButton(
                          label: 'Enregistrer l\'appel',
                          isLoading: provider.isSaving,
                          onPressed: provider.isSaving ? null : _save,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
