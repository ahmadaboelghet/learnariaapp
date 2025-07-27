import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import path based on your project name
import 'package:learnaria/screens/edit_profile.dart'; // Adjust import path
// import 'package:learnaria/screens/home_screen.dart'; // No longer directly imported for navigation here

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // _selectedIndex is no longer needed here as MainLayoutScreen manages it
  bool _isDarkModeEnabled = false; // State for Dark Mode toggle

  // _onItemTapped is no longer needed here as MainLayoutScreen manages it

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // REMOVED: leading IconButton (back button)
        leading: null, // This removes the back button entirely
        automaticallyImplyLeading: false, // Ensures no default back button is added
        title: Text(
          'Your Profile',
          style: AppTextStyles.heading2,
        ),
        centerTitle: false, // Align title to the left
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
                    // Placeholder for actual profile image.
                    // Ensure 'assets/images/profile_pic.png' exists and is declared in pubspec.yaml
                    backgroundImage: AssetImage('assets/images/profile_pic.png'),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Fallback if image fails to load
                      print('Error loading profile image: $exception');
                    },
                    child: Image.asset(
                      'assets/images/profile_pic.png', // Redundant but good for error handling
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.person_outline, size: 50, color: AppColors.mediumGrey);
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Mohamed Ahmed Ali', // Replace with actual user name
                    style: AppTextStyles.heading2,
                  ),
                  Text(
                    'example@gmail.com', // Replace with actual user email
                    style: AppTextStyles.secondaryText,
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Profile Options List
            _buildProfileOption(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
                );
              },
            ),
            _buildProfileOption(
              icon: Icons.credit_card_outlined,
              title: 'Payment option',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment option tapped (Placeholder)')),
                );
              },
            ),
            _buildProfileOption(
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notifications tapped (Placeholder)')),
                );
              },
            ),
            _buildProfileOption(
              icon: Icons.security_outlined,
              title: 'Security',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Security tapped (Placeholder)')),
                );
              },
            ),
            _buildProfileOption(
              icon: Icons.language_outlined,
              title: 'Language',
              trailingText: 'English (US)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language tapped (Placeholder)')),
                );
              },
            ),
            // Dark Mode option with a Switch
            _buildProfileOption(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              isSwitch: true, // Indicate this option has a switch
              switchValue: _isDarkModeEnabled,
              onSwitchChanged: (value) {
                setState(() {
                  _isDarkModeEnabled = value;
                  // In a real app, you would update the app's theme here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dark Mode toggled: $value')),
                  );
                });
              },
            ),
            _buildProfileOption(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terms & Conditions tapped (Placeholder)')),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      // REMOVED: bottomNavigationBar from here
    );
  }

  // Helper widget to build each profile option row
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? trailingText, // Optional text to display on the right (e.g., 'English (US)')
    VoidCallback? onTap, // Optional callback for when the option is tapped
    bool isSwitch = false, // New parameter to indicate if it's a switch option
    bool switchValue = false, // Current value for the switch
    ValueChanged<bool>? onSwitchChanged, // Callback for switch changes
  }) {
    return GestureDetector(
      onTap: isSwitch ? null : onTap, // Only allow onTap if not a switch
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0), // Vertical spacing between options
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3), // Subtle shadow for depth
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlack), // Icon for the option
            SizedBox(width: 15), // Spacing between icon and title
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyText, // Style for the option title
              ),
            ),
            if (trailingText != null) // Display trailing text if provided
              Text(
                trailingText,
                style: AppTextStyles.secondaryText.copyWith(color: AppColors.primaryYello),
              ),
            if (isSwitch) // Display a switch if it's a switch option
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: AppColors.primaryYello,
              )
            else if (trailingText == null) // Only show arrow if no trailing text and not a switch
              Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey), // Forward arrow icon
          ],
        ),
      ),
    );
  }
}