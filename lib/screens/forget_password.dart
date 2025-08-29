import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/screens/otp_verification.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/custom_text_field.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      // TODO: Call cloud function to send OTP for password reset
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(phoneNumber: _phoneController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.forgotPassword),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/logo.png', height: 120),
                  const SizedBox(height: 20),
                  Text(
                    localizations.forgotPassword,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    localizations.enterPhoneToReset, // You need to add this key to your .arb files
                    textAlign: TextAlign.center,
                    style: AppTextStyles.secondaryText,
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: localizations.phoneNumber,
                    hintText: localizations.phoneNumber,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.pleaseEnterPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYello,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      localizations.continue_,
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
