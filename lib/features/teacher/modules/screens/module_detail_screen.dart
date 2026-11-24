import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../courses/screens/course_list_screen.dart';
import '../../grades/screens/grades_screen.dart';
import '../../students/screens/students_screen.dart';
import '../models/teacher_module_model.dart';

/// Point d'entrée d'un module : cours, notes, absences, étudiants.
class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({super.key, required this.module});

  final TeacherModule module;

  @override
  Widget build(BuildContext context) {
    final entries = <_Entry>[
      _Entry(
        'Cours (PDF)',
        'Publier et gérer les supports',
        Icons.picture_as_pdf_outlined,
        CourseListScreen(module: module),
      ),
      _Entry(
        'Notes',
        'Saisir les notes des étudiants',
        Icons.grade_outlined,
        GradesScreen(module: module),
      ),
      _Entry(
        'Absences',
        'Faire l\'appel d\'une séance',
        Icons.fact_check_outlined,
        AttendanceScreen(module: module),
      ),
      _Entry(
        'Étudiants',
        'Liste des étudiants du module',
        Icons.people_outline,
        StudentsScreen(module: module),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: module.name,
              subtitle: '${module.code} · Groupes : ${module.groups.join(', ')}',
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(
                  AppDimensions.phoneHorizontalMargin,
                ),
                itemCount: entries.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDimensions.space12),
                itemBuilder: (context, index) {
                  final e = entries[index];
                  return AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => e.screen),
                    ),
                    child: Row(
                      children: [
                        Icon(e.icon, size: AppDimensions.iconSizeMaximum),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.label,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                e.description,
                                style: AppTextStyles.compactBody,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
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

class _Entry {
  const _Entry(this.label, this.description, this.icon, this.screen);

  final String label;
  final String description;
  final IconData icon;
  final Widget screen;
}
