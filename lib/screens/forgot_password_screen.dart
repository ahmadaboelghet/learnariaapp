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

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _initTruecaller();
    } else if (Platform.isIOS) {
      _checkCachedTruecallerPhone();
    }
  }

  void _initTruecaller() async {
    try {
      await TcSdk.initializeSDK(sdkOption: TcSdkOptions.OPTION_VERIFY_ONLY_TC_USERS);
      _truecallerSubscription = TcSdk.streamCallbackData.listen((tcSdkCallback) async {
        switch (tcSdkCallback.result) {
          case TcSdkCallbackResult.success:
            final oAuthData = tcSdkCallback.tcOAuthData!;
            await _handleTruecallerSuccess(oAuthData);
            break;
          case TcSdkCallbackResult.failure:
            debugPrint("Truecaller forgot password failed, fallback to standard OTP");
            break;
          default:
            break;
        }
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
            _navigateToResetScreen(rawPhone.trim());
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
        _navigateToResetScreen(cachedPhone.trim());
      }
    } catch (e) {
      debugPrint("Error checking cached Truecaller phone in forgot password: $e");
    }
  }

  void _navigateToResetScreen(String phoneNumber) {
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            phoneNumber: phoneNumber,
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

      if (Platform.isAndroid) {
        try {
          final bool isUsable = await TcSdk.isOAuthFlowUsable;
          if (isUsable) {
            _codeVerifier = await TcSdk.generateRandomCodeVerifier;
            final String? codeChallenge = await TcSdk.generateCodeChallenge(_codeVerifier!);
            if (codeChallenge != null) {
              await TcSdk.setCodeChallenge(codeChallenge);
              await TcSdk.setOAuthScopes(['profile', 'phone', 'openid']);
              await TcSdk.setOAuthState("learnaria_auth_state");
              await TcSdk.getAuthorizationCode;
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
                _navigateToResetScreen(rawPhone.trim());
                return;
              }
            }
          }
        } catch (e) {
          debugPrint("Truecaller iOS verify failed: $e");
        }
      }

      await _authService.sendOtpForPasswordReset(
        context,
        fullPhoneNumber,
        onCodeSent: () {
          if (mounted) setState(() => _isLoading = false);
        },
        onFailed: (error) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
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
