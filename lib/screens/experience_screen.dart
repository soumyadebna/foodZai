import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';
import '../utils/ui_components.dart';
import 'weight_input_screen.dart';
import '../services/user_service.dart';

class ExperienceScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onNext;

  const ExperienceScreen({Key? key, this.userData, this.onNext}) : super(key: key);

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  String? _selectedExperience;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _experienceOptions = [
    {
      'value': 'no',
      'title': 'No',
      'subtitle': 'This is my first time',
      'icon': Icons.thumb_down_outlined,
    },
    {
      'value': 'yes',
      'title': 'Yes',
      'subtitle': 'I\'ve used similar apps before',
      'icon': Icons.thumb_up_outlined,
    },
  ];

  // Current page in the onboarding flow
  final int _currentPage = Constants.experienceScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;

  @override
  void initState() {
    super.initState();
    // Ensure no experience is pre-selected by default
    setState(() {
      _selectedExperience = null;
    });
  }

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
        color: isActive ? Theme.of(context).colorScheme.primary : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back button and dot indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDarkMode ? Colors.white : Colors.black54,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms),

                  // Dot indicators
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(10, (index) {
                        return Container(
                          width: index == _currentPage ? 24.0 : 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: index == _currentPage
                                ? AppColors.primaryColor
                                : isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: Duration(milliseconds: 100 + (index * 50)),
                        );
                      }),
                    ),
                  ),

                  // Empty space to balance the back button
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Small experience icon at the top
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.help_outline,
                            size: 30,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.easeOut,
                      ),

                      const SizedBox(height: 16),

                      // Title and subtitle
                      Text(
                        'Have you used nutrition\ntracking apps before?',
                        style: AppTextStyles.heading2.copyWith(
                          color: textColor,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, duration: 600.ms),

                      const SizedBox(height: 8),

                      Text(
                        'This helps us tailor the experience for you.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: subtitleColor,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms),

                      const SizedBox(height: 32),

                      // Experience options
                      _buildExperienceOption(_experienceOptions[0], _experienceOptions[0]['value'] == _selectedExperience, 0,
                        onTap: () {
                          setState(() {
                            _selectedExperience = _experienceOptions[0]['value'];
                          });
                          // Add haptic feedback
                          HapticFeedback.lightImpact();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildExperienceOption(_experienceOptions[1], _experienceOptions[1]['value'] == _selectedExperience, 1,
                        onTap: () {
                          setState(() {
                            _selectedExperience = _experienceOptions[1]['value'];
                          });
                          // Add haptic feedback
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Next button - fixed at bottom
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedExperience != null
                      ? () {
                          // Add haptic feedback
                          HapticFeedback.mediumImpact();
                          _saveExperienceAndContinue();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedExperience != null
                        ? AppColors.primaryColor
                        : isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    foregroundColor: _selectedExperience != null
                        ? Colors.white
                        : isDarkMode ? Colors.grey[600] : Colors.black54,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Next',
                          style: AppTextStyles.buttonLarge,
                        ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms, delay: 1000.ms),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExperienceAndContinue() async {
    setState(() {
      _isLoading = true;
    });

    // Add experience to user data
    final Map<String, dynamic> updatedUserData = {
      ...widget.userData ?? {},
      'experience': _selectedExperience ?? 'beginner',
    };

    // Save experience data to UserService
    final userService = UserService();
    await userService.saveUserData({
      'experience': _selectedExperience ?? 'beginner',
    });

    debugPrint('Experience saved: ${_selectedExperience ?? 'beginner'}');

    setState(() {
      _isLoading = false;
    });

    // Navigate to weight input screen using push
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WeightInputScreen(
          userData: updatedUserData,
          onNext: widget.onNext, // Pass the callback
        ),
      ),
    );
  }

  Widget _buildExperienceOption(
    Map<String, dynamic> option,
    bool isSelected,
    int index, {
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final delay = Duration(milliseconds: 600 + (index * 200));

    // Create a simpler, more reliable experience option button
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: isSelected ? 2 : 0,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          shadowColor: isSelected ? AppColors.primaryColor.withOpacity(0.3) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryColor
                  : isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.primaryColor.withOpacity(0.1),
            highlightColor: AppColors.primaryColor.withOpacity(0.05),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Experience icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.2)
                          : isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        option['icon'],
                        color: isSelected
                            ? AppColors.primaryColor
                            : isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Label and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['title'],
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option['subtitle'],
                          style: AppTextStyles.caption.copyWith(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selected indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                              width: 1,
                            ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: delay)
    .slideX(begin: 0.1, end: 0, duration: 600.ms, delay: delay);
  }


}
