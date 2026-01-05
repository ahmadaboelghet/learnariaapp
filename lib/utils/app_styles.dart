import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // نفس الألوان من ملف style.css
  static const Color primary = Color(0xFFF2CE5A); // الأصفر بتاعنا
  static const Color primaryHover = Color(0xFFE6C045);

  static const Color lightBg = Color(0xFFF3F4F6); // رمادي فاتح للخلفية
  static const Color lightSurface = Colors.white;

  static const Color darkBg = Color(0xFF121212); // الخلفية الغامقة
  static const Color darkSurface = Color(0xFF1E1E1E); // الكروت الغامقة

  static const Color textGrayLight = Color(0xFF1F2937);
  static const Color textGrayDark = Color(0xFFF3F4F6);

  static const Color inputBorderLight = Color(0xFFE5E7EB);
  static const Color inputBorderDark = Color(0xFF374151);
}

class AppTheme {
  // إعدادات الـ Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBg,
      fontFamily: GoogleFonts.cairo().fontFamily, // خط كايرو

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.darkBg,
        surface: AppColors.lightSurface,
        background: AppColors.lightBg,
      ),

      // ستايل الحقول (Inputs) زي الويب
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  // إعدادات الـ Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: GoogleFonts.cairo().fontFamily,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: Colors.white,
        surface: AppColors.darkSurface,
        background: AppColors.darkBg,
      ),

      // ستايل الحقول في الدارك مود
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFA1A1AA),
        ), // لون الـ Placeholder
      ),
    );
  }
}
