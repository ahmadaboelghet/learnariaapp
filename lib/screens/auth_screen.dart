import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/password_text_field.dart';
import 'package:learnaria/widgets/phone_text_field.dart';
import 'package:learnaria/widgets/glass_container.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isKeyboardVisible = false;
  bool _isLogoCentered = true;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Start animation sequence
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLogoCentered = false;
        });
      }
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Animated Logo
              AnimatedAlign(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.fastOutSlowIn,
                alignment: _isLogoCentered
                    ? Alignment.center
                    : (isRtl ? Alignment.topRight : Alignment.topLeft),
                onEnd: () {
                  if (!_isLogoCentered && mounted) {
                    setState(() {
                      _showContent = true;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.fastOutSlowIn,
                  height: _isLogoCentered 
                      ? 180 
                      : (_isKeyboardVisible ? 65 : 130),
                  width: _isLogoCentered 
                      ? 180 
                      : (_isKeyboardVisible ? 65 : 130),
                  margin: EdgeInsets.only(
                    top: _isLogoCentered ? 0 : (_isKeyboardVisible ? 10 : 20),
                    right: !_isLogoCentered && isRtl ? 24 : 0,
                    left: !_isLogoCentered && !isRtl ? 24 : 0,
                  ),
                  child: Image.asset('assets/images/logo_bg.png'),
                ),
              ),

              // 2. Animated Corner Title
              Positioned(
                top: 155,
                left: isRtl ? null : 24,
                right: isRtl ? 24 : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _showContent && !_isKeyboardVisible ? 1.0 : 0.0,
                  child: Text(
                    "Let's Get Started",
                    style: AppTextStyles.heading1.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),

              // 3. Animated Form Content (Slides & Fades in)
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _showContent ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    offset: _showContent ? Offset.zero : const Offset(0, 0.12),
                    curve: Curves.fastOutSlowIn,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        margin: EdgeInsets.only(
                          top: _isKeyboardVisible ? 85 : 210,
                        ),
                        height: size.height - (_isKeyboardVisible ? 140 : 280),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: GlassContainer(
                                  fillOpacity: isDark ? 0.08 : 0.45,
                                  borderOpacity: 0.12,
                                  child: Column(
                                    children: [
                                      TabBar(
                                        controller: _tabController,
                                        labelStyle: AppTextStyles.bodyText
                                            .copyWith(fontWeight: FontWeight.bold),
                                        unselectedLabelStyle: AppTextStyles.bodyText,
                                        indicatorColor: AppColors.primaryYello,
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        labelColor: AppColors.primaryYello,
                                        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      String phoneNumber = _phoneController.text.trim();
      // --- START: FIX for extra zero ---
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
      final String fullPhoneNumber = "+20$phoneNumber";
      // --- END: FIX ---
      _authService.signInWithPhoneAndPassword(
          context, fullPhoneNumber, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Form(
        key: _formKey,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
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
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _login,
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
  final _phoneController = TextEditingController();
  bool _agreedToTerms = false;
  final AuthService _authService = AuthService();

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
            content: Text(AppLocalizations.of(context)!.mustAgreeToTermsError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      String phoneNumber = _phoneController.text.trim();
      // --- START: FIX for extra zero ---
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
      final String fullPhoneNumber = "+20$phoneNumber";
      // --- END: FIX ---
      _authService.sendOtpForSignup(context, fullPhoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Form(
        key: _formKey,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
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
                child:
                    Text(localizations.signup, style: AppTextStyles.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
