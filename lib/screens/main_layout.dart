import 'package:flutter/material.dart';
import 'package:learnaria/screens/progress_report.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/screens/home.dart';
import 'package:learnaria/screens/more_screen.dart';
import 'package:learnaria/l10n/app_localizations.dart';
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          HomeScreen(),
          ProgressReportScreen(),
          MoreScreen(), // Using the new MoreScreen
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryBlack,
        selectedItemColor: AppColors.primaryYello,
        unselectedItemColor: AppColors.mediumGrey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const ImageIcon(
              AssetImage('assets/images/home_icon.png'),
              size: 20,
            ),
            label: appLocalizations.home,
          ),
          BottomNavigationBarItem(
            icon: const ImageIcon(
              AssetImage('assets/images/reports_icon.png'),
              size: 20,
            ),
            label: appLocalizations.reports,
          ),
          BottomNavigationBarItem(
            icon: const ImageIcon(
              AssetImage('assets/images/menu.png'),
              size: 20,
            ),
            label: appLocalizations.more, // Using the new "More" label
          ),
        ],
      ),
    );
  }
}
