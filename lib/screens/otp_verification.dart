import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/screens/create_new_password.dart';
import 'package:learnaria/utils/app_styles.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  void _verifyOtp() {
    // TODO: Call your cloud function to verify the OTP
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CreateNewPassword()),
    );
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
            Text(
              '${localizations.enterOtpSentTo} ${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2,
            ),
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
