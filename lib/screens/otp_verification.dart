import 'package:flutter/material.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/services/auth_service.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/glass_container.dart';
import 'package:learnaria/widgets/pulse_loader.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:learnaria/widgets/premium_alert.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _verifyOtp() async {
    if (_otpController.text.length == 6) {
      setState(() => _isLoading = true);
      try {
        await _authService.verifyOtpAndNavigate(
          context,
          widget.verificationId,
          _otpController.text,
          widget.phoneNumber,
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
          style: AppTextStyles.heading2.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // <-- Aligns the header title to the side
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: GlassContainer(
                borderRadius: 24,
                fillOpacity: isDark ? 0.08 : 0.45,
                borderOpacity: 0.12,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), // Reduced horizontal padding to prevent overflow
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
                      localizations.enterOtpSentTo(widget.phoneNumber),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We have sent a verification code to your phone number. Enter it below to proceed.',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Premium OTP Digit Boxes Input
class _PremiumOtpInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;

  const _PremiumOtpInput({
    required this.controller,
    this.onCompleted, required this.length,
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
                if (value.length == widget.length && widget.onCompleted != null) {
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
                      ? (isFocused ? const Color(0xFF1E2028) : const Color(0xFF16171D))
                      : (isFocused ? Colors.white : const Color(0xFFF0F2F5)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primaryYello
                        : (isDark ? const Color(0xFF262930) : const Color(0xFFE5E8EB)),
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
