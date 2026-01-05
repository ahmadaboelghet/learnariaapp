import 'package:flutter/material.dart';
import 'package:learnaria/screens/edit_profile.dart';
import 'package:learnaria/screens/auth_screen.dart'; // For logout logic
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          appLocalizations.more,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 20),
            _buildMenuItem(
              context,
              icon: Icons.person_outline,
              title: appLocalizations.profile,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: appLocalizations.notifications,
              onTap: () {
                // Navigate to Notifications
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.language,
              title: appLocalizations.language,
              onTap: () {
                // Change Language
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              onTap: () {
                // Toggle Theme
              },
            ),
            const SizedBox(height: 20),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: appLocalizations.logout,
              isDestructive: true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: const Icon(Icons.person, size: 30, color: AppColors.primary),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Student Name",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "View Profile",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDestructive
                  ? Colors.red
                  : Theme.of(context).iconTheme.color,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDestructive
                  ? Colors.red
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
