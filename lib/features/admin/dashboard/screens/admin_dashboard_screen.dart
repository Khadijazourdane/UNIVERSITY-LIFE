import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/admin/affectations/screens/affectations_screen.dart';
import 'package:university_life/features/admin/attestations/screens/attestations_screen.dart';
import 'package:university_life/features/admin/emplois_du_temps/screens/emplois_du_temps_screen.dart';
import 'package:university_life/features/admin/etudiants/screens/etudiants_screen.dart';
import 'package:university_life/features/admin/filieres/screens/filieres_screen.dart';
import 'package:university_life/features/admin/groupes/screens/groupes_screen.dart';
import 'package:university_life/features/admin/modules/screens/modules_screen.dart';
import 'package:university_life/features/admin/notifications/screens/notifications_admin_screens.dart';
import 'package:university_life/features/admin/professeurs/screens/professeurs_screen.dart';
import 'package:university_life/features/admin/seances/screens/seances_screen.dart';
import 'package:university_life/features/admin/semestres/screens/semestres_screen.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';

class _AdminEntry {
  const _AdminEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screenBuilder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() screenBuilder;
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static final List<(String, List<_AdminEntry>)> _sections = [
    (
    'Organisation académique',
    [
      _AdminEntry(
        icon: Icons.school_outlined,
        title: 'Filières',
        subtitle: 'Ajouter, modifier et supprimer les filières',
        screenBuilder: () => const FilieresScreen(),
      ),
      _AdminEntry(
        icon: Icons.date_range_outlined,
        title: 'Semestres',
        subtitle: 'Gérer les semestres de l’année',
        screenBuilder: () => const SemestresScreen(),
      ),
      _AdminEntry(
        icon: Icons.menu_book_outlined,
        title: 'Modules',
        subtitle: 'Gérer les modules d’enseignement',
        screenBuilder: () => const ModulesScreen(),
      ),
      _AdminEntry(
        icon: Icons.groups_outlined,
        title: 'Groupes',
        subtitle: 'Créer et organiser les groupes d’étudiants',
        screenBuilder: () => const GroupesScreen(),
      ),
    ],
    ),
    (
    'Personnes',
    [
      _AdminEntry(
        icon: Icons.person_outline,
        title: 'Étudiants',
        subtitle: 'Gérer les comptes étudiants',
        screenBuilder: () => const EtudiantsScreen(),
      ),
      _AdminEntry(
        icon: Icons.badge_outlined,
        title: 'Professeurs',
        subtitle: 'Gérer les comptes professeurs',
        screenBuilder: () => const ProfesseursScreen(),
      ),
      _AdminEntry(
        icon: Icons.assignment_ind_outlined,
        title: 'Affectations',
        subtitle: 'Professeurs aux modules, étudiants aux groupes',
        screenBuilder: () => const AffectationsScreen(),
      ),
    ],
    ),
    (
    'Planning',
    [
      _AdminEntry(
        icon: Icons.schedule,
        title: 'Emplois du temps',
        subtitle: 'Horaires, jours et salles des cours',
        screenBuilder: () => const EmploisDuTempsScreen(),
      ),
      _AdminEntry(
        icon: Icons.event_outlined,
        title: 'Séances',
        subtitle: 'Planifier les séances de cours',
        screenBuilder: () => const SeancesScreen(),
      ),
    ],
    ),
    (
    'Demandes et communication',
    [
      _AdminEntry(
        icon: Icons.description_outlined,
        title: 'Demandes d’attestations',
        subtitle: 'Accepter ou refuser les demandes',
        screenBuilder: () => const AttestationsScreen(),
      ),
      _AdminEntry(
        icon: Icons.campaign_outlined,
        title: 'Notifications',
        subtitle: 'Publier des annonces aux étudiants',
        screenBuilder: () => const NotificationsAdminScreen(),
      ),
    ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace administrateur'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().clearLocalSession(),
          ),
        ],
      ),
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
                Text('Bonjour !', style: AppTextStyles.pageTitle),
                SizedBox(height: AppDimensions.space8),
                Text(
                  'Bienvenue dans votre espace d’administration.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          for (final (sectionTitle, entries) in _sections) ...[
            const SizedBox(height: AppDimensions.space24),
            Text(sectionTitle, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppDimensions.space8),
            for (final entry in entries)
              Card(
                child: ListTile(
                  leading: Icon(entry.icon, color: AppColors.slate),
                  title: Text(entry.title, style: AppTextStyles.body),
                  subtitle: Text(
                    entry.subtitle,
                    style: AppTextStyles.compactBody,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.slate,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => entry.screenBuilder(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
