import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumAlert {
  /// Maps a Firebase exception or raw error to a clean, user-friendly, localized message.
  static String getLocalizedError(BuildContext context, dynamic error) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return isAr 
              ? 'رقم الهاتف أو كلمة المرور غير صحيحة.' 
              : 'Incorrect phone number or password.';
        case 'user-disabled':
          return isAr 
              ? 'تم تعطيل هذا الحساب. يرجى التواصل مع الإدارة.' 
              : 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return isAr 
              ? 'محاولات كثيرة جداً خاطئة. يرجى المحاولة بعد قليل.' 
              : 'Too many login attempts. Please try again later.';
        case 'network-request-failed':
          return isAr 
              ? 'فشل الاتصال بالشبكة. تحقق من الإنترنت الخاص بك.' 
              : 'Network request failed. Please check your internet connection.';
        case 'invalid-phone-number':
          return isAr 
              ? 'رقم الهاتف المدخل غير صحيح.' 
              : 'The phone number entered is invalid.';
        case 'session-expired':
          return isAr 
              ? 'انتهت صلاحية الجلسة. يرجى إعادة طلب كود التحقق.' 
              : 'Verification session expired. Please request a new code.';
        case 'quota-exceeded':
          return isAr 
              ? 'تم تجاوز حد إرسال الرسائل (SMS). يرجى المحاولة لاحقاً.' 
              : 'SMS quota exceeded. Please try again later.';
        case 'credential-already-in-use':
        case 'email-already-in-use':
          return isAr 
              ? 'رقم الهاتف هذا مسجل بالفعل بحساب آخر.' 
              : 'This phone number is already registered under another account.';
        default:
          return isAr 
              ? 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.' 
              : 'An unexpected error occurred. Please try again.';
      }
    }
    
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return isAr 
          ? 'تعذر الاتصال بالخادم. يرجى التحقق من الشبكة.' 
          : 'Could not connect to server. Please check your connection.';
    }
    
    return isAr 
        ? 'حدث خطأ أثناء العملية. يرجى المحاولة لاحقاً.' 
        : 'An error occurred during the process. Please try again later.';
  }

  /// Displays a floating premium snackbar with Cairo font, tailored for light/dark modes.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Premium color palette mapping
    final bgColor = isError 
        ? (isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFEECEB))
        : (isDark ? const Color(0xFF1B3D2B) : const Color(0xFFEBFDF3));
        
    final borderColor = isError
        ? (isDark ? const Color(0xFFE57373) : const Color(0xFFF5C2C1))
        : (isDark ? const Color(0xFF81C784) : const Color(0xFFA3E2B5));
        
    final textColor = isError
        ? (isDark ? const Color(0xFFFFCDD2) : const Color(0xFFC53030))
        : (isDark ? const Color(0xFFC8E6C9) : const Color(0xFF1B5E20));

    final icon = isError 
        ? Icons.error_outline_rounded 
        : Icons.check_circle_outline_rounded;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 20,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Helper to automatically map and show an error.
  static void showError(BuildContext context, dynamic error) {
    final message = getLocalizedError(context, error);
    show(context, message: message, isError: true);
  }
}
