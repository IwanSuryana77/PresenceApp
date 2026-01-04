import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF1B1E6D);
  static const Color lightBlue = Color(0xFF2196F3);
  static const Color grey = Color(0xFF757575);
  static const Color muted = Color(0xFF999999);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.navy,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.navy),
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
