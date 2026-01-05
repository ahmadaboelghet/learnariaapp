import 'package:flutter/material.dart';
import 'package:learnaria/screens/auth_screen.dart';
import 'package:learnaria/screens/home.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/l10n/app_localizations.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<Map<String, String>> introPages = [
      {
        'image': 'assets/images/onboarding_image.png',
        'title': appLocalizations.introTitle1,
        'description': appLocalizations.introDesc1,
      },
      {
        'image': 'assets/images/onboarding_image_2.png',
        'title': appLocalizations.introTitle2,
        'description': appLocalizations.introDesc2,
      },
      {
        'image': 'assets/images/onboarding_image_3.png',
        'title': appLocalizations.introTitle3,
        'description': appLocalizations.introDesc3,
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: Text(
              appLocalizations.skip,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: introPages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return _buildIntroPage(
                  introPages[index]['image']!,
                  introPages[index]['title']!,
                  introPages[index]['description']!,
                  theme,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 30.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    introPages.length,
                    (index) => _buildDot(index, theme),
                  ),
                ),
                _currentPage == introPages.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              appLocalizations.getStarted,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward),
                          ],
                        ),
                      )
                    : FloatingActionButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        backgroundColor: theme.colorScheme.onBackground,
                        child: Icon(
                          Icons.arrow_forward,
                          color: theme.scaffoldBackgroundColor,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(
    String imagePath,
    String title,
    String description,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: MediaQuery.of(context).size.height * 0.4,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.4,
                color: Colors.grey.withOpacity(0.2),
                child: Center(
                  child: Text(
                    'Image not found: $imagePath',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primary
            : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
