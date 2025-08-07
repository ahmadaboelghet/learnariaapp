import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/screens/intro.dart';
import 'package:learnaria/screens/signup.dart'; // <<< تغيير: سيوجه إلى هنا أولاً
import 'package:learnaria/screens/main_layout.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // User is logged in
            return const MainLayoutScreen();
          } else {
            // User is not logged in, direct to SignUpScreen
            return const IntroScreen();
          }
        }
        // While waiting for connection, show a loading indicator
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
