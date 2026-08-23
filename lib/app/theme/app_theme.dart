import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const seedColor = Color(0xFF0E3A8A);
    const primaryDeep = Color(0xFF081B3D);
    const surfaceTint = Color(0xFFF1F6FF);
    const outlineColor = Color(0xFFD6E2F2);
    const textPrimary = Color(0xFF0F172A);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial', 'sans-serif'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceTint,
      // Popup routes such as DropdownButton use the canvas color. Keeping it
      // opaque prevents menus from visually merging with fields underneath.
      canvasColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      dividerColor: outlineColor,
      drawerTheme: const DrawerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: outlineColor),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDeep,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9AB0DB),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: outlineColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
        labelStyle: const TextStyle(color: Color(0xFF334155)),
        hintStyle: const TextStyle(color: Color(0xFF7C8CA5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: seedColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: Color(0xFF475569), height: 1.55),
        bodyMedium: TextStyle(color: Color(0xFF475569), height: 1.5),
        bodySmall: TextStyle(color: Color(0xFF64748B), height: 1.42),
        labelLarge: TextStyle(
          color: seedColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF123D9B)),
    );
  }
}
