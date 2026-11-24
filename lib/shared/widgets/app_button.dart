import 'package:flutter/material.dart';

import 'package:university_life/core/theme/app_colors.dart';
import 'package:university_life/core/theme/app_dimensions.dart';
import 'package:university_life/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary }

/// A full-width action button styled with the University Life design system.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = variant == AppButtonVariant.primary
        ? AppColors.white
        : AppColors.slate;
    final buttonStyle = const ButtonStyle(
      alignment: AlignmentDirectional.centerStart,
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      ),
    );
    final content = Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (isLoading) ...[
          Semantics(
            liveRegion: true,
            label: 'Chargement en cours',
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: AppDimensions.iconSizeMinimum,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
        ],
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: switch (variant) {
        AppButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: content,
        ),
        AppButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: content,
        ),
      },
    );
  }
}
