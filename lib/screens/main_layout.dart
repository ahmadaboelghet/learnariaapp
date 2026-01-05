import 'package:flutter/material.dart';
import 'package:learnaria/screens/home.dart';
import 'package:learnaria/screens/more_screen.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';

// ملاحظة: افترضنا أن الشاشات الأخرى موجودة، إذا لم تكن موجودة استبدلها مؤقتاً بـ Placeholder
// import 'package:learnaria/screens/inbox_screen.dart';
// import 'package:learnaria/screens/reports_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  _MainLayoutScreenState createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(
      body: Center(child: Text("Reports")),
    ), // Placeholder until file is ready
    const Scaffold(
      body: Center(child: Text("Inbox")),
    ), // Placeholder until file is ready
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      // شريط تنقل عائم وعصري
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.primary.withOpacity(0.2),
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          child: NavigationBar(
            height: 70,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home, color: AppColors.primary),
                label: appLocalizations.home,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(
                  Icons.bar_chart,
                  color: AppColors.primary,
                ),
                label: appLocalizations.reports,
              ),
              NavigationDestination(
                icon: const Icon(Icons.mail_outline),
                selectedIcon: const Icon(Icons.mail, color: AppColors.primary),
                label: appLocalizations.inbox,
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view),
                selectedIcon: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                ),
                label: appLocalizations.more,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
