// lib/screens/profile.dart

import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/screens/login.dart'; // Import for navigation
import 'package:learnaria/screens/notifications.dart'; // Import for navigation

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkModeEnabled = false;
  // This would come from your data model, but for now we'll use a placeholder
  String studentName = "Mohamed Ahmed"; 

  // --- MODIFIED: Sign out logic with confirmation dialog ---
  Future<void> _signOut() async {
    // Show confirmation dialog
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User chose not to sign out
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // User confirmed sign out
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // If the user confirmed, then proceed with sign out
    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Navigate to LoginScreen and remove all previous routes
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Text('Your Profile', style: AppTextStyles.heading2),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.lightGrey,
                        child: Icon(Icons.person_outline, size: 50, color: AppColors.mediumGrey),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Change picture functionality coming soon!')),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYello,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)
                            ),
                            child: Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text('$studentName\'s parent', style: AppTextStyles.heading2),
                  Text(
                    FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'No Phone',
                    style: AppTextStyles.secondaryText,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            
            // --- MODIFIED: Removed Edit Profile and Payment Option ---
            // --- MODIFIED: Notifications now navigates to a new screen ---
            _buildProfileOption(
              icon: Icons.notifications_none_outlined, 
              title: 'Notifications', 
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => NotificationsScreen()));
              }
            ),
            _buildProfileOption(icon: Icons.security_outlined, title: 'Security', onTap: () {}),
            
            // --- NEW: Added Language option ---
            _buildProfileOption(icon: Icons.language_outlined, title: 'Language', onTap: () {}),

            _buildProfileOption(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              isSwitch: true,
              switchValue: _isDarkModeEnabled,
              onSwitchChanged: (value) {
                setState(() { _isDarkModeEnabled = value; });
              },
            ),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 10),
            _buildProfileOption(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: _signOut, // The function now contains the confirmation logic
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    bool isLogout = false,
  }) {
    final color = isLogout ? Colors.red : AppColors.primaryBlack;

    return GestureDetector(
      onTap: isSwitch ? null : onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 15),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyText.copyWith(color: color)),
            ),
            if (isSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: AppColors.primaryYello,
              )
            else if (!isLogout)
              Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
          ],
        ),
      ),
    );
  }
}