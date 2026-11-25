import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.lime,
      onPrimary: AppColors.ink,
      surface: AppColors.ink,
      onSurface: AppColors.paper,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ink,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineMedium: AppTextStyles.display,
        bodyMedium: AppTextStyles.body,
        labelSmall: AppTextStyles.label,
      ),
    );
  }
}