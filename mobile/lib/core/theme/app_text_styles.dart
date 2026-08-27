import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'HankenGrotesk';

  static const TextStyle h1 = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.8,
    color: AppColors.primaryText,
    fontFamily: fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.32,
    color: AppColors.primaryText,
    fontFamily: fontFamily,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.primaryText,
    fontFamily: fontFamily,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.primaryText,
    fontFamily: fontFamily,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: AppColors.primaryText,
    fontFamily: fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: AppColors.primaryText,
    fontFamily: fontFamily,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.5,
    color: AppColors.secondaryText,
    fontFamily: fontFamily,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
    fontFamily: fontFamily,
  );
}
