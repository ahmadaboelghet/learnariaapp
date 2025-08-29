import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/screens/forget_password.dart';
import 'package:learnaria/screens/main_layout.dart';
import 'package:learnaria/screens/otp_verification.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/password_text_field.dart';
import 'package:learnaria/widgets/phone_text_field.dart'; // Import the new widget

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isKeyboardVisible ? 80 : 150,
                  margin: EdgeInsets.only(top: _isKeyboardVisible ? 20 : 50, bottom: 20),
                  child: Image.asset('assets/images/logo.png'),
                ),
                Text(
                  "Let's Get Started",
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  labelStyle: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: AppTextStyles.bodyText,
                  indicatorColor: AppColors.primaryYello,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primaryBlack,
                  unselectedLabelColor: AppColors.darkGrey,
                  tabs: [
                    Tab(text: localizations.login),
                    Tab(text: localizations.signup),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _LoginFormWidget(),
                      _SignupFormWidget(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Login Form Widget ---
class _LoginFormWidget extends StatefulWidget {
  const _LoginFormWidget();

  @override
  State<_LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<_LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_formKey.currentState!.validate()) {
      final String fullPhoneNumber = "+20${_phoneController.text.substring(1)}";
      print("Logging in with: $fullPhoneNumber");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhoneTextField(
              controller: _phoneController,
              hintText: "01x xxx xxxx",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterPhone;
                }
                final regex = RegExp(r'^01[0125][0-9]{8}$');
                if (!regex.hasMatch(value)) {
                  return "ادخل رقم هاتف مصري صحيح";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            PasswordTextField(
              controller: _passwordController,
              labelText: localizations.password,
              hintText: localizations.password,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterPassword;
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgetPassword()));
                },
                child: Text(
                  localizations.forgotPassword,
                  style: AppTextStyles.linkText,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYello,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(localizations.login, style: AppTextStyles.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Signup Form Widget ---
class _SignupFormWidget extends StatefulWidget {
  const _SignupFormWidget();

  @override
  State<_SignupFormWidget> createState() => __SignupFormWidgetState();
}

class __SignupFormWidgetState extends State<_SignupFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.agreeToTerms),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final String fullPhoneNumber = "+20${_phoneController.text.substring(1)}";
      print("Signing up with: $fullPhoneNumber");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(phoneNumber: fullPhoneNumber),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhoneTextField(
              controller: _phoneController,
              hintText: "01x xxx xxxx",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterPhone;
                }
                final regex = RegExp(r'^01[0125][0-9]{8}$');
                if (!regex.hasMatch(value)) {
                  return "ادخل رقم هاتف مصري صحيح";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value!;
                    });
                  },
                  activeColor: AppColors.primaryYello,
                ),
                Expanded(
                  child: Text(
                    localizations.agreeToTerms,
                    style: AppTextStyles.bodyText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYello,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(localizations.signup, style: AppTextStyles.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
