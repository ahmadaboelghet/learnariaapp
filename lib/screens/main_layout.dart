import 'package:flutter/material.dart';
import 'package:learnaria/screens/progress_report.dart';
import 'package:learnaria/utils/app_styles.dart'; // Adjust import path
import 'package:learnaria/screens/home.dart'; // Import HomeScreen
import 'package:learnaria/screens/profile.dart'; // Import ProfileScreen
// Import other main screens as needed (e.g., MyCoursesScreen, InboxScreen)

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  _MainLayoutScreenState createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0; // Initial selected tab (Home)
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
    _pageController.jumpToPage(index); // Jump to the selected page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          HomeScreen(), // Screen for 'HOME'
          ProgressReportScreen(), // Screen for 'MY COURSES'
          ProfileScreen(), // Screen for 'PROFILE'
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryBlack, // Changed to black
        selectedItemColor: AppColors.primaryYello,
        unselectedItemColor: AppColors.mediumGrey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/home_icon.png'), // Replace with your actual home icon path
              size: 20,
            ),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/reports_icon.png'), // Replace with your actual reports icon path
              size: 20,
            ),
            label: 'REPORTS',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/images/profile_icon.png'), // Replace with your actual profile icon path
              size: 20,
            ),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}