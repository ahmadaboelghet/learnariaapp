import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/custom_text_field.dart';
import 'package:learnaria/widgets/password_text_field.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/screens/login.dart'; // For navigating to login

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;
  bool _agreeToTerms = false;

  Future<void> _signUp() async {
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = "You must agree to the terms and conditions.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String emailFormattedPhoneNumber = "${_phoneController.text.trim()}@learnaria.app";
      await _auth.createUserWithEmailAndPassword(
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
          _errorMessage = e.message ?? 'An error occurred during sign up.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              Text("Create Account", style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello)),
              SizedBox(height: 8),
              Text("Start your journey with Learnaria!", style: AppTextStyles.secondaryText),
              SizedBox(height: 30),
              CustomTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              PasswordTextField(
                controller: _passwordController,
                hintText: 'Password',
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _agreeToTerms = newValue ?? false;
                      });
                    },
                    activeColor: AppColors.primaryYello,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms & Conditions',
                      style: AppTextStyles.secondaryText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
               if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  ),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _agreeToTerms ? _signUp : null,
                        style: primaryButtonStyle(),
                        child: Text('Sign Up', style: AppTextStyles.buttonText),
                      ),
              ),
               SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: AppTextStyles.secondaryText),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoginScreen()));
                      },
                      child: Text('Login', style: AppTextStyles.linkText),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
