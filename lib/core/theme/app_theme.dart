import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Thème clair Material 3 de University Life.
abstract final class AppTheme {
  static final ThemeData light = _buildLightTheme();

  static ThemeData _buildLightTheme() {
    // Keep unspecified Material color roles at Flutter's standard light values.
    // The colors assigned here are the roles explicitly supported by the UX/UI.
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.slate,
      onPrimary: AppColors.white,
      surface: AppColors.ivory,
      onSurface: AppColors.slate,
    );
    final baseTheme = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
    );
    final buttonBaseStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size?>(
        Size(AppDimensions.minimumTapTarget, AppDimensions.buttonHeight),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder?>(buttonShape),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(
            color: AppColors.slate,
            width: AppDimensions.focusBorderWidth,
          );
        }
        return null;
      }),
    );
    final fieldBorderRadius = BorderRadius.circular(AppDimensions.fieldRadius);

    return baseTheme.copyWith(
      textTheme: AppTextStyles.applyTo(baseTheme.textTheme),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontFamily: AppTextStyles.fontFamily,
      ),
      scaffoldBackgroundColor: AppColors.ivory,
      filledButtonTheme: FilledButtonThemeData(
        style: buttonBaseStyle.copyWith(
          backgroundColor: const WidgetStatePropertyAll<Color?>(
            AppColors.slate,
          ),
          foregroundColor: const WidgetStatePropertyAll<Color?>(
            AppColors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonBaseStyle),
      textButtonTheme: TextButtonThemeData(style: buttonBaseStyle),
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(borderRadius: fieldBorderRadius),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.slate,
            width: AppDimensions.focusBorderWidth,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppDimensions.navigationBarHeight,
        indicatorColor: AppColors.powderLilac,
        labelTextStyle: const WidgetStatePropertyAll<TextStyle?>(
          AppTextStyles.navigationLabel,
        ),
      ),
    );
  }
}
