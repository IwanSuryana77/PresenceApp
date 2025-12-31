import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF1B1E6D);
  static const bg = Color(0xFFF6F7FB);
  static const surface = Colors.white;
  static const muted = Color(0xFF6E7A97);
  static const border = Color(0xFFE6E9F2);
}

class AppTheme {
  static ThemeData light() {
    final serif = GoogleFonts.playfairDisplayTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
      textTheme: serif.copyWith(
        headlineSmall: serif.headlineSmall?.copyWith(
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        titleLarge: serif.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
