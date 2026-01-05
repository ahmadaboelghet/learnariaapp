import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/screens/otp_screen.dart'; //
import 'package:cloud_functions/cloud_functions.dart'; // <-- [مهم] لاستدعاء الدالة الجديدة
import 'package:url_launcher/url_launcher.dart'; // <-- [مهم] عشان الـ Hyperlink

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isKeyboardVisible = false;

  final _formKey = GlobalKey<FormState>();
  String _fullPhoneNumber = ""; // لتخزين الرقم كامل
  bool _isLoading = false;
  String? _errorMessage; // لعرض رسالة الخطأ
  bool _isPhoneValid = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // --- [اللوجيك الجديد] ---
  // 1. التحقق من وجود الأب
  // 2. إرسال الـ OTP
  Future<void> _onContinue() async {
    final localizations = AppLocalizations.of(context)!;
    
    // إخفاء الكيبورد
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
      _errorMessage = null; // مسح الأخطاء القديمة
    });

    try {
      // --- الخطوة 1: استدعاء الدالة للتأكد أن الأب موجود ---
      final callable = _functions.httpsCallable('checkParentExists');
      final result = await callable.call({'phoneNumber': _fullPhoneNumber});

      if (!mounted) return; // نتأكد إن الصفحة لسه موجودة

      if (result.data['exists'] == true) {
        // --- الخطوة 2: الأب موجود، ابعت الـ OTP ---
        await _sendOtp(localizations);
      } else {
        // --- الأب غير موجود ---
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

  // دالة إرسال الـ OTP (كما هي، لكن بدون loading)
  Future<void> _sendOtp(AppLocalizations localizations) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // (مش هنعمل حاجة هنا، هنستنى الكود)
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("فشل الإرسال: ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          // --- هنا بنروح لصفحة الـ OTP ---
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("حدث خطأ: ${e.toString()}")));
    }
  }

  // --- دالة لفتح لينك الشروط والأحكام ---
  void _launchTermsURL() async {
    final Uri url = Uri.parse('https://www.learnaria.com/terms'); // (ده لينك مثال، غيره باللينك بتاعك)
    if (!await launchUrl(url)) {
      // (لو فشل الفتح)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open terms page.')),
      );
    }
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
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                // الأنيميشن بتاعك للوجو (ممتاز)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isKeyboardVisible ? 80 : 150,
                  margin: EdgeInsets.only(
                      top: _isKeyboardVisible ? 20 : 50, bottom: 20),
                  child: Image.asset('assets/images/logo.png'),
                ),

                // --- [تم التعديل] ---
                // الكلام اللي تحت اللوجو
                Text(
                  localizations.authTitle, // "Learnaria"
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.authSlogan, // "Learn more, learn smarter"
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.darkGrey),
                ),
                // --- [نهاية التعديل] ---

                const SizedBox(height: 30),

                // --- [تم التعديل] ---
                // شيلنا الـ Tabs واكتفينا بالفورم
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: IntlPhoneField(
                            decoration: InputDecoration(
                              labelText: localizations.authPhoneLabel,
                              hintText: "10 1234 5678",
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            initialCountryCode: 'EG',
                            onChanged: (phone) {
                              _fullPhoneNumber = phone.completeNumber;
                              setState(() {
                                if (phone.countryISOCode == 'EG') {
                                  _isPhoneValid = (phone.number.length == 10);
                                } else {
                                  // (لو بلد تانية، ممكن نعتمد على الفاليديشن الداخلي)
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
                        
                        // --- [جديد] رسالة الخطأ لو الأب مش موجود ---
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyText.copyWith(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // --- [جديد] الشروط والأحكام ---
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTextStyles.bodyText.copyWith(color: AppColors.darkGrey, fontSize: 13),
                              children: [
                                TextSpan(text: "${localizations.authTermsPrefix} "),
                                TextSpan(
                                  text: localizations.authTermsLink,
                                  style: const TextStyle(
                                    color: AppColors.primaryYello,
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
                          onPressed: _isLoading || !_isPhoneValid ? null : _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlack, // <-- اللون الأسود اللي طلبته
                            disabledBackgroundColor: Colors.grey[400], // <-- اللون الرمادي للزر الغير مفعل
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isLoading ? localizations.authChecking : localizations.authContinue,
                                  style: AppTextStyles.buttonText),
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