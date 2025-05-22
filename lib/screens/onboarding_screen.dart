import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/placeholder_image.dart';
import '../services/navigation_service.dart';
import '../utils/routes.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';
import '../utils/ui_components.dart';
import '../services/user_service.dart';
import '../widgets/mango_logo.dart';
import 'home_screen.dart';
import 'gender_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = Constants.onboardingWelcomeScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;

  bool _isLoading = false;

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryColor : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Bar with logo and progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Logo
                  Row(
                    children: [
                      MangoLogo(
                        size: 36,
                        animate: false,
                        showShadow: false,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FoodAI',
                        style: AppTextStyles.heading4.copyWith(
                          color: textColor,
                        ),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(duration: 600.ms),

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildPageIndicator(),
                    ),
                  ),

                  // Skip button
                  TextButton(
                    onPressed: () {
                      _navigateToGenderSelection(context);
                    },
                    child: Text(
                      'Skip',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms),
                ],
              ),
            ),

            // Enhanced Welcome badge with Material 3 Expressive design
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColorLight.withOpacity(0.2),
                          AppColors.primaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ).animate(
                          onPlay: (controller) => controller.repeat(reverse: true),
                        ).rotate(
                          begin: -0.1,
                          end: 0.1,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Welcome to FoodAI',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.2, end: 0.0, duration: 600.ms, delay: 200.ms)
            .shimmer(
              duration: const Duration(seconds: 2),
              delay: const Duration(milliseconds: 1000),
              color: AppColors.primaryColor.withOpacity(0.2),
            ),

            // Food images with calorie info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Breakfast image
                    Positioned(
                      left: 0,
                      top: 20,
                      child: _buildFoodCard(
                        'Breakfast',
                        '10 min.',
                        '284 kcal',
                        '',
                        0,
                      ),
                    ),

                    // Lunch image
                    Positioned(
                      right: 0,
                      child: _buildFoodCard(
                        'Lunch',
                        '10 min.',
                        '358 kcal',
                        '',
                        1,
                      ),
                    ),

                    // Dinner image
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _buildFoodCard(
                        'Dinner',
                        '20 min.',
                        '636 kcal',
                        '',
                        2,
                      ),
                    ),

                    // Center mango logo
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: MangoLogo(
                            size: 60,
                            animate: true,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 800.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      delay: 800.ms,
                      curve: Curves.elasticOut,
                    ),
                  ],
                ),
              ),
            ),

            // Text content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Your Personal\nNutrition Assistant',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2.copyWith(
                      color: textColor,
                      height: 1.2,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideY(begin: 0.2, end: 0.0, duration: 600.ms, delay: 600.ms),

                  const SizedBox(height: 12),

                  Text(
                    'Track your meals, analyze nutrition, and reach your health goals',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: subtitleColor,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Enhanced Social login buttons with Material 3 Expressive design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Google login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Add haptic feedback
                        HapticFeedback.mediumImpact();

                        // Google login with Supabase
                        try {
                          setState(() {
                            _isLoading = true;
                          });

                          // Simulate successful sign-in
                          debugPrint('Google login successful (simulated)');
                          _navigateToGenderSelection(context);
                        } catch (e) {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Google login failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          debugPrint('Google login error: $e');
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            margin: const EdgeInsets.only(right: 12.0),
                            child: Icon(
                              Icons.g_translate_rounded,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Continue with Google',
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 1000.ms)
                  .slideY(begin: 0.2, end: 0.0, duration: 600.ms, delay: 1000.ms),

                  const SizedBox(height: 16),

                  // Skip button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () async {
                        // Add haptic feedback
                        HapticFeedback.mediumImpact();

                        // Skip login logic
                        debugPrint('Skip pressed');
                        setState(() {
                          _isLoading = true;
                        });

                        // Navigate to gender selection instead of home
                        _navigateToGenderSelection(context);

                        setState(() {
                          _isLoading = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Skip for now',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 1200.ms)
                  .slideY(begin: 0.2, end: 0.0, duration: 600.ms, delay: 1200.ms),
                ],
              ),
            ),

            // Terms and conditions
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to FoodAI\'s '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 1400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(String title, String time, String calories, String imagePath, int index) {
    // Calculate animation delay based on index
    final delay = Duration(milliseconds: 300 + (index * 200));

    // Enhanced food card with Material 3 Expressive design
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
        // Enhanced gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: title == 'Breakfast'
              ? [
                  AppColors.primaryColorLight.withRed((AppColors.primaryColorLight.red + 20).clamp(0, 255)),
                  AppColors.primaryColor,
                ]
              : title == 'Lunch'
                  ? [
                      Colors.green[300]!,
                      Colors.green[600]!.withBlue((Colors.green[600]!.blue - 20).clamp(0, 255)),
                    ]
                  : [
                      Colors.red[300]!.withRed((Colors.red[300]!.red + 20).clamp(0, 255)),
                      Colors.red[600]!,
                    ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Decorative pattern overlay with gradient
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcOver,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: title == 'Breakfast'
                        ? [
                            Colors.orange.withOpacity(0.3),
                            Colors.orange.withOpacity(0.1),
                          ]
                        : title == 'Lunch'
                            ? [
                                Colors.green.withOpacity(0.3),
                                Colors.green.withOpacity(0.1),
                              ]
                            : [
                                Colors.red.withOpacity(0.3),
                                Colors.red.withOpacity(0.1),
                              ],
                  ),
                ),
              ),
            ),
          ),

          // Enhanced food icon with container
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                title == 'Breakfast' ? Icons.free_breakfast :
                title == 'Lunch' ? Icons.lunch_dining :
                Icons.dinner_dining,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Enhanced title with better typography
          Positioned(
            top: 16,
            right: 16,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Enhanced gradient overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          // Enhanced time and calories info
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal description
                Text(
                  title == 'Breakfast' ? 'Start your day right'
                      : title == 'Lunch' ? 'Midday energy boost'
                      : 'Evening nutrition',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Time and calories in a row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Enhanced time badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            time,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Enhanced calories badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            calories,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: delay)
    .slideY(begin: 0.2, end: 0.0, duration: 600.ms, delay: delay)
    .shimmer(
      duration: const Duration(seconds: 2),
      delay: delay + const Duration(milliseconds: 500),
      color: Colors.white.withOpacity(0.2),
    );
  }

  final UserService _userService = UserService();

  // Navigate to gender selection screen
  void _navigateToGenderSelection(BuildContext context) {
    print('Navigating to gender selection screen');

    // Use push to maintain the navigation stack
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GenderSelectionScreen(
          fromOnboarding: true,
        ),
      ),
    );
  }

  // Navigate directly to home screen
  Future<void> _navigateToHome(BuildContext context) async {
    // Mark onboarding as completed even when skipping
    await _userService.setOnboardingCompleted(true);

    // Navigate to home screen
    NavigationService.navigateToReplacement(Routes.home);
  }

  Widget _buildSocialButton(
    String text,
    String? logoPath,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed, {
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: backgroundColor == Colors.white
                ? Colors.black.withOpacity(0.08)
                : backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? Colors.grey[300] : backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: backgroundColor == Colors.white
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main content
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        backgroundColor == Colors.white ? Colors.black54 : Colors.white,
                      ),
                    ),
                  )
                else if (logoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Image.asset(
                      logoPath,
                      height: 24,
                      width: 24,
                    ),
                  )
                else if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundColor == Colors.white
                          ? Colors.grey.shade100
                          : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    margin: const EdgeInsets.only(right: 12.0),
                    child: Icon(
                      icon,
                      size: 20,
                      color: backgroundColor == Colors.white
                          ? textColor
                          : Colors.white,
                    ),
                  ),
                Text(
                  isLoading ? 'Please wait...' : text,
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: isLoading ? Colors.grey[600] : textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 1000.ms)
    .slideY(begin: 0.2, end: 0.0, duration: 600.ms, delay: 1000.ms);
  }
}
