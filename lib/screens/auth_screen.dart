import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:truecaller_sdk/truecaller_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:learnaria/screens/create_new_password.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/screens/forgot_password_screen.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/password_text_field.dart';
import 'package:learnaria/widgets/phone_text_field.dart';
import 'package:learnaria/widgets/glass_container.dart';
import 'package:learnaria/widgets/pulse_loader.dart';

import 'package:learnaria/widgets/premium_alert.dart';

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
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        unselectedLabelStyle:
                                            AppTextStyles.bodyText,
                                        indicatorColor: AppColors.primaryYello,
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        labelColor: AppColors.primaryYello,
                                        unselectedLabelColor: isDark
                                            ? Colors.white60
                                            : Colors.black54,
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
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String phoneNumber = _phoneController.text.trim();
      // --- START: FIX for extra zero ---
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
      final String fullPhoneNumber = "+20$phoneNumber";
      // --- END: FIX ---
      try {
        await _authService.signInWithPhoneAndPassword(
          context,
          fullPhoneNumber,
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    localizations.forgotPassword,
                    style: AppTextStyles.linkText.copyWith(
                      color: AppColors.primaryYello,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryYello,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYello,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const PulseLoader(size: 28)
                    : Text(
                        localizations.login,
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
  bool _isLoading = false;

  StreamSubscription<TcSdkCallback>? _truecallerSubscription;
  String? _codeVerifier;
  bool _isTruecallerFlowActive = false;

  String _normalizePhoneNumberForCompare(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^\d]'), '').trim();
    if (clean.startsWith('20')) {
      clean = clean.substring(2);
    }
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return clean;
  }

  Future<void> _checkTruecallerNumberAndProceed({
    required String enteredPhone,
    required String truecallerPhone,
  }) async {
    final normEntered = _normalizePhoneNumberForCompare(enteredPhone);
    final normTc = _normalizePhoneNumberForCompare(truecallerPhone);

    if (normEntered == normTc) {
      await _proceedWithPhone(truecallerPhone);
    } else {
      // Mismatch
      if (mounted) {
        setState(() => _isLoading = false);
        final locale = Localizations.localeOf(context).languageCode;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              locale == 'ar'
                  ? 'تأكيد رقم الهاتف ⚠️'
                  : 'Confirm Phone Number ⚠️',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              locale == 'ar'
                  ? 'الرقم الذي ادخلته ($enteredPhone) يختلف عن رقم Truecaller الموثق ($truecallerPhone).\n\nهل ترغب في الاستمرار برقم Truecaller أم التحقق من رقمك المكتوب عبر رسالة نصية (SMS)؟'
                  : 'The number you entered ($enteredPhone) is different from the verified Truecaller number ($truecallerPhone).\n\nDo you want to proceed with the Truecaller number or verify your entered number via SMS?',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  // Verify entered number via SMS
                  _signUpFirebase();
                },
                child: Text(
                  locale == 'ar' ? 'التحقق عبر SMS' : 'Verify via SMS',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  setState(() => _isLoading = true);
                  // Update text field so user sees it
                  _phoneController.text = truecallerPhone
                      .replaceAll('+20', '0')
                      .replaceAll('+2', '');
                  await _proceedWithPhone(truecallerPhone);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYello,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  locale == 'ar' ? 'رقم Truecaller' : 'Truecaller Number',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _proceedWithPhone(String phone) async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final bool alreadyExists = await _authService.checkParentAccountExists(
      phone,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (alreadyExists) {
        PremiumAlert.show(
          context,
          message: AppLocalizations.of(context)!.phoneAlreadyRegistered,
          isError: true,
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateNewPassword(phoneNumber: phone),
        ),
      );
    }
  }

  Future<void> _showSupportDialog(String enteredPhone) async {
    final locale = Localizations.localeOf(context).languageCode;
    String teacherPhone = "+201283361553"; // Fallback support number
    String teacherName = locale == 'ar' ? 'المعلم' : 'the Teacher';

    try {
      String clean = enteredPhone.replaceAll(RegExp(r'[^\d]'), '').trim();
      if (clean.startsWith('20')) {
        clean = clean.substring(2);
      }
      if (clean.startsWith('0')) {
        clean = clean.substring(1);
      }
      final phoneFormats = ["0$clean", "+20$clean"];

      final studentDocs = await FirebaseFirestore.instance
          .collectionGroup('students')
          .where('parentPhoneNumber', whereIn: phoneFormats)
          .limit(1)
          .get();

      if (studentDocs.docs.isNotEmpty) {
        final pathSegments = studentDocs.docs.first.reference.path.split('/');
        final tId = pathSegments[1];
        if (tId.startsWith('+') ||
            tId.startsWith('0') ||
            RegExp(r'^\d+$').hasMatch(tId)) {
          teacherPhone = tId;
          final tDoc = await FirebaseFirestore.instance
              .collection('teachers')
              .doc(tId)
              .get();
          if (tDoc.exists && tDoc.data()?['name'] != null) {
            teacherName = tDoc.data()?['name'];
          }
        }
      }
    } catch (e) {
      debugPrint("Error looking up teacher phone: $e");
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            locale == 'ar'
                ? 'مشكلة في إرسال الرمز ⚠️'
                : 'Failed to Send Code ⚠️',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            locale == 'ar'
                ? 'تعذر إرسال رمز التحقق (OTP) إلى الرقم $enteredPhone.\n\ هل ترغب في التواصل مع $teacherName عبر الواتساب لتفعيل حسابك مباشرة؟'
                : 'Could not send the verification code (OTP) to $enteredPhone.\n\ Do you want to contact $teacherName via WhatsApp to activate your account directly?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                locale == 'ar' ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final whatsappMsg = locale == 'ar'
                    ? 'مرحباً يا أستاذ، واجهت مشكلة في استلام رمز التحقق (OTP) لتفعيل حساب ولي الأمر الخاص بالرقم $enteredPhone. هل يمكنك تفعيل الحساب لي من لوحة التحكم؟'
                    : 'Hello, I faced an issue receiving the OTP code to activate my parent account for phone number $enteredPhone. Could you please activate my account from the dashboard?';

                final cleanTeacherPhone = teacherPhone
                    .replaceAll(RegExp(r'[^\d]'), '')
                    .trim();
                final uri = Uri.parse(
                  "https://wa.me/$cleanTeacherPhone?text=${Uri.encodeComponent(whatsappMsg)}",
                );

                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      PremiumAlert.show(
                        context,
                        message: locale == 'ar'
                            ? 'تعذر فتح الواتساب. رقم تواصل المعلم: $teacherPhone'
                            : 'Could not launch WhatsApp. Teacher contact: $teacherPhone',
                        isError: true,
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("Error launching WhatsApp: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYello,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                locale == 'ar' ? 'تواصل واتساب' : 'Contact WhatsApp',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _initTruecaller();
    }
  }

  void _checkCachedTruecallerPhone() async {
    try {
      const channel = MethodChannel('com.elnazeredu.elnazer/truecaller');
      final String? cachedPhone = await channel.invokeMethod<String>(
        'getAndClearCachedPhone',
      );
      if (cachedPhone != null && cachedPhone.isNotEmpty) {
        String normalizedPhone = cachedPhone.trim();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateNewPassword(phoneNumber: normalizedPhone),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking cached Truecaller phone: $e");
    }
  }

  void _initTruecaller() async {
    try {
      debugPrint("Truecaller: Registering stream listener first...");
      _truecallerSubscription = TcSdk.streamCallbackData.listen((
        tcSdkCallback,
      ) async {
        debugPrint(
          "Truecaller Callback: Result = ${tcSdkCallback.result}, Error = ${tcSdkCallback.error}",
        );
        if (!_isTruecallerFlowActive) {
          debugPrint("Truecaller Callback ignored: flow not user-initiated.");
          return;
        }
        switch (tcSdkCallback.result) {
          case TcSdkCallbackResult.success:
            debugPrint(
              "Truecaller Callback: SUCCESS! Authorization Code obtained.",
            );
            final oAuthData = tcSdkCallback.tcOAuthData!;
            await _handleTruecallerSuccess(oAuthData);
            break;
          case TcSdkCallbackResult.failure:
            debugPrint(
              "Truecaller Callback: FAILURE! Error: ${tcSdkCallback.error?.message}",
            );
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _signUpFirebase();
            break;
          default:
            debugPrint(
              "Truecaller Callback: Unknown state: ${tcSdkCallback.result}",
            );
            break;
        }
      });

      debugPrint("Truecaller: Initializing SDK (non-blocking)...");
      TcSdk.initializeSDK(sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS)
          .then((_) {
            debugPrint(
              "Truecaller: SDK initialization future resolved successfully.",
            );
          })
          .catchError((e) {
            debugPrint(
              "Truecaller: SDK initialization future returned error: $e",
            );
          });
    } catch (e) {
      debugPrint("Truecaller: Initialization failed with exception: $e");
    }
  }

  Future<void> _handleTruecallerSuccess(TcOAuthData oAuthData) async {
    try {
      debugPrint(
        "Truecaller Token Exchange: Exchanging code ${oAuthData.authorizationCode} with verifier ${_codeVerifier}",
      );
      final tokenUrl = Uri.parse(
        'https://oauth-account-noneu.truecaller.com/v1/token',
      );
      final response = await http.post(
        tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': '5aljimgbfi-dlojnmxmlyeypfk3da21mc2irnqejpvc',
          'code': oAuthData.authorizationCode,
          'code_verifier': _codeVerifier ?? '',
        },
      );

      debugPrint(
        "Truecaller Token Response: Status = ${response.statusCode}, Body = ${response.body}",
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        final accessToken = tokenData['access_token'];

        // Get user info
        debugPrint(
          "Truecaller UserInfo: Fetching user info with token $accessToken",
        );
        final userInfoUrl = Uri.parse(
          'https://oauth-account-noneu.truecaller.com/v1/userinfo',
        );
        final userInfoResponse = await http.get(
          userInfoUrl,
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        debugPrint(
          "Truecaller UserInfo Response: Status = ${userInfoResponse.statusCode}, Body = ${userInfoResponse.body}",
        );

        if (userInfoResponse.statusCode == 200) {
          final userInfo = jsonDecode(userInfoResponse.body);
          final String? rawPhone = userInfo['phone_number'];

          if (rawPhone != null && rawPhone.isNotEmpty) {
            String normalizedPhone = rawPhone.trim();
            if (!normalizedPhone.startsWith('+')) {
              normalizedPhone = '+$normalizedPhone';
            }
            debugPrint(
              "Truecaller Flow Success! Phone: $normalizedPhone. Navigating to CreateNewPassword...",
            );
            if (mounted) {
              await _checkTruecallerNumberAndProceed(
                enteredPhone: _phoneController.text.trim(),
                truecallerPhone: normalizedPhone,
              );
            }
          } else {
            throw Exception(
              "Phone number missing in Truecaller profile payload",
            );
          }
        } else {
          throw Exception(
            "Failed to fetch Truecaller user info: Status ${userInfoResponse.statusCode}",
          );
        }
      } else {
        throw Exception(
          "Failed to exchange Truecaller authorization code: Status ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Truecaller auth exception: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _signUpFirebase();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _truecallerSubscription?.cancel();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        PremiumAlert.show(
          context,
          message: AppLocalizations.of(context)!.mustAgreeToTermsError,
          isError: true,
        );
        return;
      }
      setState(() => _isLoading = true);

      String phoneNumber = _phoneController.text.trim();
      final bool alreadyExists = await _authService.checkParentAccountExists(
        phoneNumber,
      );
      if (alreadyExists) {
        if (mounted) {
          setState(() => _isLoading = false);
          PremiumAlert.show(
            context,
            message: AppLocalizations.of(context)!.phoneAlreadyRegistered,
            isError: true,
          );
        }
        return;
      }

      if (Platform.isAndroid) {
        try {
          debugPrint("Truecaller: Checking Android OAuth Flow usability...");
          final bool isUsable = await TcSdk.isOAuthFlowUsable;
          debugPrint("Truecaller: isOAuthFlowUsable = $isUsable");
          if (isUsable) {
            _codeVerifier = await TcSdk.generateRandomCodeVerifier;
            debugPrint("Truecaller: Code Verifier generated: $_codeVerifier");
            final String? codeChallenge = await TcSdk.generateCodeChallenge(
              _codeVerifier!,
            );
            debugPrint("Truecaller: Code Challenge generated: $codeChallenge");
            if (codeChallenge != null) {
              TcSdk.setCodeChallenge(codeChallenge);
              TcSdk.setOAuthScopes(['phone', 'openid']);
              TcSdk.setOAuthState("learnaria_auth_state");
              debugPrint("Truecaller: Requesting authorization code...");
              _isTruecallerFlowActive = true;
              TcSdk.getAuthorizationCode;
              debugPrint("Truecaller: getAuthorizationCode invoked.");
              return; // Wait for callback stream response
            }
          } else {
            debugPrint(
              "Truecaller: Flow is NOT usable on this Android device (not installed or logged in).",
            );
          }
        } catch (e) {
          debugPrint("Truecaller Android usage check failed: $e");
        }
      } else if (Platform.isIOS) {
        try {
          const channel = MethodChannel('com.elnazeredu.elnazer/truecaller');
          final bool isUsable =
              await channel.invokeMethod<bool>('isUsable') ?? false;
          if (isUsable) {
            final result = await channel.invokeMethod('verifyUser');
            if (result is Map) {
              if (result['status'] == 'success') {
                final String? rawPhone = result['phoneNumber'];
                if (rawPhone != null && rawPhone.isNotEmpty) {
                  String normalizedPhone = rawPhone.trim();
                  if (mounted) {
                    await _checkTruecallerNumberAndProceed(
                      enteredPhone: _phoneController.text.trim(),
                      truecallerPhone: normalizedPhone,
                    );
                    return; // Bypassed Firebase OTP successfully
                  }
                }
              } else {
                debugPrint(
                  "Truecaller iOS returned non-success status: ${result['status']}",
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Truecaller iOS usage check/verification failed: $e");
        }
      }

      // Fallback
      _signUpFirebase();
    }
  }

  void _signUpFirebase() async {
    setState(() => _isLoading = true);
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }
    final String fullPhoneNumber = "+20$phoneNumber";
    try {
      await _authService.sendOtpForSignup(
        context,
        fullPhoneNumber,
        onCodeSent: () {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
        onFailed: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showSupportDialog(fullPhoneNumber);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSupportDialog(fullPhoneNumber);
      }
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
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYello,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const PulseLoader(size: 28)
                    : Text(
                        localizations.signup,
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
