import 'package:flutter/material.dart';

import 'package:university_life/core/theme/app_theme.dart';

class UniversityLifeApp extends StatelessWidget {
  const UniversityLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Life',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(),
    );
  }
}
