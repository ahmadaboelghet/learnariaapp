import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/screens/otp_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:learnaria/widgets/glass_card.dart'; // تأكد من وجود هذا الملف

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isKeyboardVisible = false;

  final _formKey = GlobalKey<FormState>();
  String _fullPhoneNumber = "";
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhoneValid = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> _onContinue() async {
    final localizations = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() || _fullPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseEnterPhone),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final callable = _functions.httpsCallable('checkParentExists');
      final result = await callable.call({'phoneNumber': _fullPhoneNumber});

      if (!mounted) return;

      if (result.data['exists'] == true) {
        await _sendOtp(localizations);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = localizations.authParentNotFoundError;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? "Failed to check parent.";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An unknown error occurred.";
      });
    }
  }

  Future<void> _sendOtp(AppLocalizations localizations) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("فشل الإرسال: ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                verificationId: verificationId,
                phoneNumber: _fullPhoneNumber,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isLoading = false);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ: ${e.toString()}")));
    }
  }

  void _launchTermsURL() async {
    final Uri url = Uri.parse('https://www.learnaria.com/terms');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open terms page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isKeyboardVisible) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  Text(
                    localizations.authTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.authSlogan,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // --- التصميم الزجاجي للكارت ---
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: IntlPhoneField(
                            decoration: InputDecoration(
                              labelText: localizations.authPhoneLabel,
                              hintText: "10 1234 5678",
                            ),
                            initialCountryCode: 'EG',
                            onChanged: (phone) {
                              _fullPhoneNumber = phone.completeNumber;
                              setState(() {
                                if (phone.countryISOCode == 'EG') {
                                  _isPhoneValid = (phone.number.length == 10);
                                } else {
                                  _isPhoneValid = phone.isValidNumber();
                                }
                              });
                            },
                            validator: (phone) {
                              if (phone == null || phone.number.isEmpty) {
                                return localizations.pleaseEnterPhone;
                              }
                              return null;
                            },
                          ),
                        ),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7),
                                fontSize: 13,
                                fontFamily: 'Cairo',
                              ),
                              children: [
                                TextSpan(
                                  text: "${localizations.authTermsPrefix} ",
                                ),
                                TextSpan(
                                  text: localizations.authTermsLink,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _launchTermsURL,
                                ),
                              ],
                            ),
                          ),
                        ),

                        ElevatedButton(
                          onPressed: _isLoading || !_isPhoneValid
                              ? null
                              : _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                              : Text(
                                  _isLoading
                                      ? localizations.authChecking
                                      : localizations.authContinue,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ],
                    ),
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
