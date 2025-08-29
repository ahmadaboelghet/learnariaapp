import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/screens/auth_screen.dart'; // استيراد شاشة المصادقة الجديدة
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
            // المستخدم مسجل دخوله
            return const MainLayoutScreen();
          } else {
            // المستخدم ليس مسجل دخوله
            return const AuthScreen(); // توجيه المستخدم إلى شاشة المصادقة
          }
        }
        // أثناء انتظار الاتصال، يتم عرض مؤشر تحميل
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}