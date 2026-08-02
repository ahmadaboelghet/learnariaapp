import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:truecaller_sdk/truecaller_sdk.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/glass_container.dart';
import 'package:learnaria/widgets/phone_text_field.dart';
import 'package:learnaria/widgets/pulse_loader.dart';
import 'package:learnaria/widgets/premium_alert.dart';
import 'package:learnaria/screens/reset_password_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  StreamSubscription<TcSdkCallback>? _truecallerSubscription;
  String? _codeVerifier;
  bool _isTruecallerFlowActive = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _initTruecaller();
    }
  }

  void _initTruecaller() async {
    try {
      debugPrint("Truecaller ForgotPassword: Registering stream listener first...");
      _truecallerSubscription = TcSdk.streamCallbackData.listen((tcSdkCallback) async {
        debugPrint("Truecaller ForgotPassword Callback: Result = ${tcSdkCallback.result}, Error = ${tcSdkCallback.error}");
        if (!_isTruecallerFlowActive) {
          debugPrint("Truecaller ForgotPassword Callback ignored: flow not user-initiated.");
          return;
        }
        switch (tcSdkCallback.result) {
          case TcSdkCallbackResult.success:
            debugPrint("Truecaller ForgotPassword Callback: SUCCESS! Authorization Code obtained.");
            final oAuthData = tcSdkCallback.tcOAuthData!;
            await _handleTruecallerSuccess(oAuthData);
            break;
          case TcSdkCallbackResult.failure:
            debugPrint("Truecaller ForgotPassword Callback: FAILURE! Error: ${tcSdkCallback.error?.message}");
            if (mounted) {
              setState(() => _isLoading = false);
            }
            break;
          default:
            debugPrint("Truecaller ForgotPassword Callback: Unknown state: ${tcSdkCallback.result}");
            break;
        }
      });

      debugPrint("Truecaller ForgotPassword: Initializing SDK (non-blocking)...");
      TcSdk.initializeSDK(sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS).then((_) {
        debugPrint("Truecaller ForgotPassword: SDK initialization future resolved successfully.");
      }).catchError((e) {
        debugPrint("Truecaller ForgotPassword: SDK initialization future returned error: $e");
      });
    } catch (e) {
      debugPrint("Truecaller init failed in forgot password: $e");
    }
  }

  Future<void> _handleTruecallerSuccess(TcOAuthData oAuthData) async {
    try {
      setState(() => _isLoading = true);
      final tokenUrl = Uri.parse('https://oauth-account-noneu.truecaller.com/v1/token');
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

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        final accessToken = tokenData['access_token'];

        final userInfoUrl = Uri.parse('https://oauth-account-noneu.truecaller.com/v1/userinfo');
        final userInfoResponse = await http.get(
          userInfoUrl,
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (userInfoResponse.statusCode == 200) {
          final userInfo = jsonDecode(userInfoResponse.body);
          final String? rawPhone = userInfo['phone_number'];
          if (rawPhone != null && rawPhone.isNotEmpty) {
            await _checkTruecallerNumberAndProceed(
              enteredPhone: _phoneController.text.trim(),
              truecallerPhone: rawPhone.trim(),
            );
            return;
          }
        }
      }
      throw Exception("Failed to retrieve phone number from Truecaller");
    } catch (e) {
      debugPrint("Truecaller exchange exception: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        PremiumAlert.show(
          context,
          message: Localizations.localeOf(context).languageCode == 'ar'
              ? 'فشل التحقق عبر Truecaller. يرجى استخدام التحقق العادي.'
              : 'Truecaller verification failed. Please use normal verification.',
          isError: true,
        );
      }
    }
  }

  void _checkCachedTruecallerPhone() async {
    try {
      const channel = MethodChannel('com.elnazeredu.elnazer/truecaller');
      final String? cachedPhone = await channel.invokeMethod<String>('getAndClearCachedPhone');
      if (cachedPhone != null && cachedPhone.isNotEmpty) {
        await _checkTruecallerNumberAndProceed(
          enteredPhone: _phoneController.text.trim(),
          truecallerPhone: cachedPhone.trim(),
        );
      }
    } catch (e) {
      debugPrint("Error checking cached Truecaller phone in forgot password: $e");
    }
  }

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
      _navigateToResetScreen(truecallerPhone);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        final locale = Localizations.localeOf(context).languageCode;

        String formattedTcPhone = truecallerPhone;
        if (formattedTcPhone.startsWith('+20')) {
          formattedTcPhone = '0' + formattedTcPhone.substring(3);
        } else if (formattedTcPhone.startsWith('+2')) {
          formattedTcPhone = '0' + formattedTcPhone.substring(2);
        } else if (formattedTcPhone.startsWith('20')) {
          formattedTcPhone = '0' + formattedTcPhone.substring(2);
        }

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
                  ? 'الرقم الذي ادخلته ($enteredPhone) يختلف عن رقم Truecaller الموثق ($formattedTcPhone).\n\nهل ترغب في الاستمرار برقم Truecaller أم التحقق من رقمك المكتوب عبر رسالة نصية (SMS)؟'
                  : 'The number you entered ($enteredPhone) is different from the verified Truecaller number ($formattedTcPhone).\n\nDo you want to proceed with the Truecaller number or verify your entered number via SMS?',
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
                  _sendOtpFirebase();
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
                  
                  final bool tcExists = await _authService.checkParentAccountExists(truecallerPhone);
                  if (mounted) {
                    if (tcExists) {
                      _phoneController.text = truecallerPhone
                          .replaceAll('+20', '0')
                          .replaceAll('+2', '');
                      _navigateToResetScreen(truecallerPhone);
                    } else {
                      setState(() => _isLoading = false);
                      PremiumAlert.show(
                        context,
                        message: locale == 'ar'
                            ? 'رقم Truecaller هذا ($truecallerPhone) غير مسجل لدينا. يرجى إنشاء حساب أولاً.'
                            : 'This Truecaller number ($truecallerPhone) is not registered. Please create an account.',
                        isError: true,
                      );
                    }
                  }
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

  void _sendOtpFirebase() async {
    setState(() => _isLoading = true);
    String phoneNumber = _phoneController.text.trim();
    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }
    final String fullPhoneNumber = '+20$phoneNumber';

    try {
      await _authService.sendOtpForPasswordReset(
        context,
        fullPhoneNumber,
        onCodeSent: () {
          if (mounted) setState(() => _isLoading = false);
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

  Future<void> _showSupportDialog(String enteredPhone) async {
    final locale = Localizations.localeOf(context).languageCode;
    String teacherPhone = "+201283361553"; // Fallback support number
    String teacherName = locale == 'ar' ? 'المعلم' : 'the Teacher';

    try {
      final contactInfo = await _authService.getTeacherContact(enteredPhone);
      if (contactInfo != null) {
        teacherPhone = contactInfo['teacherPhone'] ?? teacherPhone;
        teacherName = contactInfo['teacherName'] ?? teacherName;
      }
    } catch (e) {
      debugPrint("Error looking up teacher phone via Cloud Function: $e");
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1E1E1E) 
              : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            locale == 'ar' ? 'مشكلة في إرسال الرمز ⚠️' : 'Failed to Send Code ⚠️',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            locale == 'ar'
                ? 'تعذر إرسال رمز التحقق (OTP) إلى الرقم $enteredPhone.\n\nبعض شبكات المحمول تحظر رسائل Firebase التلقائية. هل ترغب في التواصل مع $teacherName عبر الواتساب لتفعيل حسابك مباشرة؟'
                : 'Could not send the verification code (OTP) to $enteredPhone.\n\nSome mobile networks block Firebase SMS. Do you want to contact $teacherName via WhatsApp to activate your account directly?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
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
                
                String formattedParentPhone = enteredPhone;
                if (formattedParentPhone.startsWith('+20')) {
                  formattedParentPhone = '0' + formattedParentPhone.substring(3);
                } else if (formattedParentPhone.startsWith('+2')) {
                  formattedParentPhone = '0' + formattedParentPhone.substring(2);
                } else if (formattedParentPhone.startsWith('20')) {
                  formattedParentPhone = '0' + formattedParentPhone.substring(2);
                }

                final whatsappMsg = locale == 'ar'
                    ? 'مرحباً يا مستر $teacherName، واجهت مشكلة في استلام رمز التحقق (OTP) لتفعيل حساب ولي الأمر الخاص بالرقم $formattedParentPhone. هل يمكنك تفعيل الحساب لي من لوحة التحكم؟'
                    : 'Hello Mr. $teacherName, I faced an issue receiving the OTP code to activate my parent account for phone number $formattedParentPhone. Could you please activate my account from the dashboard?';
                
                String cleanTeacherPhone = teacherPhone.replaceAll(RegExp(r'[^\d]'), '').trim();
                if (cleanTeacherPhone.startsWith('0')) {
                  cleanTeacherPhone = '20' + cleanTeacherPhone.substring(1);
                } else if (!cleanTeacherPhone.startsWith('20') && cleanTeacherPhone.isNotEmpty) {
                  cleanTeacherPhone = '20' + cleanTeacherPhone;
                }
                final uri = Uri.parse("https://wa.me/$cleanTeacherPhone?text=${Uri.encodeComponent(whatsappMsg)}");
                
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                locale == 'ar' ? 'تواصل واتساب' : 'Contact WhatsApp',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToResetScreen(String phoneNumber) {
    if (mounted) {
      setState(() => _isLoading = false);
      String normalizedPhone = phoneNumber.trim();
      if (!normalizedPhone.startsWith('+')) {
        normalizedPhone = '+$normalizedPhone';
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            phoneNumber: normalizedPhone,
            verificationId: 'truecaller',
            smsCode: 'truecaller',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _truecallerSubscription?.cancel();
    super.dispose();
  }

  void _sendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String phoneNumber = _phoneController.text.trim();
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
      final String fullPhoneNumber = '+20$phoneNumber';

      // 1. التحقق من وجود الحساب أولاً
      final bool alreadyExists = await _authService.checkParentAccountExists(fullPhoneNumber);
      if (!alreadyExists) {
        if (mounted) {
          setState(() => _isLoading = false);
          PremiumAlert.show(
            context,
            message: Localizations.localeOf(context).languageCode == 'ar'
                ? 'رقم الهاتف هذا غير مسجل لدينا. من فضلك قم بإنشاء حساب.'
                : 'This phone number is not registered. Please create an account.',
            isError: true,
          );
        }
        return;
      }

      // 2. التحقق من التروكولر
      if (Platform.isAndroid) {
        try {
          final bool isUsable = await TcSdk.isOAuthFlowUsable;
          if (isUsable) {
            _codeVerifier = await TcSdk.generateRandomCodeVerifier;
            final String? codeChallenge = await TcSdk.generateCodeChallenge(_codeVerifier!);
            if (codeChallenge != null) {
              TcSdk.setCodeChallenge(codeChallenge);
              TcSdk.setOAuthScopes(['phone', 'openid']);
              TcSdk.setOAuthState("learnaria_auth_state");
              _isTruecallerFlowActive = true;
              TcSdk.getAuthorizationCode;
              return;
            }
          }
        } catch (e) {
          debugPrint("Truecaller usable check failed: $e");
        }
      } else if (Platform.isIOS) {
        try {
          const channel = MethodChannel('com.elnazeredu.elnazer/truecaller');
          final bool isUsable = await channel.invokeMethod<bool>('isUsable') ?? false;
          if (isUsable) {
            final result = await channel.invokeMethod('verifyUser');
            if (result is Map && result['status'] == 'success') {
              final String? rawPhone = result['phoneNumber'];
              if (rawPhone != null && rawPhone.isNotEmpty) {
                String normalizedPhone = rawPhone.trim();
                if (mounted) {
                  await _checkTruecallerNumberAndProceed(
                    enteredPhone: _phoneController.text.trim(),
                    truecallerPhone: normalizedPhone,
                  );
                  return;
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Truecaller iOS verify failed: $e");
        }
      }

      // 3. التحقق عبر الـ SMS في حال تعذر التروكولر
      _sendOtpFirebase();
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
          localizations.forgotPasswordTitle,
          style: AppTextStyles.heading2.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
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
                        // Top Icon
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
                              Icons.lock_reset_outlined,
                              size: 40,
                              color: AppColors.primaryYello,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          localizations.forgotPasswordTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          localizations.forgotPasswordSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.secondaryText.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),
                        PhoneTextField(
                          controller: _phoneController,
                          hintText: '01x xxx xxxx',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.pleaseEnterPhone;
                            }
                            final regex = RegExp(r'^01[0125][0-9]{8}$');
                            if (!regex.hasMatch(value)) {
                              return Localizations.localeOf(context).languageCode == 'ar'
                                  ? 'ادخل رقم هاتف مصري صحيح'
                                  : 'Enter a valid Egyptian phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sendCode,
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
                                  localizations.sendCode,
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
