import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/glass_container.dart';
import 'package:learnaria/widgets/pulse_loader.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:learnaria/widgets/premium_alert.dart';
import 'package:url_launcher/url_launcher.dart';

enum OtpMode { signup, resetPassword }

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final OtpMode mode;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.mode = OtpMode.signup,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  late String _currentVerificationId;
  Timer? _timer;
  int _secondsRemaining = 30; // 30 seconds
  bool _timerExpired = false;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 30;
    _timerExpired = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timerExpired = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _resendCode() async {
    setState(() => _isLoading = true);
    await _authService.resendOtp(
      widget.phoneNumber,
      onCodeSent: (newVerificationId) {
        if (mounted) {
          setState(() {
            _currentVerificationId = newVerificationId;
            _isLoading = false;
          });
          _startTimer();
          PremiumAlert.show(
            context,
            message: Localizations.localeOf(context).languageCode == 'ar'
                ? 'تم إعادة إرسال رمز التحقق بنجاح!'
                : 'Verification code resent successfully!',
            isError: false,
          );
        }
      },
      onFailed: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          PremiumAlert.show(
            context,
            message: Localizations.localeOf(context).languageCode == 'ar'
                ? 'فشل إعادة إرسال الرمز. يرجى المحاولة مرة أخرى لاحقاً.'
                : 'Failed to resend code. Please try again later.',
            isError: true,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    if (_otpController.text.length == 6) {
      setState(() => _isLoading = true);
      try {
        await _authService.verifyOtpAndNavigate(
          context,
          _currentVerificationId,
          _otpController.text,
          widget.phoneNumber,
          mode: widget.mode,
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      PremiumAlert.show(
        context,
        message: Localizations.localeOf(context).languageCode == 'ar'
            ? 'يرجى إدخال رمز التحقق المكون من 6 أرقام.'
            : 'Please enter a valid 6-digit code.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    String formattedDisplayPhone = widget.phoneNumber;
    if (formattedDisplayPhone.startsWith('+20')) {
      formattedDisplayPhone = '0' + formattedDisplayPhone.substring(3);
    } else if (formattedDisplayPhone.startsWith('+2')) {
      formattedDisplayPhone = '0' + formattedDisplayPhone.substring(2);
    } else if (formattedDisplayPhone.startsWith('20')) {
      formattedDisplayPhone = '0' + formattedDisplayPhone.substring(2);
    }

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
          localizations.otpVerification,
          style: AppTextStyles.heading2.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // <-- Aligns the header title to the side
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: GlassContainer(
                borderRadius: 24,
                fillOpacity: isDark ? 0.08 : 0.45,
                borderOpacity: 0.12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ), // Reduced horizontal padding to prevent overflow
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
                          Icons.vpn_key_outlined,
                          size: 40,
                          color: AppColors.primaryYello,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title/Instruction
                    Text(
                      localizations.enterOtpSentTo(formattedDisplayPhone),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.mode == OtpMode.resetPassword
                          ? (Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'أدخل رمز التحقق المرسل إلى رقم هاتفك لإعادة تعيين كلمة المرور.'
                                : 'Enter the verification code sent to your phone to reset your password.')
                          : (Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'لقد أرسلنا رمز التحقق إلى رقم هاتفك. أدخله أدناه للمتابعة.'
                                : 'We have sent a verification code to your phone number. Enter it below to proceed.'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondaryText.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Premium Custom OTP Input Field
                    _PremiumOtpInput(
                      controller: _otpController,
                      onCompleted: (value) {
                        _verifyOtp();
                      },
                      length: 6,
                    ),
                    const SizedBox(height: 32),
                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
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
                              localizations.verify,
                              style: AppTextStyles.buttonText.copyWith(
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    // Resend OTP Button (Always visible, disabled during countdown)
                    TextButton(
                      onPressed: _secondsRemaining > 0 || _isLoading
                          ? null
                          : () {
                              _otpController.clear();
                              _resendCode();
                            },
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'إعادة إرسال الرمز${_secondsRemaining > 0 ? " ($_secondsRemaining)" : ""}'
                            : 'Resend Code${_secondsRemaining > 0 ? " ($_secondsRemaining)" : ""}',
                        style: TextStyle(
                          color: _secondsRemaining > 0
                              ? Colors.grey
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Support button (Visible only when timer runs out/expired)
                    if (_timerExpired) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => _contactTeacherSupport(
                                context,
                                widget.phoneNumber,
                              ),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'لم يصلك الرمز؟ تواصل مع المدرس للتفعيل 💬'
                              : 'Did not receive code? Contact teacher for activation 💬',
                          style: const TextStyle(
                            color: AppColors.primaryYello,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _contactTeacherSupport(
    BuildContext context,
    String parentPhone,
  ) async {
    final locale = Localizations.localeOf(context).languageCode;
    String teacherPhone = "+201009856266"; // Default support number
    String teacherName = ''; // Default support name
    String groupName = locale == 'ar' ? 'المجموعةالعامة' : 'General Group'; // Default group name  

    setState(() => _isLoading = true);

    try {
      debugPrint("OTP Verification Support Lookup: parentPhone = $parentPhone");
      final contactInfo = await _authService.getTeacherContact(parentPhone);
      debugPrint("OTP Verification Support Lookup Result: $contactInfo");
      if (contactInfo != null) {
        teacherPhone = contactInfo['teacherPhone'] ?? teacherPhone;
        teacherName = contactInfo['teacherName'] ?? teacherName;
        groupName = contactInfo['groupName'] ?? groupName;
      }
    } catch (e) {
      debugPrint("Error looking up teacher phone via Cloud Function: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    String formattedParentPhone = parentPhone;
    if (formattedParentPhone.startsWith('+20')) {
      formattedParentPhone = '0' + formattedParentPhone.substring(3);
    } else if (formattedParentPhone.startsWith('+2')) {
      formattedParentPhone = '0' + formattedParentPhone.substring(2);
    } else if (formattedParentPhone.startsWith('20')) {
      formattedParentPhone = '0' + formattedParentPhone.substring(2);
    }

    final message = locale == 'ar'
        ? 'مرحباً يا مستر $teacherName، واجهت مشكلة في استلام رمز التحقق (OTP) لتفعيل حساب ولي الأمر الخاص بالرقم $formattedParentPhone ومجموعته هي ($groupName). هل يمكنك تفعيل الحساب لي من لوحة التحكم؟'
        : 'Hello Mr. $teacherName, I faced an issue receiving the OTP code to activate my parent account for phone number $formattedParentPhone in group ($groupName). Could you please activate my account from the dashboard?';

    String cleanTeacherPhone = teacherPhone
        .replaceAll(RegExp(r'[^\d]'), '')
        .trim();
    if (cleanTeacherPhone.startsWith('0')) {
      cleanTeacherPhone = '20' + cleanTeacherPhone.substring(1);
    } else if (!cleanTeacherPhone.startsWith('20') &&
        cleanTeacherPhone.isNotEmpty) {
      cleanTeacherPhone = '20' + cleanTeacherPhone;
    }
    final url = Uri.parse(
      "https://wa.me/$cleanTeacherPhone?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          PremiumAlert.show(
            context,
            message: locale == 'ar'
                ? 'تعذر فتح الواتساب. رقم تواصل المعلم: $teacherPhone'
                : 'Could not open WhatsApp. Support number: $teacherPhone',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching WhatsApp: $e");
    }
  }
}

// Custom Premium OTP Digit Boxes Input
class _PremiumOtpInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;

  const _PremiumOtpInput({
    required this.controller,
    this.onCompleted,
    required this.length,
  });

  @override
  State<_PremiumOtpInput> createState() => _PremiumOtpInputState();
}

class _PremiumOtpInputState extends State<_PremiumOtpInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final code = widget.controller.text;

    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden input field
          SizedBox(
            width: 0,
            height: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofillHints: const [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length == widget.length &&
                    widget.onCompleted != null) {
                  widget.onCompleted!(value);
                }
              },
            ),
          ),
          // Elegant UI Row of individual boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.length, (index) {
              final isFocused = _focusNode.hasFocus && index == code.length;
              final hasValue = index < code.length;
              final value = hasValue ? code[index] : '';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38, // Adjusted width to prevent overflow
                height: 48, // Adjusted height to match the ratio
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? (isFocused
                            ? const Color(0xFF1E2028)
                            : const Color(0xFF16171D))
                      : (isFocused ? Colors.white : const Color(0xFFF0F2F5)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primaryYello
                        : (isDark
                              ? const Color(0xFF262930)
                              : const Color(0xFFE5E8EB)),
                    width: isFocused ? 2.0 : 1.2,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primaryYello.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isFocused ? AppColors.primaryYello : textColor,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
