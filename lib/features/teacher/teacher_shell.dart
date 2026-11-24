import 'package:flutter/material.dart';

import '../../shared/widgets/app_bottom_nav.dart';
import 'modules/screens/modules_screen.dart';
import 'notifications/screens/teacher_notifications_screen.dart';

/// Espace professeur : barre de navigation basse.
/// Les providers sont fournis plus haut, dans `main.dart`.
/// À afficher après l'authentification quand le rôle du compte est « professeur ».
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [ModulesScreen(), TeacherNotificationsScreen()],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        items: const [
          AppNavItem('Accueil', Icons.home_outlined),
          AppNavItem('Notifications', Icons.notifications_outlined),
        ],
      ),
    );
  }
}
