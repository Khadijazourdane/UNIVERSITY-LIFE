import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

/// Carte blanche à bordure lilas du UI Kit. Cliquable si [onTap] est fourni.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadiusMinimum),
        side: const BorderSide(color: AppColors.powderLilac),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
