import 'package:flutter/material.dart';
import 'package:learnaria/screens/intro.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import path
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main layout after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const IntroScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center( // Center the entire Row vertically and horizontally
        child: Row( // Changed from Column to Row for horizontal layout
          mainAxisAlignment: MainAxisAlignment.center, // Center content horizontally within the Row
          children: [
            Image.asset(
              'assets/images/learnaria_logo.png', // Ensure this path is correct and image exists
              height: 120,
              width: 240, // Adjusted width for visual balance with text
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.school, size: 60, color: AppColors.primaryYello);
              },
            ),
            const SizedBox(width: 15), // Added horizontal spacing between logo and text
          ],
        ),
      ),
    );
  }
}
