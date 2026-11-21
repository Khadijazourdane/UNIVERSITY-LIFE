import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Styles typographiques nommés selon les rôles de l'interface.
abstract final class AppTextStyles {
  static const String fontFamily = 'DejaVuSans';

  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    color: AppColors.slate,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.slate,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.slate,
  );

  static const TextStyle compactBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.slate,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.slate,
  );

  static const TextStyle navigationLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.slate,
  );

  /// Replaces the selected Material 3 text roles while retaining the other
  /// standard roles supplied by Flutter.
  static TextTheme applyTo(TextTheme base) {
    return base
        .copyWith(
          headlineMedium: pageTitle,
          titleLarge: sectionTitle,
          bodyLarge: body,
          bodyMedium: compactBody,
          bodySmall: caption,
          labelSmall: navigationLabel,
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.slate,
          displayColor: AppColors.slate,
        );
  }
}
