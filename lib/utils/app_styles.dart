import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Define common colors with modern vibrant palette for liquid glass look
class AppColors {
  static const Color primaryYello = Color(0xFFEBB84D); // Spot Dashboard Gold/Amber
  static const Color primaryBlue = Color(0xFF00C6FF);  
  static const Color primaryPurple = Color(0xFF7000FF); 
  static const Color primaryBlack = Color(0xFF0D0E12); // Deep dashboard dark
  static const Color lightGrey = Color(0xFF16171D); 
  static const Color darkGrey = Color(0xFF8A90A0); 
  static const Color mediumGrey = Color(0xFF262930); 
  static const Color greenSuccess = Color(0xFF2ECC71); 
  static const Color errorRed = Color(0xFFE74C3C);

  // Glass specific colors
  static const Color glassLight = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x0DFFFFFF);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x1AFFFFFF);
}

// Define common text styles using GoogleFonts Cairo
class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle heading2 = GoogleFonts.cairo(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static TextStyle bodyText = GoogleFonts.cairo(
    fontSize: 16,
  );

  static TextStyle secondaryText = GoogleFonts.cairo(
    fontSize: 14,
  );

  static TextStyle linkText = GoogleFonts.cairo(
    fontSize: 14,
    color: AppColors.primaryYello,
    fontWeight: FontWeight.w600,
  );

  static TextStyle buttonText = GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle smallRedText = GoogleFonts.cairo(
    fontSize: 12,
    color: AppColors.errorRed,
  );

  static TextStyle smallGreenText = GoogleFonts.cairo(
    fontSize: 12,
    color: AppColors.greenSuccess,
  );
}

// Define common input decoration for Liquid Glass theme
class AppInputDecoration {
  static InputDecoration build(String hintText, {IconData? prefixIcon, Widget? suffixIcon, BuildContext? context}) {
    final isDark = context != null ? Theme.of(context).brightness == Brightness.dark : true;
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.secondaryText.copyWith(color: isDark ? Colors.white38 : Colors.black38),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDark ? Colors.white60 : Colors.black54) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: AppColors.primaryYello, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    );
  }

  static InputDecoration buildOTP(String hintText, {BuildContext? context}) {
    final isDark = context != null ? Theme.of(context).brightness == Brightness.dark : true;
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.secondaryText.copyWith(color: isDark ? Colors.white38 : Colors.black38),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: AppColors.primaryYello, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      counterText: "",
    );
  }
}

// Custom button style
ButtonStyle primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryYello,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    elevation: 0,
  );
}