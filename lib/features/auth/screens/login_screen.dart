import 'package:flutter/material.dart';

import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final RegExp _emailFormatPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );
  static const String _universityDomain = 'edu.uiz.ac.ma';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Veuillez saisir votre adresse universitaire.';
    }

    if (!_emailFormatPattern.hasMatch(email)) {
      return 'Veuillez saisir une adresse email valide.';
    }

    final domain = email.substring(email.lastIndexOf('@') + 1).toLowerCase();
    if (domain != _universityDomain) {
      return 'Utilisez une adresse se terminant par @edu.uiz.ac.ma.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }

    return null;
  }

  void _submitForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // The backend is not connected, so a valid form has no further action.
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
                  _buildBrandPanel(),
                  const SizedBox(height: AppDimensions.space32),
                  Text('Bienvenue.', style: AppTextStyles.pageTitle),
                  const SizedBox(height: AppDimensions.space24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFieldLabel('Adresse universitaire'),
                        const SizedBox(height: AppDimensions.space8),
                        Semantics(
                          label: 'Adresse universitaire',
                          textField: true,
                          child: TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'prenom.nom@edu.uiz.ac.ma',
                            ),
                            validator: _validateEmail,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space24),
                        _buildFieldLabel('Mot de passe'),
                        const SizedBox(height: AppDimensions.space8),
                        Semantics(
                          label: 'Mot de passe',
                          textField: true,
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _isPasswordObscured,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                            decoration: InputDecoration(
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
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            'Mot de passe oublié ?',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                              'Se connecter →',
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

  Widget _buildFieldLabel(String label) {
    return ExcludeSemantics(
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
