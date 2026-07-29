import 'package:flutter/material.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/screens/notifications.dart';
import 'package:provider/provider.dart';
import 'package:learnaria/utils/theme_provider.dart';
import 'package:learnaria/utils/locale_provider.dart';
import 'package:learnaria/l10n/app_localizations.dart';
import 'package:learnaria/widgets/glass_container.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:learnaria/services/auth_service.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _showDeleteAccount = false;

  @override
  void initState() {
    super.initState();
    _setupRemoteConfig();
  }

  Future<void> _setupRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(const {
        'show_delete_account': true,
      });
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await remoteConfig.fetchAndActivate();
      if (mounted) {
        setState(() {
          _showDeleteAccount = remoteConfig.getBool('show_delete_account');
        });
      }
    } catch (e) {
      debugPrint('Error setting up Remote Config: $e');
    }
  }

  Future<void> _signOut() async {
    if (!mounted) return;
    final appLocalizations = AppLocalizations.of(context)!;
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.confirmSignOut),
        content: Text(appLocalizations.areYouSureSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.signOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      if (mounted) {
        await AuthService().logout(context);
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;
    final appLocalizations = AppLocalizations.of(context)!;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.confirmDeleteAccount),
        content: Text(appLocalizations.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.deleteAccount, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        if (mounted) {
          await AuthService().logout(context);
        }
      } catch (e) {
        debugPrint('Error signing out during deletion placeholder: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Text(
          appLocalizations.more,
          style: AppTextStyles.heading2.copyWith(color: isDark ? Colors.white : Colors.black87),
        ),
        centerTitle: false,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileOption(
                icon: Icons.notifications_none_outlined, 
                title: appLocalizations.notifications, 
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                }
              ),
              
              _buildProfileOption(
                icon: Icons.language_outlined, 
                title: appLocalizations.language,
                trailingText: localeProvider.locale?.languageCode == 'ar' ? 'العربية' : 'English',
                onTap: () {
                  localeProvider.toggleLocale();
                }
              ),
  
              _buildProfileOption(
                icon: Icons.dark_mode_outlined,
                title: appLocalizations.darkMode,
                isSwitch: true,
                switchValue: themeProvider.isDarkMode,
                onSwitchChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              if (_showDeleteAccount) ...[
                _buildProfileOption(
                  icon: Icons.delete_forever_outlined,
                  title: appLocalizations.deleteAccount,
                  onTap: _deleteAccount,
                  isDelete: true,
                ),
                const SizedBox(height: 8),
              ],
              _buildProfileOption(
                icon: Icons.logout,
                title: appLocalizations.signOut,
                onTap: _signOut,
                isLogout: true,
              ),
            ],
          ),
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
    bool isDelete = false,
    String? trailingText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine colors
    final Color iconColor = (isLogout || isDelete)
        ? Colors.red 
        : (isDark ? Colors.white : Colors.black87);
        
    final Color textColor = isLogout 
        ? Colors.red 
        : (isDark ? Colors.white : Colors.black87);

    return GestureDetector(
      onTap: isSwitch ? null : onTap,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 15),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyText.copyWith(color: textColor)),
            ),
            if (isSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeThumbColor: AppColors.primaryYello,
              )
            else if (trailingText != null)
              Row(
                children: [
                  Text(trailingText, style: AppTextStyles.secondaryText),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
                ],
              )
            else if (!isLogout && !isDelete)
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mediumGrey),
          ],
        ),
      ),
    );
  }
}
