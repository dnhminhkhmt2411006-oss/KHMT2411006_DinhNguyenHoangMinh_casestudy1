import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2563EB);      // xanh dương chủ đạo
  static const income = Color(0xFF16A34A);       // xanh lá (Thu)
  static const incomeBg = Color(0xFFE8F7EE);
  static const expense = Color(0xFFEF4444);      // đỏ (Chi)
  static const expenseBg = Color(0xFFFDECEC);
  static const background = Color(0xFFF5F7FB);
  static const textDark = Color(0xFF1F2937);
  static const textGrey = Color(0xFF9CA3AF);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textDark,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
  );
}