import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/screens/auth_screen.dart';
import 'package:learnaria/screens/create_new_password.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/screens/otp_verification.dart';
import 'package:learnaria/screens/welcom.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.message}')),
      );
    }
  }

  // دالة لإرسال كود التحقق عند التسجيل
  Future<void> sendOtpForSignup(BuildContext context, String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
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
      BuildContext context, String verificationId, String smsCode, String phoneNumber) async {
    try {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Failed: ${e.message}')),
      );
    }
  }

  // تسجيل الخروج
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }
}
