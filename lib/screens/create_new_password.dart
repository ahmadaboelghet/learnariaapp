import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/password_text_field.dart';

class CreateNewPassword extends StatefulWidget {
  final String phoneNumber;
  const CreateNewPassword({super.key, required this.phoneNumber});

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  void _createPassword() {
    if (_formKey.currentState!.validate()) {
      _authService.createUserWithPhoneAndPassword(
        context,
        widget.phoneNumber,
        _passwordController.text,
      );
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordTextField(
                controller: _passwordController,
                labelText: localizations.password,
                hintText: localizations.password,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PasswordTextField(
                controller: _confirmPasswordController,
                labelText: localizations.confirmPassword,
                hintText: localizations.confirmPassword,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
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
      ),
    );
  }
}
