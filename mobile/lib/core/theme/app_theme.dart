import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: AppColors.warmCream,

      colorScheme: const ColorScheme.light(
        primary: AppColors.ochre,
        secondary: AppColors.charcoal,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.primaryText,
        onError: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h4,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ochre,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: AppTextStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: AppTextStyles.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: AppTextStyles.button,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.ochre, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.secondaryText),
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.border.withValues(alpha: 0.3),
        selectedColor: AppColors.ochreLight,
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primaryText,
        ),
        secondaryLabelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.ochre,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: AppTextStyles.body,
        subtitleTextStyle: AppTextStyles.bodySmall,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.ochre,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        titleTextStyle: AppTextStyles.h4,
        contentTextStyle: AppTextStyles.body,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.charcoal,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
