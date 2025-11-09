import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/utils/app_styles.dart';
// import 'package:learnaria/widgets/phone_text_field.dart'; // <-- تم الإلغاء
import 'package:intl_phone_field/intl_phone_field.dart'; // <-- البديل
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/screens/otp_screen.dart'; // <-- (هنحتاج الشاشة دي)

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
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
    // الكود بتاعك للأنيميشن (ممتاز)
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SizedBox(
            // الكود ده بيضمن إن الصفحة تاخد طول الشاشة وميحصلش Overflow
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
                Text(
                  "Let's Get Started", // (يفضل إضافة دي للترجمة)
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  labelStyle: AppTextStyles.bodyText
                      .copyWith(fontWeight: FontWeight.bold),
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
                      // هنستخدم نفس الـ Widget للاتنين
                      // لأن الدخول والاشتراك بقوا بنفس الطريقة (OTP)
                      _AuthFormWidget(),
                      _AuthFormWidget(isSignup: true),
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

// --- Widget موحد للدخول والاشتراك ---
class _AuthFormWidget extends StatefulWidget {
  final bool isSignup;
  const _AuthFormWidget({this.isSignup = false});

  @override
  State<_AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<_AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  String _fullPhoneNumber = ""; // لتخزين الرقم كامل
  bool _agreedToTerms = false; // خاص بـ Signup بس
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- دي الـ Functionality الجديدة لإرسال الـ OTP ---
  void _sendOtp() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return; // لو الفحص مرجعش true
    }
    
    // التأكد من إدخال رقم
    if (_fullPhoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseEnterPhone),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.isSignup && !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.mustAgreeToTermsError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // (مش هنعمل حاجة هنا، هنستنى الكود)
          setState(() => _isLoading = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("فشل الإرسال: ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          // --- هنا بنروح لصفحة الـ OTP ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen( // (تأكد إن الملف ده موجود)
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
            // --- استخدمنا intl_phone_field ---
            Directionality( // ضروري عشان الحقل يظهر من الشمال لليمين صح
              textDirection: TextDirection.ltr,
              child: IntlPhoneField(
                decoration: InputDecoration(
                  labelText: localizations.authPhoneLabel,
                  hintText: "10 1234 5678", // مثال
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                initialCountryCode: 'EG', // كود مصر
                onChanged: (phone) {
                  _fullPhoneNumber = phone.completeNumber; // (e.g. +201012345678)
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) {
                     return localizations.pleaseEnterPhone;
                  }
                  // الـ package نفسها بتعمل validation مبدئي
                  return null;
                },
              ),
            ),
            
            // --- حذفنا حقل الباسورد ---

            // هنظهر "الشروط والأحكام" في حالة الـ Signup بس
            if (widget.isSignup)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
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
              ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYello,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      localizations.authSendCode, // (غيرنا النص لإرسال الكود)
                      style: AppTextStyles.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}