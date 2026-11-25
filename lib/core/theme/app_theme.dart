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
      // Lime only on the active part; the rest stays neutral.
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: AppColors.lime,
        inactiveTrackColor: AppColors.inkLine,
        thumbColor: AppColors.lime,
        overlayColor: AppColors.lime.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.ink,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.paper),
    );
  }
}