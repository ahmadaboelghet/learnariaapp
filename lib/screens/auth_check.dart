import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/screens/auth_screen.dart'; // <-- [تعديل] الشاشة الجديدة
import 'package:learnaria/screens/intro.dart';
import 'package:learnaria/screens/main_layout.dart'; //
// import 'package:learnaria/screens/login.dart'; // <-- لم نعد بحاجة له

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // مستخدم سجل دخوله
          return const MainLayoutScreen(); //
        } else {
          // مستخدم لم يسجل دخوله
          return const IntroScreen(); // <-- [تعديل] اعرض الشاشة الجديدة
        }
      },
    );
  }
}