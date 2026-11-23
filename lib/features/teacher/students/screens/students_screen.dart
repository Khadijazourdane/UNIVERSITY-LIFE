import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../modules/models/teacher_module_model.dart';
import '../providers/teacher_student_provider.dart';

/// Liste des étudiants d'un module.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key, required this.module});

  final TeacherModule module;

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherStudentProvider>().load(widget.module.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherStudentProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Étudiants',
              subtitle: widget.module.name,
            ),
            Expanded(child: _buildBody(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TeacherStudentProvider provider) {
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(provider.error!);
    if (provider.students.isEmpty) return const ErrorView('Aucun étudiant.');
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.phoneHorizontalMargin),
      itemCount: provider.students.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
      itemBuilder: (context, index) {
        final s = provider.students[index];
        return AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${s.filiere} · ${s.email}',
                      style: AppTextStyles.compactBody,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              StatusBadge(s.group),
            ],
          ),
        );
      },
    );
  }
}
