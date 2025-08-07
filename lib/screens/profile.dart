import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/screens/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learnaria/screens/auth_check.dart'; // <<< استيراد

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkModeEnabled = false;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthCheck()),
        (route) => false,
      );
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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.lightGrey,
                    child: Icon(Icons.person_outline, size: 50, color: AppColors.mediumGrey),
                  ),
                  SizedBox(height: 15),
                  Text('Mohamed Ahmed Ali', style: AppTextStyles.heading2),
                  Text(
                    FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'No Phone',
                    style: AppTextStyles.secondaryText,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            _buildProfileOption(icon: Icons.edit_outlined, title: 'Edit Profile', onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditProfileScreen()));
            }),
            _buildProfileOption(icon: Icons.credit_card_outlined, title: 'Payment option', onTap: () {}),
            _buildProfileOption(icon: Icons.notifications_none_outlined, title: 'Notifications', onTap: () {}),
            _buildProfileOption(icon: Icons.security_outlined, title: 'Security', onTap: () {}),
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
            // --- زر تسجيل الخروج ---
            _buildProfileOption(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: _signOut,
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
