import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/screens/auth_screen.dart';
import 'package:learnaria/screens/intro.dart';
import 'package:learnaria/screens/splash.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/utils/app_styles.dart';

class InitialScreenSelector extends StatelessWidget {
  final bool isFirstTime;

  const InitialScreenSelector({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            // User is logged in -> show animated splash screen -> then MainLayoutScreen
            return const SplashScreen(navigateTo: MainLayoutScreen());
          } else {
            // User is NOT logged in
            if (isFirstTime) {
              // First time opening app -> show animated splash screen -> then IntroScreen
              return const SplashScreen(navigateTo: IntroScreen());
            } else {
              // Not first time -> start directly on AuthScreen (Login)
              return const AuthScreen();
            }
          }
        }
        // While Firebase verifies authentication state, show a clean background with loader
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryYello,
            ),
          ),
        );
      },
    );
  }
}
