import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:university_life/core/navigation/app_routes.dart';
import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';
import 'package:university_life/features/auth/validators/university_email_validator.dart';
import 'package:university_life/shared/widgets/app_button.dart';
import 'package:university_life/shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }
    if (value.runes.length > 256) {
      return 'Le mot de passe est limité à 256 caractères.';
    }

    return null;
  }

  void _submitForm() {
    final auth = context.read<AuthProvider?>();
    if (auth?.isBusy ?? false) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    auth?.signIn(
      universityEmail: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider?>();
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
                  _buildBrandPanel(),
                  const SizedBox(height: AppDimensions.space32),
                  Text('Bienvenue.', style: AppTextStyles.pageTitle),
                  const SizedBox(height: AppDimensions.space24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Adresse universitaire',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'prenom.nom@edu.uiz.ac.ma',
                          validator: UniversityEmailValidator.validate,
                        ),
                        const SizedBox(height: AppDimensions.space24),
                        AppTextField(
                          label: 'Mot de passe',
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          suffixIcon: Semantics(
                            button: true,
                            label: _isPasswordObscured
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            onTap: _togglePasswordVisibility,
                            child: ExcludeSemantics(
                              child: TextButton(
                                onPressed: _togglePasswordVisibility,
                                child: Text(
                                  _isPasswordObscured ? 'Voir' : 'Masquer',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () {
                              context.pushNamed(AppRoutes.forgotPasswordName);
                            },
                            child: Text(
                              'Mot de passe oublié ?',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space32),
                        if (auth?.message case final message?) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(message, style: AppTextStyles.body),
                          ),
                          if (auth!.canRetryRestore)
                            TextButton(
                              onPressed: auth.restoreSession,
                              child: const Text('Réessayer la restauration'),
                            ),
                          const SizedBox(height: AppDimensions.space12),
                        ],
                        AppButton(
                          label: 'Se connecter →',
                          onPressed: auth?.isBusy == true ? null : _submitForm,
                          isLoading: auth?.isBusy ?? false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  Text(
                    'Besoin d’aide ? Contactez la scolarité.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.powderLilac,
        borderRadius: BorderRadius.circular(AppDimensions.bannerRadiusMaximum),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'UNIVERSITY LIFE',
                  style: AppTextStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space32),
          const Text(
            'Votre campus, à portée de main.',
            style: AppTextStyles.pageTitle,
          ),
          const SizedBox(height: AppDimensions.space24),
          const Text(
            'Étudier. Enseigner. Organiser.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
