import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

/// Décoration minimale : le thème de l'app (`AppTheme`) fait le reste.
/// Pour les champs hors `AppTextField` (liste déroulante, champ dans une ligne).
InputDecoration formInputDecoration({String? hint, String? errorText}) {
  return InputDecoration(hintText: hint, errorText: errorText);
}

/// Libellé en gras au-dessus d'un champ (même style que `AppTextField`).
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
