import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;

  const PasswordTextField({super.key, required this.hintText, this.controller});

  @override
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    // يستخدم الثيم العام المعرف في main.dart / app_styles.dart
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        // الخصائص التالية تأتي تلقائياً من Theme:
        // filled, fillColor, border, enabledBorder, focusedBorder
      ),
    );
  }
}
