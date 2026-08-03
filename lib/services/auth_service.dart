import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:learnaria/screens/auth_screen.dart';
import 'package:learnaria/screens/create_new_password.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/screens/otp_verification.dart';
import 'package:learnaria/screens/reset_password_screen.dart';
import 'package:learnaria/screens/welcom.dart';
import 'package:learnaria/widgets/premium_alert.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // دالة لتسجيل الدخول باستخدام رقم الهاتف وكلمة المرور
  Future<void> signInWithPhoneAndPassword(
      BuildContext context, String phoneNumber, String password) async {
    try {
      // Firebase لا يدعم تسجيل الدخول المباشر بالهاتف وكلمة المرور
      // لذا، نستخدم البريد الإلكتروني كحيلة، حيث يكون البريد هو رقم الهاتف
      String email = '$phoneNumber@learnaria.app'; // استخدام نطاق وهمي
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      PremiumAlert.showError(context, e);
    }
  }

  // دالة لإرسال كود التحقق عند التسجيل
  Future<void> sendOtpForSignup(
      BuildContext context,
      String phoneNumber, {
      required VoidCallback onCodeSent,
      required void Function(String error) onFailed,
    }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? 'Verification Failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber, // تمرير رقم الهاتف للشاشة التالية
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // دالة لإعادة إرسال رمز التحقق
  Future<void> resendOtp(
      String phoneNumber, {
      required void Function(String verificationId) onCodeSent,
      required void Function(String error) onFailed,
    }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? 'Verification Failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // دالة للتحقق من الكود والانتقال لإنشاء كلمة المرور
  Future<void> verifyOtpAndNavigate(
      BuildContext context, String verificationId, String smsCode, String phoneNumber,
      {OtpMode mode = OtpMode.signup}) async {
    try {
      if (mode == OtpMode.resetPassword) {
        // For reset: just validate the OTP by signing in, then navigate to reset screen
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        // Validate credential by signing in
        await _auth.signInWithCredential(credential);
        await _auth.signOut();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              phoneNumber: phoneNumber,
              verificationId: verificationId,
              smsCode: smsCode,
            ),
          ),
        );
      } else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        // التحقق من الكود فقط دون تسجيل الدخول
        await _auth.signInWithCredential(credential);
        // تسجيل الخروج فورًا للاستعداد لإنشاء حساب بكلمة مرور
        await _auth.signOut();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNewPassword(phoneNumber: phoneNumber),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? 'Verification Failed';
      if (e.code == 'invalid-verification-code' || e.code == 'invalid-credential') {
        errorMessage = Localizations.localeOf(context).languageCode == 'ar'
            ? 'الرمز المدخل غير صحيح. يرجى التأكد من الرمز والمحاولة مرة أخرى.'
            : 'The entered verification code is incorrect. Please check the code and try again.';
      }
      PremiumAlert.show(context, message: errorMessage, isError: true);
    } catch (e) {
      PremiumAlert.show(context, message: e.toString(), isError: true);
    }
  }

  // دالة لإنشاء مستخدم جديد برقم هاتف وكلمة مرور
  Future<void> createUserWithPhoneAndPassword(
      BuildContext context, String phoneNumber, String password) async {
    try {
      String email = '$phoneNumber@learnaria.app';
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // بعد إنشاء الحساب بنجاح، انتقل إلى شاشة الترحيب
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      PremiumAlert.showError(context, e);
    }
  }

  // دالة للتحقق مما إذا كان حساب ولي الأمر مسجلاً بالفعل
  Future<bool> checkParentAccountExists(String phoneNumber) async {
    String clean = phoneNumber.replaceAll(RegExp(r'[^\d]'), '').trim();
    if (clean.startsWith('20')) {
      clean = clean.substring(2);
    }
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    final String phoneWithPlus = "+20$clean";

    // محاولة استدعاء الدالة السحابية أولاً لأنها الأدق ولا تتأثر بـ email enumeration protection
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('checkAuthUserExists');
      final response = await callable.call(<String, dynamic>{
        'phone': phoneWithPlus,
      });
      if (response.data != null && response.data['exists'] != null) {
        return response.data['exists'] as bool;
      }
    } catch (e) {
      debugPrint("Cloud function checkAuthUserExists failed: $e");
    }

    return false;
  }

  // Send OTP for password reset
  Future<void> sendOtpForPasswordReset(
      BuildContext context,
      String phoneNumber, {
      required VoidCallback onCodeSent,
      required void Function(String error) onFailed,
    }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? 'Verification Failed');
        PremiumAlert.showError(context, e);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
              mode: OtpMode.resetPassword,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Reset password after OTP verification using Cloud Functions
  Future<void> resetUserPassword(
      BuildContext context,
      String phoneNumber,
      String newPassword,
      String verificationId,
      String smsCode) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('resetPassword');
      final response = await callable.call(<String, dynamic>{
        'phoneNumber': phoneNumber,
        'newPassword': newPassword,
      });

      if (response.data != null && response.data['status'] == 'success') {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
          PremiumAlert.show(
            context,
            message: Localizations.localeOf(context).languageCode == 'ar'
                ? 'تم إعادة تعيين كلمة المرور بنجاح! يرجى تسجيل الدخول.'
                : 'Password reset successfully! Please log in.',
            isError: false,
          );
        }
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to reset password');
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        PremiumAlert.show(
          context,
          message: e.message ?? e.toString(),
          isError: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        PremiumAlert.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  // تسجيل الخروج
  Future<void> logout(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      final parentPhone = user?.email?.split('@').first;
      if (parentPhone != null && parentPhone.isNotEmpty) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          List<String> getPhoneFormats(String phone) {
            final clean = phone.replaceAll(RegExp(r'\s+'), '').trim();
            String withZero = clean;
            String withPlus = clean;
            if (clean.startsWith('+20')) {
              withZero = '0${clean.substring(3)}';
            } else if (clean.startsWith('0')) {
              withPlus = '+20${clean.substring(1)}';
            } else {
              withPlus = '+20$clean';
              withZero = '0$clean';
            }
            return [withZero, withPlus].toSet().toList();
          }

          final phoneFormats = getPhoneFormats(parentPhone);
          for (var phoneDocId in phoneFormats) {
            await FirebaseFirestore.instance
                .collection('parents')
                .doc(phoneDocId)
                .update({
              'fcmToken': FieldValue.delete(),
              'fcmTokens': FieldValue.arrayRemove([fcmToken])
            }).catchError((err) => debugPrint('Error removing token on logout: $err'));
          }
          debugPrint('FCM Token successfully removed from parents collection on logout for: $phoneFormats');
        }
      }
    } catch (e) {
      debugPrint('Error removing FCM token during logout: $e');
    }

    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  // جلب معلومات تواصل المدرس الخاص بولي الأمر بشكل آمن ومصرح به
  Future<Map<String, dynamic>?> getTeacherContact(String phoneNumber) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('getTeacherContactForParent');
      final results = await callable.call(<String, dynamic>{
        'phone': phoneNumber,
      });
      if (results.data != null && results.data['found'] == true) {
        return {
          'teacherPhone': results.data['teacherPhone'] as String,
          'teacherName': results.data['teacherName'] as String,
          'groupName': (results.data['groupName'] as String?) ?? 'المجموعة',
        };
      }
    } catch (e) {
      debugPrint("Error calling getTeacherContactForParent: $e");
    }
    return null;
  }
}
