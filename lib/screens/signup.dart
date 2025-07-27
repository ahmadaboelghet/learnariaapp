import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import
import 'package:learnaria/widgets/custom_text_field.dart'; // Adjust import
import 'package:learnaria/widgets/password_text_field.dart'; // Adjust import
import 'package:learnaria/screens/forget_password.dart'; // Adjust import
import 'package:learnaria/screens/fill_profile.dart'; // Adjust import

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _agreeToTerms = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Sign Up',
          style: AppTextStyles.heading2,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Let's get started",
              style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello),
            ),
            SizedBox(height: 8),
            Text(
              "Create an account to start learning",
              style: AppTextStyles.secondaryText,
            ),
            SizedBox(height: 30),
            CustomTextField(
              controller: _emailController,
              hintText: 'example@gmail.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            PasswordTextField(
              controller: _passwordController,
              hintText: 'Password',
            ),
            SizedBox(height: 20),
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
                    'Agree to Terms & Conditions',
                    style: AppTextStyles.secondaryText,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreeToTerms
                    ? () {
                        // Simulate sign up and navigate to FillProfileScreen
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => FillProfileScreen()),
                        );
                      }
                    : null, // Disable button if terms not agreed
                style: primaryButtonStyle(),
                child: Text('Sign Up', style: AppTextStyles.buttonText),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an Account? ',
                  style: AppTextStyles.secondaryText,
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to a login screen if you had one, or back to intro/signup
                    // For this example, let's just show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign In functionality would go here!')),
                    );
                  },
                  child: Text(
                    'Sign in',
                    style: AppTextStyles.linkText,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ForgetPasswordScreen()),
                  );
                },
                child: Text(
                  'Forget Password?',
                  style: AppTextStyles.linkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
