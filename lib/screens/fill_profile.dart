// import 'package:flutter/material.dart';
// import 'package:learnaria/screens/main_layout.dart';
// import 'package:learnaria/utils/app_styles.dart'; // Adjust import
// import 'package:learnaria/widgets/custom_text_field.dart'; // Adjust import
// // Adjust import
// import 'package:intl/intl.dart'; // For date formatting

// class FillProfileScreen extends StatefulWidget {
//   const FillProfileScreen({super.key});

//   @override
//   _FillProfileScreenState createState() => _FillProfileScreenState();
// }

// class _FillProfileScreenState extends State<FillProfileScreen> {
//   final TextEditingController _fullNameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   String? _selectedGender;
//   final List<String> _genders = ['Male', 'Female', 'Other'];

//   DateTime? _selectedDate;

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: ColorScheme.light(
//               primary: AppColors.primaryYello, // Header background color
//               onPrimary: Colors.white, // Header text color
//               onSurface: AppColors.primaryBlack, // Body text color
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: AppColors.primaryYello, // Button text color
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _dobController.dispose();
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
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Text(
//           'Fill Profile',
//           style: AppTextStyles.heading2,
//         ),
//         centerTitle: false,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Stack(
//                 children: [
//                   CircleAvatar(
//                     radius: 60,
//                     backgroundColor: AppColors.lightGrey,
//                     child: Icon(Icons.person_outline, size: 60, color: AppColors.mediumGrey),
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryYello,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 30),
//             CustomTextField(
//               controller: _fullNameController,
//               hintText: 'Full name',
//               prefixIcon: Icons.person_outline,
//             ),
//             SizedBox(height: 20),
//             CustomTextField(
//               controller: _emailController,
//               hintText: 'Email',
//               prefixIcon: Icons.email_outlined,
//               keyboardType: TextInputType.emailAddress,
//             ),
//             SizedBox(height: 20),
//             CustomTextField(
//               controller: _dobController,
//               hintText: 'Date of birth',
//               prefixIcon: Icons.calendar_today_outlined,
//               readOnly: true,
//               onTap: () => _selectDate(context),
//             ),
//             SizedBox(height: 20),
//             CustomTextField(
//               controller: _phoneController,
//               hintText: 'Phone number',
//               prefixIcon: Icons.phone_outlined,
//               keyboardType: TextInputType.phone
//             ),
//             SizedBox(height: 20),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 color: AppColors.lightGrey,
//                 borderRadius: BorderRadius.circular(10.0),
//               ),
//               child: DropdownButtonFormField<String>(
//                 value: _selectedGender,
//                 hint: Text('Gender', style: AppTextStyles.secondaryText),
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(Icons.transgender, color: AppColors.mediumGrey),
//                   border: InputBorder.none,
//                   contentPadding: EdgeInsets.symmetric(vertical: 16.0),
//                 ),
//                 icon: Icon(Icons.keyboard_arrow_down, color: AppColors.mediumGrey),
//                 items: _genders.map((String gender) {
//                   return DropdownMenuItem<String>(
//                     value: gender,
//                     child: Text(gender, style: AppTextStyles.bodyText),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedGender = newValue;
//                   });
//                 },
//               ),
//             ),
//             SizedBox(height: 40),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Simulate saving profile and navigate to ProfileScreen
//                   Navigator.of(context).pushReplacement(
//                     MaterialPageRoute(builder: (context) => MainLayoutScreen()),
//                   );
//                 },
//                 style: primaryButtonStyle(),
//                 child: Text('Done', style: AppTextStyles.buttonText),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
