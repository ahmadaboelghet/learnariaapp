import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
        PremiumAlert.showError(context, e);
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
    } catch (e) {
      PremiumAlert.showError(context, e);
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

  // Reset password after OTP verification
  Future<void> resetUserPassword(
      BuildContext context,
      String phoneNumber,
      String newPassword,
      String verificationId,
      String smsCode) async {
    try {
      final email = '$phoneNumber@learnaria.app';
      final phoneCred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with phone credential
      final userCredential = await _auth.signInWithCredential(phoneCred);
      final user = userCredential.user!;

      // Check if this user has email/password provider linked
      final hasEmailProvider = user.providerData
          .any((info) => info.providerId == 'password');

      if (hasEmailProvider) {
        // Directly update password on this account
        await user.updatePassword(newPassword);
      } else {
        // Phone user is separate from email/password account.
        // Delete phone user, then recreate the email account with new password.
        await user.delete();
        try {
          await _auth.createUserWithEmailAndPassword(
              email: email, password: newPassword);
        } on FirebaseAuthException catch (createErr) {
          if (createErr.code == 'email-already-in-use') {
            // Email account exists with a different password that we can't retrieve.
            // Inform the user to contact support.
            if (context.mounted) {
              PremiumAlert.show(
                context,
                message: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'تعذر إعادة تعيين كلمة المرور. يرجى التواصل مع الدعم.'
                    : 'Unable to reset password automatically. Please contact support.',
                isError: true,
              );
            }
            return;
          }
          rethrow;
        }
      }

      // Sign out and navigate back to login
      await _auth.signOut();
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
    } on FirebaseAuthException catch (e) {
      PremiumAlert.showError(context, e);
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
}
