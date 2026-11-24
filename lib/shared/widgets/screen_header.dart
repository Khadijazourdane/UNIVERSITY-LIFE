import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// En-tête d'écran : titre, sous-titre, bouton retour (si on peut revenir)
/// et pastille de profil.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.phoneHorizontalMargin,
        AppDimensions.space16,
        AppDimensions.phoneHorizontalMargin,
        AppDimensions.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop)
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.space8),
              child: IconButton(
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.pageTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.compactBody),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.powderLilac,
            child: Icon(
              Icons.person_outline,
              size: AppDimensions.iconSizeMinimum - 4,
              color: AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}
