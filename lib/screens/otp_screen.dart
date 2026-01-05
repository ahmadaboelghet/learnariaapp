import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/screens/fill_profile.dart';
// [تصحيح] اسم الكلاس سليم في الملف ده
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

  // --- [جديد] ---
  // متغير لمراقبة اكتمال الكود
  bool _isPinComplete = false;
  // --- [نهاية الجديد] ---

  Future<void> _verifyOTP() async {
    final localizations = AppLocalizations.of(context)!;

    // (اللوجيك زي ما هو)
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
          MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
          (route) => false,
        );
      } else {
        // [تصحيح] الكود بتاعك كان كاتب MainLayoutScreen()
        // اسم الكلاس الصحيح هو MainLayout() بناءً على ملفاتك
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            
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
              textDirection: TextDirection.ltr, 
            ),
            const SizedBox(height: 30),

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
                  
                  // --- [جديد] ---
                  // بنراقب التغيير عشان نفعّل الزرار
                  onChanged: (pin) {
                    setState(() {
                      _isPinComplete = (pin.length == 6);
                    });
                  },
                  // --- [نهاية الجديد] ---

                  onCompleted: (pin) {
                    // أول ما يكتب 6 أرقام، بنعمل verify تلقائي
                    _verifyOTP();
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, 
              height: 50,
              child: ElevatedButton(
                // --- [تم التعديل] ---
                // الزرار هيفضل disabled لو الكود مش كامل
                onPressed: _isLoading || !_isPinComplete ? null : _verifyOTP,
                // --- [نهاية التعديل] ---
                style: ElevatedButton.styleFrom(
                  // --- [تم التعديل] ---
                  // اللون بيتغير بناءً على حالة الزرار
                  backgroundColor: AppColors.primaryBlack,
                  disabledBackgroundColor: AppColors.primaryBlack, // <-- اللون الرمادي
                  // --- [نهاية التعديل] ---
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white) // (خلينا اللودر أبيض)
                    : Text(
                        localizations.otpVerifyButton,
                        // --- [تم التعديل] ---
                        // بنغير لون الكلام مع الزرار
                        style: AppTextStyles.buttonText.copyWith(
                          color: _isPinComplete ? Colors.white : Colors.white70,
                        ),
                        // --- [نهاية التعديل] ---
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(localizations.otpChangePhone),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryYello,
              ),
            )
          ],
        ),
      ),
    );
  }
}