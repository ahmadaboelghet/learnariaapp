import 'package:flutter/material.dart';

import 'package:flutter/services.dart'; // For FilteringTextInputFormatter

import 'package:learnaria/utils/app_styles.dart'; // Adjust import

import 'package:learnaria/widgets/custom_text_field.dart'; // Adjust import
import 'package:learnaria/screens/create_new_password.dart'; // Adjust import
import 'dart:async'; // For Timer

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  int _resendCountdown = 60;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _startResendTimer();

    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 &&
            i < _otpControllers.length - 1) {
          _focusNodes[i + 1].requestFocus();
        } else if (_otpControllers[i].text.isEmpty && i > 0) {
          _focusNodes[i - 1].requestFocus();
        }
      });
    }
  }

  void _startResendTimer() {
    _resendCountdown = 60; // Reset timer

    _timer?.cancel(); // Cancel any existing timer

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (var controller in _otpControllers) {
      controller.dispose();
    }

    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'Forget Password',

              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primaryYello,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Code has been sent to ${widget.email}',

              style: AppTextStyles.secondaryText,
            ),

            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,

                  child: CustomTextField(
                    controller: _otpControllers[index],

                    hintText: '*',

                    keyboardType: TextInputType.number,
                  ),
                );
              }),
            ),

            SizedBox(height: 20),

            Align(
              alignment: Alignment.center,

              child: GestureDetector(
                onTap: _resendCountdown == 0 ? _startResendTimer : null,

                child: Text(
                  _resendCountdown == 0
                      ? 'Resend Code'
                      : 'Resend Code in ${_resendCountdown}s',

                  style: _resendCountdown == 0
                      ? AppTextStyles.linkText
                      : AppTextStyles.secondaryText.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                ),
              ),
            ),

            SizedBox(height: 40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  // Simulate OTP verification and navigate to create new password

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateNewPasswordScreen(),
                    ),
                  );
                },

                style: primaryButtonStyle(),

                child: Text('Verify', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for OTP input that centers text and limits length

class OtpInput extends StatelessWidget {
  final TextEditingController controller;

  final FocusNode focusNode;

  const OtpInput({
    super.key,

    required this.controller,

    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,

      child: TextField(
        controller: controller,

        focusNode: focusNode,

        keyboardType: TextInputType.number,

        textAlign: TextAlign.center,

        inputFormatters: [
          LengthLimitingTextInputFormatter(1),

          FilteringTextInputFormatter.digitsOnly,
        ],

        decoration: AppInputDecoration.buildOTP('*'),

        style: AppTextStyles.heading2,
      ),
    );
  }
}
