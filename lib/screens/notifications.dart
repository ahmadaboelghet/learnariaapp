// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.heading2),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          'No notifications yet.',
          style: AppTextStyles.secondaryText,
        ),
      ),
    );
  }
}