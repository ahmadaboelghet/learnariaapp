// import 'package:flutter/material.dart';
// import 'package:learnaria/utils/app_styles.dart'; // Adjust import
// import 'package:learnaria/widgets/custom_text_field.dart'; // Adjust import
// import 'package:learnaria/screens/otp_verification.dart'; // Adjust import

// class ForgetPasswordScreen extends StatefulWidget {
//   const ForgetPasswordScreen({super.key});

//   @override
//   _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
// }

// class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
//   final TextEditingController _emailController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Forget Password',
//               style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Write your email to send you the verification code',
//               style: AppTextStyles.secondaryText,
//             ),
//             SizedBox(height: 30),
//             CustomTextField(
//               controller: _emailController,
//               hintText: 'example@gmail.com',
//               prefixIcon: Icons.email_outlined,
//               keyboardType: TextInputType.emailAddress,
//             ),
//             SizedBox(height: 40),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Simulate sending code and navigate to OTP verification
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (context) => OtpVerificationScreen(
//                         email: _emailController.text.isNotEmpty ? _emailController.text : 'example@gmail.com',
//                       ),
//                     ),
//                   );
//                 },
//                 style: primaryButtonStyle(),
//                 child: Text('Continue', style: AppTextStyles.buttonText),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
