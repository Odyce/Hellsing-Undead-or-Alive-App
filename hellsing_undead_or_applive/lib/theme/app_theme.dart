import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary           = Color(0xFF754300); // brun sombre
  static const Color secondary         = Color(0xFFA66C1E); // ambre moyen
  static const Color tertiary          = Color(0xFF8B6356); // brun-rouge
  static const Color primaryContainer  = Color(0xFFAC8B67); // brun clair/tan
  static const Color secondaryContainer = Color(0xFFD1907C); // saumon
  static const Color tertiaryContainer = Color(0xFFEAD1CA); // pêche clair

  // Admin / User badge
  static const Color adminBadge = Color(0xFFA66C1E);
  static const Color userBadge  = Color(0xFF8B6356);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      primary:              AppColors.primary,
      onPrimary:            Colors.white,
      primaryContainer:     AppColors.primaryContainer,
      onPrimaryContainer:   const Color(0xFF2A1000),
      secondary:            AppColors.secondary,
      onSecondary:          Colors.white,
      secondaryContainer:   AppColors.secondaryContainer,
      onSecondaryContainer: const Color(0xFF2D1000),
      tertiary:             AppColors.tertiary,
      onTertiary:           Colors.white,
      tertiaryContainer:    AppColors.tertiaryContainer,
      onTertiaryContainer:  const Color(0xFF2D1510),
      surfaceContainerHighest: AppColors.tertiaryContainer,
      outline:              AppColors.tertiary,
      surfaceTint:          AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      appBarTheme: const AppBarTheme(
        backgroundColor:  AppColors.primary,
        foregroundColor:  Colors.white,
        elevation:        0,
        iconTheme:        IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),

      chipTheme: ChipThemeData(
        selectedColor:    AppColors.secondaryContainer,
        checkmarkColor:   AppColors.primary,
        backgroundColor:  AppColors.tertiaryContainer,
        side:             const BorderSide(color: AppColors.primaryContainer),
        labelStyle:       const TextStyle(color: Color(0xFF2D1000)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      cardTheme: const CardThemeData(
        color:     AppColors.tertiaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryContainer),
        ),
        labelStyle: const TextStyle(color: AppColors.tertiary),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        prefixIconColor: AppColors.secondary,
        suffixIconColor: AppColors.tertiary,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.secondary;
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondary,
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primaryContainer,
        contentTextStyle: TextStyle(color: Color(0xFF2A1000)),
        actionTextColor: AppColors.primary,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.primaryContainer,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.secondary,
      ),
    );
  }
}
