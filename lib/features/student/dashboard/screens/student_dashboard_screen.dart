import 'package:flutter/material.dart';
import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/student/absences/screens/absences_screen.dart';
import 'package:university_life/features/student/grades/screens/grades_screen.dart';
import 'package:university_life/features/student/timetable/screens/timetable_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space24),
            decoration: BoxDecoration(
              color: AppColors.powderLilac,
              borderRadius: BorderRadius.circular(
                AppDimensions.bannerRadiusMinimum,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour, Lina !', style: AppTextStyles.pageTitle),
                SizedBox(height: AppDimensions.space8),
                Text(
                  'Bienvenue dans ton espace étudiant.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          const Text('Prochain cours', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimensions.space8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.slate),
              title: const Text('Bases de données', style: AppTextStyles.body),
              subtitle: const Text(
                'Aujourd’hui, 10 h 30 · Salle B12',
                style: AppTextStyles.compactBody,
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const TimetableScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          const Text('Annonces', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimensions.space8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.campaign_outlined, color: AppColors.slate),
              title: Text('Changement de salle', style: AppTextStyles.body),
              subtitle: Text(
                'Le cours de demain aura lieu en salle B12.',
                style: AppTextStyles.compactBody,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          const Text('Indicateurs', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppDimensions.space8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.grade_outlined, color: AppColors.slate),
              title: const Text('Notes', style: AppTextStyles.body),
              subtitle: const Text(
                'Moyenne générale · 14,5 / 20',
                style: AppTextStyles.compactBody,
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const GradesScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.event_busy_outlined,
                color: AppColors.slate,
              ),
              title: const Text('Absences', style: AppTextStyles.body),
              subtitle: const Text(
                '2 absences ce semestre',
                style: AppTextStyles.compactBody,
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.slate),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AbsencesScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
