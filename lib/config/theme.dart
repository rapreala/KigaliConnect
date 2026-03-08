import 'package:flutter/material.dart';

class AppColors {
  // Dark navy backgrounds
  static const Color background    = Color(0xFF0D1B2A);
  static const Color surface       = Color(0xFF162232);
  static const Color surfaceAlt    = Color(0xFF1C2D3F);

  // Orange accent
  static const Color primary       = Color(0xFFFFB300);
  static const Color primaryDark   = Color(0xFFE65100);

  // Feedback
  static const Color error         = Color(0xFFEF5350);
  static const Color success       = Color(0xFF66BB6A);

  // Text
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE);

  // Chips
  static const Color chipSelected   = Color(0xFFFFB300);
  static const Color chipUnselected = Color(0xFF1C2D3F);

  // Category icon colours
  static const Color iconHospital        = Color(0xFFEF5350);
  static const Color iconPolice          = Color(0xFF42A5F5);
  static const Color iconLibrary         = Color(0xFF7E57C2);
  static const Color iconRestaurant      = Color(0xFFFFB300);
  static const Color iconPark            = Color(0xFF66BB6A);
  static const Color iconTourist         = Color(0xFFAB47BC);
  static const Color iconUtility         = Color(0xFF90A4AE);
}

class AppSpacing {
  static const double p4  = 4.0;
  static const double p8  = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;

  static const double r8  = 8.0;
  static const double r12 = 12.0;
  static const double r20 = 20.0;  // pill chips
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.primary,
      secondary: AppColors.primary,
      surface:   AppColors.surface,
      error:     AppColors.error,
      onPrimary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.surface,
      selectedItemColor:    AppColors.primary,
      unselectedItemColor:  AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p16,
        vertical: AppSpacing.p12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.chipUnselected,
      selectedColor: AppColors.chipSelected,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r20),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p12,
        vertical: AppSpacing.p4,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge:  TextStyle(color: AppColors.textPrimary,   fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: AppColors.textPrimary,   fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall:  TextStyle(color: AppColors.textPrimary,   fontSize: 18, fontWeight: FontWeight.bold),
      titleLarge:     TextStyle(color: AppColors.textPrimary,   fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge:      TextStyle(color: AppColors.textPrimary,   fontSize: 16),
      bodyMedium:     TextStyle(color: AppColors.textSecondary, fontSize: 14),
      bodySmall:      TextStyle(color: AppColors.textSecondary, fontSize: 12),
      labelSmall:     TextStyle(color: AppColors.textSecondary, fontSize: 11),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceAlt,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceAlt,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.r8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
