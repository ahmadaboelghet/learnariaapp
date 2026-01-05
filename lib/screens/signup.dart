// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:learnaria/screens/auth_screen.dart';
// import 'package:learnaria/utils/app_styles.dart';
// import 'package:learnaria/widgets/custom_text_field.dart';
// import 'package:learnaria/widgets/password_text_field.dart';
// import 'package:learnaria/screens/main_layout.dart';
// import 'package:learnaria/l10n/app_localizations.dart';

// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});

//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends State<SignUpScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isLoading = false;
//   String? _errorMessage;
//   bool _agreeToTerms = false;

//   Future<void> _signUp() async {
//     final appLocalizations = AppLocalizations.of(context)!;
//     if (!_agreeToTerms) {
//       setState(() {
//         _errorMessage = appLocalizations.mustAgreeToTermsError; // <-- نص مترجم
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       // -- Start: التعديل هنا --
//       // إضافة +2 إلى بداية رقم الهاتف
//       final String formattedPhoneNumber = "+2${_phoneController.text.trim()}";
//       final String emailFormattedPhoneNumber = "$formattedPhoneNumber@learnaria.app";
//       // -- End: التعديل هنا --

//       await _auth.createUserWithEmailAndPassword(
//         email: emailFormattedPhoneNumber,
//         password: _passwordController.text.trim(),
//       );

//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => const MainLayoutScreen()), // Corrected
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.message ?? 'An error occurred during sign up.';
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context)!;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: 50),
//               Text(appLocalizations.signupCreateAccount, style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello)), // <-- نص مترجم
//               SizedBox(height: 8),
//               Text(appLocalizations.signupStartJourney, style: AppTextStyles.secondaryText), // <-- نص مترجم
//               SizedBox(height: 30),
//               CustomTextField(
//                 controller: _phoneController,
//                 hintText: appLocalizations.phoneNumber, // <-- نص مترجم
//                 prefixIcon: Icons.phone_outlined,
//                 keyboardType: TextInputType.phone,
//               ),
//               SizedBox(height: 20),
//               PasswordTextField(
//                 controller: _passwordController,
//                 hintText: appLocalizations.password, // <-- نص مترجم
//               ),
//               SizedBox(height: 15),
//               Row(
//                 children: [
//                   Checkbox(
//                     value: _agreeToTerms,
//                     onChanged: (bool? newValue) {
//                       setState(() {
//                         _agreeToTerms = newValue ?? false;
//                       });
//                     },
//                     activeColor: AppColors.primaryYello,
//                   ),
//                   Expanded(
//                     child: Text(
//                       appLocalizations.agreeToTerms, // <-- نص مترجم
//                       style: AppTextStyles.secondaryText,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 15),
//                if (_errorMessage != null)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 15.0),
//                     child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
//                   ),
//               SizedBox(
//                 width: double.infinity,
//                 child: _isLoading
//                     ? Center(child: CircularProgressIndicator())
//                     : ElevatedButton(
//                         onPressed: _agreeToTerms ? _signUp : null,
//                         style: primaryButtonStyle(),
//                         child: Text(appLocalizations.signup, style: AppTextStyles.buttonText), // <-- نص مترجم
//                       ),
//               ),
//                SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text("${appLocalizations.alreadyHaveAccount} ", style: AppTextStyles.secondaryText), // <-- نص مترجم
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.of(context).push(MaterialPageRoute(builder: (context) => AuthScreen()));
//                       },
//                       child: Text(appLocalizations.login, style: AppTextStyles.linkText), // <-- نص مترجم
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }