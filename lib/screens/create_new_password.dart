import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/screens/welcom.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/password_text_field.dart';

class CreateNewPassword extends StatefulWidget {
  const CreateNewPassword({super.key});

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _createPassword() {
    // TODO: Save the new password
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.createPassword),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordTextField(
              controller: _passwordController,
              labelText: localizations.password,
              hintText: localizations.password, // Corrected
            ),
            const SizedBox(height: 20),
            PasswordTextField(
              controller: _confirmPasswordController,
              labelText: localizations.confirmPassword,
              hintText: localizations.confirmPassword, // Corrected
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _createPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYello,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                localizations.continue_,
                style: AppTextStyles.buttonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
