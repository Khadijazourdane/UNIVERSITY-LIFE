import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:university_life/core/navigation/app_routes.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';

enum _AccountAction { changePassword, signOut }

/// Shared account actions around the existing role screens.
class AuthenticatedSpace extends StatelessWidget {
  const AuthenticatedSpace({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider?>();
    if (auth == null) return child;
    return Column(
      children: [
        Expanded(child: child),
        Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (auth.isBusy) const LinearProgressIndicator(),
                if (auth.message case final message?)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Semantics(liveRegion: true, child: Text(message)),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (auth.canCloseLocally)
                        TextButton(
                          onPressed: auth.isBusy
                              ? null
                              : auth.closeSessionLocally,
                          child: const Text('Fermer la session locale'),
                        ),
                      PopupMenuButton<_AccountAction>(
                        tooltip: 'Compte',
                        icon: const Icon(Icons.account_circle_outlined),
                        enabled: !auth.isBusy,
                        onSelected: (action) {
                          switch (action) {
                            case _AccountAction.changePassword:
                              context.pushNamed(AppRoutes.changePasswordName);
                            case _AccountAction.signOut:
                              auth.signOut();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _AccountAction.changePassword,
                            child: Text('Changer le mot de passe'),
                          ),
                          PopupMenuItem(
                            value: _AccountAction.signOut,
                            child: Text('Se déconnecter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
