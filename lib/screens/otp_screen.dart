import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/screens/fill_profile.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:pinput/pinput.dart';
import 'package:learnaria/l10n/app_localizations.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  Future<void> _verifyOTP() async {
    final localizations = AppLocalizations.of(context)!;

    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.otpEnter6Digits)));
      return;
    }
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _pinController.text,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      setState(() => _isLoading = false);

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const FillProfileScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = localizations.otpErrorInvalidCode;
      if (e.code == 'invalid-verification-code') {
         errorMessage = localizations.otpErrorInvalidCode;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.otpVerifyTitle),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // --- [تم التعديل] ---
      // شيلنا الـ Center عشان الكلام يطلع فوق
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // --- [تم التعديل] ---
          // خلينا المحاذاة "للجنب" (start)
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- [تم الإضافة] ---
            // ضفنا مسافة فوق عشان متبقاش لازقة في الـ AppBar
            const SizedBox(height: 40),
            
            // --- [تم الحذف] ---
            // تم حذف اللوجو بناءً على طلبك

            Text(
              localizations.otpSentTo,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.phoneNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textDirection: TextDirection.ltr, // عشان الرقم يظهر صح
            ),
            const SizedBox(height: 30),

            // --- [تم التعديل] ---
            // ضفنا Center هنا عشان حقل الإدخال يفضل في النص
            Center(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _focusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppColors.primaryYello),
                    ),
                  ),
                  onCompleted: (pin) {
                    _verifyOTP();
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // الزر هيفضل بعرض الشاشة
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYello,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        localizations.otpVerifyButton,
                        style: AppTextStyles.buttonText,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // الزر ده هيفضل على الشمال (start) بسبب الـ CrossAxisAlignment
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(localizations.otpChangePhone),
            )
          ],
        ),
      ),
    );
  }
}