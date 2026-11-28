import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';
import 'package:university_life/features/auth/providers/auth_provider.dart';
import 'package:university_life/shared/widgets/app_button.dart';
import 'package:university_life/shared/widgets/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();

  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmationObscured = true;

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe actuel.';
    }
    if (value.runes.length > 256) {
      return 'Le mot de passe est limité à 256 caractères.';
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir un nouveau mot de passe.';
    }

    if (value.runes.length < 8) {
      return 'Le nouveau mot de passe doit contenir au moins 8 caractères.';
    }
    if (value.runes.length > 256) {
      return 'Le mot de passe est limité à 256 caractères.';
    }

    if (value == _currentPasswordController.text) {
      return 'Le nouveau mot de passe doit être différent du mot de passe actuel.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le nouveau mot de passe.';
    }

    if (value != _newPasswordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }

    return null;
  }

  void _submitForm() {
    final auth = context.read<AuthProvider?>();
    if (auth?.isBusy ?? false) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    auth?.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
  }

  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _isCurrentPasswordObscured = !_isCurrentPasswordObscured;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _isNewPasswordObscured = !_isNewPasswordObscured;
    });
  }

  void _toggleConfirmationVisibility() {
    setState(() {
      _isConfirmationObscured = !_isConfirmationObscured;
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
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
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      tooltip: 'Retour à l’écran précédent',
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  const Text(
                    'Changer le mot de passe',
                    style: AppTextStyles.pageTitle,
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPasswordField(
                          label: 'Mot de passe actuel',
                          semanticDescription: 'mot de passe actuel',
                          fieldKey: const ValueKey('current-password-field'),
                          visibilityButtonKey: const ValueKey(
                            'current-password-visibility',
                          ),
                          controller: _currentPasswordController,
                          isObscured: _isCurrentPasswordObscured,
                          textInputAction: TextInputAction.next,
                          validator: _validateCurrentPassword,
                          onToggleVisibility: _toggleCurrentPasswordVisibility,
                        ),
                        const SizedBox(height: AppDimensions.space24),
                        _buildPasswordField(
                          label: 'Nouveau mot de passe',
                          semanticDescription: 'nouveau mot de passe',
                          fieldKey: const ValueKey('new-password-field'),
                          visibilityButtonKey: const ValueKey(
                            'new-password-visibility',
                          ),
                          controller: _newPasswordController,
                          isObscured: _isNewPasswordObscured,
                          textInputAction: TextInputAction.next,
                          validator: _validateNewPassword,
                          onToggleVisibility: _toggleNewPasswordVisibility,
                        ),
                        const SizedBox(height: AppDimensions.space24),
                        _buildPasswordField(
                          label: 'Confirmer le nouveau mot de passe',
                          semanticDescription:
                              'confirmation du nouveau mot de passe',
                          fieldKey: const ValueKey(
                            'confirmation-password-field',
                          ),
                          visibilityButtonKey: const ValueKey(
                            'confirmation-password-visibility',
                          ),
                          controller: _confirmationController,
                          isObscured: _isConfirmationObscured,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmation,
                          onToggleVisibility: _toggleConfirmationVisibility,
                        ),
                        const SizedBox(height: AppDimensions.space32),
                        AppButton(
                          label: 'Changer le mot de passe',
                          onPressed: auth?.isBusy == true ? null : _submitForm,
                          isLoading: auth?.isBusy ?? false,
                        ),
                        if (auth?.message case final message?) ...[
                          const SizedBox(height: AppDimensions.space12),
                          Semantics(
                            liveRegion: true,
                            child: Text(message, style: AppTextStyles.body),
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

  Widget _buildPasswordField({
    required String label,
    required String semanticDescription,
    required Key fieldKey,
    required Key visibilityButtonKey,
    required TextEditingController controller,
    required bool isObscured,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    required VoidCallback onToggleVisibility,
  }) {
    return AppTextField(
      label: label,
      fieldKey: fieldKey,
      controller: controller,
      obscureText: isObscured,
      textInputAction: textInputAction,
      validator: validator,
      suffixIcon: Semantics(
        button: true,
        label: isObscured
            ? 'Afficher le $semanticDescription'
            : 'Masquer le $semanticDescription',
        onTap: onToggleVisibility,
        child: ExcludeSemantics(
          child: TextButton(
            key: visibilityButtonKey,
            onPressed: onToggleVisibility,
            child: Text(isObscured ? 'Voir' : 'Masquer'),
          ),
        ),
      ),
    );
  }
}
