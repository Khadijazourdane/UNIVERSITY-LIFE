import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

/// Grande carte ardoise (« Machine Learning », « 15,25 / 20 »...).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.slate,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppDimensions.bannerRadiusMinimum),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.powderLilac,
                      letterSpacing: 0.6,
                    ),
                  ),
                if (eyebrow != null) const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.white,
                    fontSize: 22,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.compactBody.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
