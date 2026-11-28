import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:university_life/core/navigation/app_routes.dart';
import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/auth/validators/university_email_validator.dart';
import 'package:university_life/shared/widgets/app_button.dart';
import 'package:university_life/shared/widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showUnavailable = false;

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _showUnavailable = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalMargin =
                constraints.maxWidth < AppDimensions.phoneMinimumWidth
                ? AppDimensions.compactHorizontalMargin
                : AppDimensions.phoneHorizontalMargin;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalMargin,
                AppDimensions.space16,
                horizontalMargin,
                AppDimensions.space24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Retour à la connexion',
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.loginPath),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      ExcludeSemantics(
                        child: SizedBox.square(
                          dimension: 56,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppColors.powderLilac,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mail_outline,
                              color: AppColors.slate,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  const Text(
                    'Mot de passe oublié',
                    style: AppTextStyles.pageTitle,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  const Text(
                    'Retrouver votre accès',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  const Text(
                    'La récupération en ligne est en cours de préparation. '
                    'Pour retrouver votre accès, contactez la scolarité.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Adresse universitaire',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          hintText: 'prenom.nom@edu.uiz.ac.ma',
                          validator: UniversityEmailValidator.validate,
                        ),
                        const SizedBox(height: AppDimensions.space32),
                        AppButton(
                          label: 'Envoyer le lien',
                          onPressed: _submitForm,
                        ),
                        if (_showUnavailable) ...[
                          const SizedBox(height: AppDimensions.space12),
                          Semantics(
                            liveRegion: true,
                            child: const Text(
                              'Aucun lien envoyé. Contactez la scolarité.',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
