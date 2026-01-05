import 'package:flutter/material.dart';

// Define common colors
class AppColors {
  static const Color primaryYello = Color.fromARGB(
    255,
    229,
    173,
    53,
  ); // A vibrant red
  static const Color primaryBlack = Color(0xFF212121); // Dark text/button color
  static const Color lightGrey = Color(0xFFF5F5F5); // Background/field color
  static const Color mediumGrey = Color.fromARGB(
    255,
    170,
    169,
    162,
  ); // Icon/placeholder color
  static const Color darkGrey = Color(0xFF616161); // Secondary text color
  static const Color greenSuccess = Color(0xFF4CAF50); // Green for success
}

// Define common text styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlack,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlack,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.primaryBlack,
  );

  static const TextStyle secondaryText = TextStyle(
    fontSize: 14,
    color: AppColors.darkGrey,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    color: AppColors.primaryYello,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle smallRedText = TextStyle(
    fontSize: 12,
    color: AppColors.primaryYello,
  );

  static const TextStyle smallGreenText = TextStyle(
    fontSize: 12,
    color: AppColors.greenSuccess,
  );
}

// Define common input decoration
class AppInputDecoration {
  static InputDecoration build(
    String hintText, {
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.secondaryText,
      filled: true,
      fillColor: AppColors.lightGrey,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.mediumGrey)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none, // No border line
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: AppColors.primaryYello,
          width: 1.5,
        ), // Highlight on focus
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    );
  }

  static InputDecoration buildOTP(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.secondaryText,
      filled: true,
      fillColor: AppColors.lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none, // No border line
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: AppColors.primaryYello,
          width: 1.5,
        ), // Highlight on focus
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      counterText: "", // Hide character counter
    );
  }
}

// Custom button style
ButtonStyle primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryBlack, // Button background color
    foregroundColor: Colors.white, // Text color
    padding: EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    elevation: 5,
    shadowColor: Colors.black.withOpacity(0.2),
  );
}
