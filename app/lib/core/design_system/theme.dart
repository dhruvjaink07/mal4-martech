import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

/// Central ThemeData definitions for Dark and Light mode.
class AppTheme {
  AppTheme._();

  /// Dark Theme (Default Architectural SaaS theme)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.defenseGreen,
        onPrimary: Colors.white,
        secondary: AppColors.defenseBlack,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkForeground,
        error: AppColors.defenseRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderLg,
          side: BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkMutedText),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkMutedText),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.defenseGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.defenseRed, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.defenseGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(64.0, AppSpacing.primaryButtonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.borderMd),
          textStyle: AppTypography.titleMedium.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.defenseGreen,
        onPrimary: Colors.white,
        secondary: AppColors.defenseBlack,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightForeground,
        error: AppColors.defenseRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderLg,
          side: BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightMutedText),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightMutedText),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.defenseGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderMd,
          borderSide: const BorderSide(color: AppColors.defenseRed, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.defenseGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(64.0, AppSpacing.primaryButtonHeight),
          shape: const RoundedRectangleBorder(borderRadius: AppSpacing.borderMd),
          textStyle: AppTypography.titleMedium.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1.0,
        space: 1.0,
      ),
    );
  }
}
