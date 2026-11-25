import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const display = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.paper,
  );

  static const title = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.paper,
  );

  // Tabular figures keep digits from jittering as times change.
  static const number = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.paper,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    height: 1.4,
    color: AppColors.paper,
  );

  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.paperMuted,
  );
}