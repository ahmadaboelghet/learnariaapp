import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/custom_text_field.dart';
import 'package:learnaria/widgets/password_text_field.dart';
import 'package:learnaria/screens/signup.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/screens/forget_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String emailFormattedPhoneNumber = "${_phoneController.text.trim()}@learnaria.app";

      await _auth.signInWithEmailAndPassword(
        email: emailFormattedPhoneNumber,
        password: _passwordController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'An error occurred.';
        });
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Login', style: AppTextStyles.heading2),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text("Welcome Back!", style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello)),
            SizedBox(height: 8),
            Text("Login with your phone number and password.", style: AppTextStyles.secondaryText),
            SizedBox(height: 40),
            CustomTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            PasswordTextField(
              controller: _passwordController,
              hintText: 'Password',
            ),
            SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ForgetPasswordScreen()),
                  );
                },
                child: Text('Forget Password?', style: AppTextStyles.linkText),
              ),
            ),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              ),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      style: primaryButtonStyle(),
                      child: Text('Login', style: AppTextStyles.buttonText),
                    ),
                  ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ", style: AppTextStyles.secondaryText),
                GestureDetector(
                  onTap: () {
                    // Navigate to SignUp, replacing the current login screen
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => SignUpScreen()));
                  },
                  child: Text('Sign Up', style: AppTextStyles.linkText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
