import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:university_life/core/navigation/app_router.dart';
import 'package:university_life/core/network/api_client.dart';
import 'package:university_life/core/network/auth_platform.dart';
import 'package:university_life/core/storage/session_token_store.dart';
import 'package:university_life/core/theme/app_theme.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';
import 'package:university_life/features/auth/services/auth_service.dart';
import 'package:university_life/features/auth/services/http_auth_service.dart';
import 'package:university_life/features/teacher/teacher_providers.dart';

class UniversityLifeApp extends StatefulWidget {
  const UniversityLifeApp({super.key, this.authService});

  final AuthService? authService;

  @override
  State<UniversityLifeApp> createState() => _UniversityLifeAppState();
}

class _UniversityLifeAppState extends State<UniversityLifeApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;
  ApiClient? _apiClient;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(
      service: widget.authService ?? _createAuthService(),
    );
    _router = AppRouter.create(authProvider: _authProvider);
    unawaited(_authProvider.restoreSession());
  }

  AuthService? _createAuthService() {
    try {
      final client = ApiClient.fromConfig();
      _apiClient = client;
      configureAuthClient(client.dio);
      final apiUri = Uri.parse(client.dio.options.baseUrl);
      return HttpAuthService(
        client,
        tokenStore: kIsWeb ? null : SecureSessionTokenStore(apiUri),
      );
    } on StateError {
      return null;
    } on ArgumentError {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  void dispose() {
    _router.dispose();
    _authProvider.dispose();
    _apiClient?.dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ...buildTeacherProviders(),
      ],
      child: MaterialApp.router(
        title: 'University Life',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
