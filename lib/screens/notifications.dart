import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';
// استيراد الترجمة

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      // --- دعم الوضع المظلم ---
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        // --- دعم الترجمة والوضع المظلم ---
        title: Text(
          appLocalizations.notifications, // <-- نص مترجم
          style: AppTextStyles.heading2.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          appLocalizations.noNotificationsYet, // <-- نص مترجم
          style: AppTextStyles.secondaryText,
        ),
      ),
    );
  }
}
