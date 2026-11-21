import 'package:flutter/material.dart';

import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/features/auth/screens/login_screen.dart';

class UniversityLifeApp extends StatelessWidget {
  const UniversityLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Life',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
