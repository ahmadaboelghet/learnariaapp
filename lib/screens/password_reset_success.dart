import 'package:flutter/material.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import
import 'dart:async';

class PasswordResetSuccessScreen extends StatefulWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  _PasswordResetSuccessScreenState createState() => _PasswordResetSuccessScreenState();
}

class _PasswordResetSuccessScreenState extends State<PasswordResetSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home page after a few seconds
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainLayoutScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/done.png', // Replace with your actual success image
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/done.png', // Replace with your actual error image
                      height: 150,
                      fit: BoxFit.contain,
                    );
                  },
                ),
                SizedBox(height: 30),
                Text(
                  'Congratulations',
                  style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                Text(
                  'Your Account is Ready to Use. You will be redirected to the Home Page in a Few Seconds.',
                  style: AppTextStyles.secondaryText,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
