import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  void _verifyOtp() {
    if (_otpController.text.length == 6) {
      _authService.verifyOtpAndNavigate(
        context,
        widget.verificationId,
        _otpController.text,
        widget.phoneNumber,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.otpVerification),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- START: FIX ---
            // استدعاء النص كدالة وتمرير رقم الهاتف لها
            Text(
              localizations.enterOtpSentTo(widget.phoneNumber),
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2,
            ),
            // --- END: FIX ---
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
              decoration: AppInputDecoration.buildOTP('------'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYello,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                localizations.verify,
                style: AppTextStyles.buttonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
