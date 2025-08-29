// import 'package:flutter/material.dart';
// import 'package:learnaria/l10n/app_localizations.dart';
// import 'package:learnaria/screens/login.dart';
// import 'package:learnaria/utils/app_styles.dart';
// import 'package:learnaria/widgets/custom_text_field.dart';
// import 'package:learnaria/screens/otp_verification.dart';

// class SignUp extends StatefulWidget {
//   const SignUp({super.key});

//   @override
//   State<SignUp> createState() => _SignUpState();
// }

// class _SignUpState extends State<SignUp> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   bool _agreedToTerms = false;

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   void _signUp() {
//     final localizations = AppLocalizations.of(context)!;
//     if (_formKey.currentState!.validate()) {
//       if (!_agreedToTerms) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(localizations.agreeToTerms),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//       // TODO: Call your cloud function to send OTP here
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => OtpVerificationScreen(phoneNumber: _phoneController.text),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context)!;
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Image.asset('assets/images/logo.png', height: 120),
//                   const SizedBox(height: 20),
//                   Text(
//                     localizations.signupCreateAccount,
//                     textAlign: TextAlign.center,
//                     style: AppTextStyles.heading1,
//                   ),
//                   const SizedBox(height: 30),
//                   CustomTextField(
//                     controller: _phoneController,
//                     labelText: localizations.phoneNumber,
//                     hintText: localizations.phoneNumber, // Corrected
//                     keyboardType: TextInputType.phone,
//                     prefixIcon: Icons.phone_outlined,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return localizations.pleaseEnterPhone;
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: _agreedToTerms,
//                         onChanged: (value) {
//                           setState(() {
//                             _agreedToTerms = value!;
//                           });
//                         },
//                         activeColor: AppColors.primaryYello,
//                       ),
//                       Expanded(
//                         child: Text(
//                           localizations.agreeToTerms,
//                           style: AppTextStyles.bodyText,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   ElevatedButton(
//                     onPressed: _signUp,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryYello,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       localizations.signup,
//                       style: AppTextStyles.buttonText,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         localizations.alreadyHaveAccount,
//                         style: AppTextStyles.bodyText,
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(builder: (context) => const Login()),
//                           );
//                         },
//                         child: Text(
//                           localizations.login,
//                           style: AppTextStyles.linkText,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
