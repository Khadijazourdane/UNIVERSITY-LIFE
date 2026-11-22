import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:university_life/core/navigation/app_router.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';

class UniversityLifeApp extends StatefulWidget {
  const UniversityLifeApp({super.key});

  @override
  State<UniversityLifeApp> createState() => _UniversityLifeAppState();
}

class _UniversityLifeAppState extends State<UniversityLifeApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.create(authProvider: _authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: 'University Life',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
