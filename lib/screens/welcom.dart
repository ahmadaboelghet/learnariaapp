import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/utils/app_styles.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showWelcomeMessage = true;

  @override
  void initState() {
    super.initState();
    // إخفاء رسالة الترحيب بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الشاشة الرئيسية في الخلفية
          const MainLayoutScreen(),

          // رسالة الترحيب التي تتلاشى
          AnimatedOpacity(
            opacity: _showWelcomeMessage ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            // تجاهل اللمس عندما تكون الرسالة مخفية
            child: IgnorePointer(
              ignoring: !_showWelcomeMessage,
              child: _WelcomeOverlay(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      color: Colors.white.withOpacity(0.9), // خلفية شبه شفافة
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/done.png', height: 150),
            const SizedBox(height: 20),
            Text(
              localizations.helloParent,
              style: AppTextStyles.heading1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
