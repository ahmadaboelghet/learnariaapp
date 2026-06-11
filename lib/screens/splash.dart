import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnaria/screens/auth_check.dart'; 
import 'package:learnaria/screens/intro.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnaria/utils/app_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد الـ Animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // مدة ظهور الشعار
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // بدء الـ Animation
    _animationController.forward();

    // المؤقت للانتقال إلى الشاشة التالية بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final isFirstTime = prefs.getBool('is_first_time') ?? true;

        if (isFirstTime) {
          await prefs.setBool('is_first_time', false);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const IntroScreen()),
            );
          }
        } else {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthCheck()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // التخلص من الكنترولر لتجنب تسريب الذاكرة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // استخدام FadeTransition لتطبيق تأثير الظهور التدريجي
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/learnaria_logo.png',
                width: 220, // يمكنك تعديل الحجم حسب رغبتك
              ),
              const SizedBox(height: 16),
              Text(
                'Stay Connected. Stay Guided',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}