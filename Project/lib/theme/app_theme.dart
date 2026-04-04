import 'package:flutter/material.dart';
import 'package:project56/others/mycolors.dart';

class AppTheme
{
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // ✅ Background
      scaffoldBackgroundColor: kScaffoldBg,

      // ✅ Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: kPrimary,
        onPrimary: kWhite,
        secondary: kAccent,
        onSecondary: kWhite,
        error: Colors.red,
        onError: kWhite,
        background: kScaffoldBg,
        onBackground: kTextPrimary,
        surface: kCardBg,
        onSurface: kTextPrimary,
      ),

      // ✅ AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimaryDark,
        foregroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
      ),

      // ✅ Card
      cardTheme: CardTheme(
        color: kCardBg,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ✅ Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: kTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: kTextPrimary),
        bodyMedium: TextStyle(color: kTextSecondary),
      ),

      // ✅ Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: kWhite,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ✅ Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSubtleBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary),
        ),
      ),

      // ✅ Divider
      dividerColor: kDivider,
    );
  }
}