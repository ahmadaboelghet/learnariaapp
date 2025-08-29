// import 'package:flutter/material.dart';
// import 'package:learnaria/l10n/app_localizations.dart';
// import 'package:learnaria/screens/forget_password.dart';
// import 'package:learnaria/screens/main_layout.dart';
// import 'package:learnaria/screens/signup.dart';
// import 'package:learnaria/utils/app_styles.dart';
// import 'package:learnaria/widgets/custom_text_field.dart';
// import 'package:learnaria/widgets/password_text_field.dart';

// class Login extends StatefulWidget {
//   const Login({super.key});

//   @override
//   State<Login> createState() => _LoginState();
// }

// class _LoginState extends State<Login> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();

//   void _signIn() {
//     if (_formKey.currentState!.validate()) {
//       // TODO: Perform login with phone and password
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
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
//                     localizations.login,
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
//                      validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return localizations.pleaseEnterPhone;
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   PasswordTextField(
//                     controller: _passwordController,
//                     labelText: localizations.password,
//                     hintText: localizations.password, // Corrected
//                      validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return localizations.pleaseEnterPassword;
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 30),
//                   ElevatedButton(
//                     onPressed: _signIn,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.primaryYello,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                        shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       localizations.login,
//                       style: AppTextStyles.buttonText,
//                     ),
//                   ),
//                    Align(
//                     alignment: Alignment.centerRight,
//                     child: TextButton(
//                       onPressed: () {
//                         Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgetPassword()));
//                       },
//                       child: Text(
//                         localizations.forgetPassword,
//                          style: AppTextStyles.linkText,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         localizations.dontHaveAccount,
//                         style: AppTextStyles.bodyText,
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUp()));
//                         },
//                         child: Text(
//                           localizations.signup,
//                            style: AppTextStyles.linkText,
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
