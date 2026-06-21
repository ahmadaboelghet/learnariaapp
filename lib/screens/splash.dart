import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnaria/utils/app_styles.dart';
import 'package:learnaria/widgets/glass_container.dart'; // Contains LiquidBackground

class SplashScreen extends StatefulWidget {
  final Widget navigateTo;
  const SplashScreen({super.key, required this.navigateTo});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _textFadeAnimation;

  late Animation<double> _glowScaleAnimation;
  late Animation<double> _glowOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initial entrance animation controller (2.4 seconds for smooth, elegant pacing)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Entrance Animations
    // Logo starts slightly larger (1.25) and scales down smoothly to normal size (1.0)
    _scaleAnimation = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Glow background blooms slowly behind the logo
    _glowScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _glowOpacityAnimation = Tween<double>(begin: 0.0, end: 0.22).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Tagline text slides up very subtly (offset of 0.25) and fades in
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeIn),
      ),
    );

    // Start entrance animations
    _animationController.forward().then((_) {
      // Settle splash screen for 500ms before transition
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  widget.navigateTo,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 700),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // LiquidBackground adapts automatically to light/dark themes and draws the grid
      body: LiquidBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Slow-blooming glowing gold orb behind the logo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 300 * _glowScaleAnimation.value,
                        height: 300 * _glowScaleAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primaryYello.withOpacity(
                                _glowOpacityAnimation.value,
                              ),
                              AppColors.primaryYello.withOpacity(0.0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // 2. Animated Logo (Smooth scale down + fade in)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Image.asset(
                        'assets/images/logo_bg.png',
                        width: 220,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.school_rounded,
                            size: 100,
                            color: AppColors.primaryYello,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // 3. Tagline & Loader (Subtle slide + fade transition)
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Stay Connected. Stay Guided',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.darkGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}