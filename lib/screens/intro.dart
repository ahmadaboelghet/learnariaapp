import 'package:flutter/material.dart';
import 'package:learnaria/screens/login.dart';
import 'package:learnaria/screens/signup.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
            child: Text(
              appLocalizations.skip,
              style: AppTextStyles.secondaryText,
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
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    introPages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                _currentPage == introPages.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: primaryButtonStyle().copyWith(
                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                          minimumSize: MaterialStateProperty.all(const Size(150, 50)),
                        ),
                        child: Row(
                          children: [
                            Text(appLocalizations.getStarted, style: AppTextStyles.buttonText),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward, color: Colors.white),
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
                        backgroundColor: AppColors.primaryBlack,
                        child: const Icon(Icons.arrow_forward, color: Colors.white),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroPage(String imagePath, String title, String description) {
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
                color: AppColors.lightGrey,
                child: Center(
                  child: Text('Image not found: $imagePath', textAlign: TextAlign.center),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTextStyles.secondaryText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primaryBlack : AppColors.mediumGrey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
