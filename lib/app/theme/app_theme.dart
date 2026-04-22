import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.voltGreen,
        onPrimary: AppColors.black,
        secondary: AppColors.cyan,
        onSecondary: AppColors.black,
        error: AppColors.electricRed,
        onError: AppColors.chalk,
        surface: AppColors.panel,
        onSurface: AppColors.chalk,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          height: 0.95,
          color: AppColors.chalk,
        ),
        displayMedium: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: AppColors.chalk,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: AppColors.chalk,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: AppColors.chalk,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: AppColors.chalk,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: AppColors.chalk,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: AppColors.black,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.chalk, width: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          foregroundColor: AppColors.chalk,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.chalk,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.panel,
        selectedItemColor: AppColors.voltGreen,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.voltGreen,
        inactiveTrackColor: AppColors.graphite,
        thumbColor: AppColors.chalk,
        overlayShape: SliderComponentShape.noOverlay,
        trackHeight: 6,
      ),
    );
  }
}
