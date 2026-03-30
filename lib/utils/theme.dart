import 'package:flutter/material.dart';

const Color primaryBlue = Color(0xFF1E40AF); // Deep indigo blue
const Color primaryLight = Color(0xFF3B82F6); // Vibrant accent blue
const Color successGreen = Color(0xFF10B981); // Emerald green
const Color errorRed = Color(0xFFEF4444); // Rose red
const Color backgroundLight = Color(0xFFF1F5F9);
const Color surfaceWhite = Colors.white;
const Color textPrimary = Color(0xFF0F172A); // Slate 900
const Color textSecondary = Color(0xFF64748B); // Slate 500

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: primaryBlue,
    secondary: primaryLight,
    surface: surfaceWhite,
    error: errorRed,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textPrimary,
    onError: Colors.white,
    outlineVariant: Colors.grey.withValues(alpha: 0.1),
  ),
  scaffoldBackgroundColor: backgroundLight,
  cardTheme: CardThemeData(
    color: surfaceWhite,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: surfaceWhite,
    selectedItemColor: primaryBlue,
    unselectedItemColor: textSecondary,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
    titleMedium: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
    bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
    bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
  ),
);
