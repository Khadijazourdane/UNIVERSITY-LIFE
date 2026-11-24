import 'package:flutter/material.dart';

import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';

/// A labeled form field with the shared University Life spacing and semantics.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.fieldKey,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Semantics(
          label: label,
          textField: true,
          child: TextFormField(
            key: fieldKey,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
