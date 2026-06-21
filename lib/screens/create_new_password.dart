import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/password_text_field.dart';
import 'package:learnaria/widgets/glass_container.dart';
import 'package:learnaria/widgets/pulse_loader.dart';

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
  bool _isLoading = false;

  void _createPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.createUserWithPhoneAndPassword(
          context,
          widget.phoneNumber,
          _passwordController.text,
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.createPassword,
          style: AppTextStyles.heading2.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // <-- Aligns the header title to the side
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: GlassContainer(
                borderRadius: 24,
                fillOpacity: isDark ? 0.08 : 0.45,
                borderOpacity: 0.12,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Icon with glowing effect
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYello.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryYello.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 40,
                              color: AppColors.primaryYello,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          localizations.createPassword,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Set a strong password for your new account to ensure its security.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.secondaryText.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYello,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: AppColors.primaryYello.withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const PulseLoader(size: 28)
                              : Text(
                                  localizations.continue_,
                                  style: AppTextStyles.buttonText.copyWith(
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
