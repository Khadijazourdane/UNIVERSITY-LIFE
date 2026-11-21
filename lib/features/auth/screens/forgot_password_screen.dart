import 'package:flutter/material.dart';

import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/auth/validators/university_email_validator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _submitForm() {
    _formKey.currentState?.validate();

    // No recovery email is sent until the backend is connected.
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
                        onPressed: () => Navigator.of(context).pop(),
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
                    'Indiquez votre adresse universitaire. Si elle est associée '
                    'à un compte, vous recevrez un lien de réinitialisation.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            'Adresse universitaire',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Semantics(
                          label: 'Adresse universitaire',
                          textField: true,
                          child: TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'prenom.nom@edu.uiz.ac.ma',
                            ),
                            validator: UniversityEmailValidator.validate,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space32),
                        SizedBox(
                          width: double.infinity,
                          height: AppDimensions.buttonHeight,
                          child: FilledButton(
                            style: const ButtonStyle(
                              alignment: Alignment.centerLeft,
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(
                                  horizontal: AppDimensions.space16,
                                ),
                              ),
                            ),
                            onPressed: _submitForm,
                            child: Text(
                              'Envoyer le lien',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
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
