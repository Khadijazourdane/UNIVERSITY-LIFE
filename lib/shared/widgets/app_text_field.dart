import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Décoration commune des champs : fond blanc, bordure lilas.
InputDecoration appInputDecoration({String? hint, String? errorText}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
    borderSide: const BorderSide(color: AppColors.powderLilac),
  );
  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    filled: true,
    fillColor: AppColors.white,
    enabledBorder: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

/// Libellé en gras au-dessus d'un champ.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Champ texte avec libellé au-dessus.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(label),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: appInputDecoration(hint: hint),
        ),
      ],
    );
  }
}
