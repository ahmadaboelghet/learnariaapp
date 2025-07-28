import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/custom_text_field.dart';
import 'package:learnaria/screens/main_layout.dart'; // Navigate to main layout on success
import 'dart:async';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken; // For resending OTP
  final bool isAutoVerified; // To indicate if auto-verified (Android)

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
    this.isAutoVerified = false,
  }) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController()); // OTP is usually 6 digits
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isAutoVerified) {
      _startResendTimer();
    }
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < _otpControllers.length - 1) {
          _focusNodes[i + 1].requestFocus();
        } else if (_otpControllers[i].text.isEmpty && i > 0) {
          _focusNodes[i - 1].requestFocus();
        }
        if (_otpControllers.every((controller) => controller.text.isNotEmpty)) {
          // If all fields are filled, auto-verify (optional)
          _verifyOtp();
        }
      });
    }
  }

  void _startResendTimer() {
    _resendCountdown = 60; // Reset timer
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String smsCode = _otpControllers.map((controller) => controller.text).join();

    if (smsCode.length != 6) {
      _errorMessage = 'Please enter the 6-digit code.';
      setState(() { _isLoading = false; });
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Successfully signed in, navigate to main layout
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.code == 'invalid-verification-code') {
          _errorMessage = 'Invalid verification code. Please try again.';
        } else if (e.code == 'session-expired') {
          _errorMessage = 'Verification code expired. Please resend.';
        } else {
          _errorMessage = 'Verification failed: ${e.message}';
        }
        print('OTP Verification Failed: ${e.code} - ${e.message}');
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: $e';
        print('Unexpected error during OTP verification: $e');
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() { _isLoading = false; });
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Resend failed: ${e.message}';
            print('Resend Verification Failed: ${e.code} - ${e.message}');
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            // Update the verificationId if it changes (rare)
            // For simplicity, we assume verificationId remains same or user re-enters
            _startResendTimer(); // Restart timer
            showMessageBox(context, 'New code sent!');
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() { _isLoading = false; });
          print('Resend Auto-retrieval timeout. Verification ID: $verificationId');
        },
        forceResendingToken: widget.resendToken, // Use the token for resending
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred during resend: $e';
        print('Unexpected error during resend: $e');
      });
    }
  }

  void showMessageBox(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              'Verify Your Phone',
              style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello),
            ),
            SizedBox(height: 8),
            Text(
              'Code has been sent to ${widget.phoneNumber}',
              style: AppTextStyles.secondaryText,
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) { // Changed to 6 digits
                return SizedBox(
                  width: 50, // Adjusted width for 6 digits
                  child: CustomTextField(
                    controller: _otpControllers[index],
                    hintText: '-', // Changed placeholder
                    keyboardType: TextInputType.number,
  
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: AppTextStyles.smallRedText.copyWith(color: Colors.red),
              ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: _resendCountdown == 0 && !_isLoading ? _resendCode : null, // Enable resend only when countdown is 0 and not loading
                child: Text(
                  _resendCountdown == 0
                      ? 'Resend Code'
                      : 'Resend Code in ${_resendCountdown}s',
                  style: _resendCountdown == 0 && !_isLoading
                      ? AppTextStyles.linkText
                      : AppTextStyles.secondaryText.copyWith(color: AppColors.mediumGrey),
                ),
              ),
            ),
            SizedBox(height: 40),
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
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

// Helper widget for OTP input is no longer explicitly needed if CustomTextField is used directly
// class OtpInput extends StatelessWidget { ... }
