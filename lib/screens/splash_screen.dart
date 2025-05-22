import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../widgets/mango_logo.dart';
import '../services/user_service.dart';
import '../services/navigation_service.dart';
import '../utils/routes.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';
import '../utils/ui_components.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashScreen({
    Key? key,
    required this.onInitializationComplete,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // Add a debug print to verify the theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      debugPrint('Splash screen initialized with dark mode: $isDarkMode');
    });
  }

  Future<void> _initializeApp() async {
    // Add a delay to simulate loading and show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if onboarding has been completed
      final isOnboardingCompleted = await _userService.isOnboardingCompleted();

      print("Onboarding completed: $isOnboardingCompleted");

      if (isOnboardingCompleted) {
        // If onboarding is completed, navigate to home screen
        print("Navigating to home screen");
        NavigationService.navigateToReplacement(Routes.home);
      } else {
        // If onboarding is not completed, navigate to onboarding screen
        print("Navigating to onboarding screen");
        NavigationService.navigateToReplacement(Routes.onboarding);
      }
    } catch (e) {
      print("Error during app initialization: $e");
      // In case of error, navigate to onboarding as a fallback
      NavigationService.navigateToReplacement(Routes.onboarding);
    }

    widget.onInitializationComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated mango logo
            Animate(
              effects: [
                ScaleEffect(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                ),
              ],
              child: MangoLogo(
                size: 120,
                animate: true,
                animationDelay: 0.ms,
              ),
            ),

            const SizedBox(height: 24),

            // App Name with animation
            Animate(
              effects: [
                FadeEffect(
                  duration: 600.ms,
                  delay: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
                SlideEffect(
                  begin: const Offset(0, 0.2),
                  end: const Offset(0, 0),
                  duration: 600.ms,
                  delay: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
              ],
              child: Text(
                'FoodAI',
                style: AppTextStyles.heading1.copyWith(
                  color: textColor,
                  fontSize: 42,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Tagline with animation
            Animate(
              effects: [
                FadeEffect(
                  duration: 600.ms,
                  delay: 600.ms,
                ),
              ],
              child: Text(
                'Your personal nutrition assistant',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            Animate(
              effects: [
                FadeEffect(
                  duration: 400.ms,
                  delay: 800.ms,
                ),
              ],
              child: SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Loading text
            Animate(
              effects: [
                FadeEffect(
                  duration: 400.ms,
                  delay: 1000.ms,
                ),
              ],
              child: Text(
                'Loading...',
                style: AppTextStyles.caption.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
