import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Bouton pleine largeur : principal (ardoise) ou secondaire (contour).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.isLoading = false,
  });

  final String label;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;
  final bool secondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.slate,
            side: const BorderSide(color: AppColors.slate),
          ),
          child: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.slate,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.mist,
          disabledForegroundColor: AppColors.white,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
