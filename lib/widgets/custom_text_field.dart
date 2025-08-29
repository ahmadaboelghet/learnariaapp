import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnaria/utils/app_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefix; // The widget to show before the input text
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefix,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        // Building the decoration directly here to ensure correct behavior
        hintText: hintText,
        hintStyle: AppTextStyles.secondaryText,
        filled: true,
        fillColor: AppColors.lightGrey,
        prefix: prefix, // Using prefix to ensure it's always visible
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: AppColors.primaryYello, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        counterText: "", // Hide the default counter text for maxLength
      ),
    );
  }
}
