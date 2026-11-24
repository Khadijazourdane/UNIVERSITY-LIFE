import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../modules/models/teacher_module_model.dart';
import '../../widgets/form_helpers.dart';
import '../providers/teacher_grade_provider.dart';

/// « Saisie des notes » d'un module.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key, required this.module});

  final TeacherModule module;

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherGradeProvider>().load(
        widget.module.id,
        widget.module.gradeScale,
      );
    });
  }

  Future<void> _save() async {
    final provider = context.read<TeacherGradeProvider>();
    final ok = await provider.save(widget.module.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Notes enregistrées.' : (provider.error ?? 'Corrigez les erreurs.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherGradeProvider>();
    final module = widget.module;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Saisie des notes',
              subtitle:
                  '${module.name} · ${module.groups.join(', ')} · Sur ${module.gradeScale.toStringAsFixed(0)}',
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) return const LoadingView();
                  if (provider.students.isEmpty) {
                    return ErrorView(provider.error ?? 'Aucun étudiant.');
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(
                            AppDimensions.phoneHorizontalMargin,
                          ),
                          itemCount: provider.students.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppDimensions.space12),
                          itemBuilder: (context, index) {
                            final s = provider.students[index];
                            return AppCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Text(
                                        s.fullName,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.space12),
                                  SizedBox(
                                    width: 120,
                                    child: TextFormField(
                                      key: ValueKey('grade_${s.id}'),
                                      initialValue: provider.initialText(s.id),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: formInputDecoration(
                                        hint:
                                            '/ ${provider.scale.toStringAsFixed(0)}',
                                        errorText: provider.errorFor(s.id),
                                      ),
                                      onChanged: (v) =>
                                          provider.setInput(s.id, v),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(
                          AppDimensions.phoneHorizontalMargin,
                        ),
                        child: AppButton(
                          label: 'Enregistrer les notes',
                          isLoading: provider.isSaving,
                          onPressed: (provider.hasErrors || provider.isSaving)
                              ? null
                              : _save,
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
