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
      bottomNavigationBar: _buildCustomNavBar(context, appLocalizations),
    );
  }

  Widget _buildCustomNavBar(BuildContext context, AppLocalizations appLocalizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16171D) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF262930) : const Color(0xFFE5E8EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(
              index: 0,
              iconPath: 'assets/images/home_icon.png',
              label: appLocalizations.home,
            ),
            _buildNavBarItem(
              index: 1,
              iconPath: 'assets/images/reports_icon.png',
              label: appLocalizations.reports,
            ),
            _buildNavBarItem(
              index: 2,
              iconPath: 'assets/images/menu.png',
              label: appLocalizations.more,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index,
    required String iconPath,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryYello.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageIcon(
              AssetImage(iconPath),
              size: 22,
              color: isSelected 
                  ? AppColors.primaryYello 
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryYello,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
