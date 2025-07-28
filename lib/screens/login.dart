
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:learnaria/utils/app_styles.dart';
// import 'package:learnaria/widgets/custom_text_field.dart';
// import 'package:learnaria/screens/otp_verification.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);

//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isLoading = false;
//   String? _errorMessage;

//   Future<void> _verifyPhoneNumber() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     // Firebase expects phone numbers in E.164 format (e.g., +1234567890)
//     // You might need to add a country code picker or prepend a default one.
//     final String phoneNumber = _phoneController.text.trim();
//     if (!phoneNumber.startsWith('+')) {
//       _errorMessage = 'Phone number must start with a country code (e.g., +201234567890).';
//       setState(() { _isLoading = false; });
//       return;
//     }

//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           // Auto-retrieval on Android, or instant verification
//           setState(() { _isLoading = false; });
//           await _auth.signInWithCredential(credential);
//           // Navigate to main layout on successful auto-verification
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => OtpVerificationScreen(
//               phoneNumber: phoneNumber,
//               verificationId: '', // Not needed for auto-verification
//               isAutoVerified: true,
//             )),
//           );
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           setState(() {
//             _isLoading = false;
//             if (e.code == 'invalid-phone-number') {
//               _errorMessage = 'The provided phone number is not valid.';
//             } else if (e.code == 'too-many-requests') {
//               _errorMessage = 'Too many requests. Please try again later.';
//             } else {
//               _errorMessage = 'Verification failed: ${e.message}';
//             }
//             print('Verification Failed: ${e.code} - ${e.message}');
//           });
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           setState(() { _isLoading = false; });
//           // Navigate to OTP verification screen
//           Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (context) => OtpVerificationScreen(
//                 phoneNumber: phoneNumber,
//                 verificationId: verificationId,
//                 resendToken: resendToken,
//               ),
//             ),
//           );
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           setState(() { _isLoading = false; });
//           // This callback is fired when the SMS code is not auto-retrieved
//           // and the timeout expires. The verificationId is still valid for manual entry.
//           print('Auto-retrieval timeout. Verification ID: $verificationId');
//         },
//         timeout: const Duration(seconds: 60), // Optional: Set a timeout for SMS auto-retrieval
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = 'An unexpected error occurred: $e';
//         print('Unexpected error: $e');
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           'Login / Register',
//           style: AppTextStyles.heading2,
//         ),
//         centerTitle: false,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome to Learnaria!",
//               style: AppTextStyles.heading1.copyWith(color: AppColors.primaryYello),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Enter your phone number to continue.",
//               style: AppTextStyles.secondaryText,
//             ),
//             SizedBox(height: 30),
//             CustomTextField(
//               controller: _phoneController,
//               hintText: 'e.g., +201234567890',
//               prefixIcon: Icons.phone,
//               keyboardType: TextInputType.phone,
//             ),
//             SizedBox(height: 20),
//             if (_errorMessage != null)
//               Text(
//                 _errorMessage!,
//                 style: AppTextStyles.smallRedText.copyWith(color: Colors.red),
//               ),
//             SizedBox(height: 20),
//             _isLoading
//                 ? Center(
//                     child: CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYello),
//                     ),
//                   )
//                 : SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _verifyPhoneNumber,
//                       style: primaryButtonStyle(),
//                       child: Text('Send Verification Code', style: AppTextStyles.buttonText),
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
