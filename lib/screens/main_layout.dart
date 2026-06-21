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
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16171D) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark ? const Color(0xFF262930) : const Color(0xFFE5E8EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final itemWidth = barWidth / 3;
          final capsuleLeft = Directionality.of(context) == TextDirection.rtl
              ? (2 - _selectedIndex) * itemWidth + 8.0
              : _selectedIndex * itemWidth + 8.0;

          return Stack(
            children: [
              // Sliding Background Pill Capsule
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: capsuleLeft,
                top: 10,
                width: itemWidth - 16.0,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryYello.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              
              // Navigation Items Row
              Row(
                children: [
                  Expanded(
                    child: _buildNavBarItem(
                      index: 0,
                      iconPath: 'assets/images/home_icon.png',
                      label: appLocalizations.home,
                    ),
                  ),
                  Expanded(
                    child: _buildNavBarItem(
                      index: 1,
                      iconPath: 'assets/images/reports_icon.png',
                      label: appLocalizations.reports,
                    ),
                  ),
                  Expanded(
                    child: _buildNavBarItem(
                      index: 2,
                      iconPath: 'assets/images/menu.png',
                      label: appLocalizations.more,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.15 : 1.0,
              child: ImageIcon(
                AssetImage(iconPath),
                size: 22,
                color: isSelected 
                    ? AppColors.primaryYello 
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? AppColors.primaryYello 
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
