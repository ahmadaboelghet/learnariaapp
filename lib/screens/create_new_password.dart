import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import
import 'package:learnaria/widgets/password_text_field.dart'; // Adjust import
import 'package:learnaria/screens/password_reset_success.dart'; // Adjust import

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  _CreateNewPasswordScreenState createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Password',
              style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello),
            ),
            SizedBox(height: 8),
            Text(
              'Create you new password',
              style: AppTextStyles.secondaryText,
            ),
            SizedBox(height: 30),
            PasswordTextField(
              controller: _passwordController,
              hintText: 'Password',
            ),
            SizedBox(height: 20),
            PasswordTextField(
              controller: _confirmPasswordController,
              hintText: 'Repeat Password',
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate password change and navigate to success screen
                  if (_passwordController.text == _confirmPasswordController.text &&
                      _passwordController.text.isNotEmpty) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => PasswordResetSuccessScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Passwords do not match or are empty.')),
                    );
                  }
                },
                style: primaryButtonStyle(),
                child: Text('Continue', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
