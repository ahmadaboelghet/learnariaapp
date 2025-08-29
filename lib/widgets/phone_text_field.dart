import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnaria/utils/app_styles.dart';

class PhoneTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;

  const PhoneTextField({
    super.key,
    required this.controller,
    this.validator,
    required this.hintText,
  });

  @override
  State<PhoneTextField> createState() => _PhoneTextFieldState();
}

class _PhoneTextFieldState extends State<PhoneTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: state.hasError
                      ? Colors.red.shade700
                      : _isFocused
                          ? AppColors.primaryYello
                          : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // This prefix is now part of the row and will always be visible
                  const _CountryCodePicker(),
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: AppTextStyles.secondaryText,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                        counterText: '',
                      ),
                      onChanged: (value) {
                        state.didChange(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 5.0),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

// --- Country Code Picker Widget ---
class _CountryCodePicker extends StatelessWidget {
  const _CountryCodePicker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🇪🇬", style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text("+20", style: AppTextStyles.bodyText),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: AppColors.mediumGrey,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
