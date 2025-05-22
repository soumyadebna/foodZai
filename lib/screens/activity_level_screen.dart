import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';
import '../utils/ui_components.dart';
import 'experience_screen.dart';
import '../services/user_service.dart';
import 'gender_selection_screen.dart';

class ActivityLevelScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onNext;

  const ActivityLevelScreen({Key? key, this.userData, this.onNext}) : super(key: key);

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  String? _selectedLevel;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _activityOptions = [
    {
      'value': 'beginner',
      'title': '0 - 2',
      'subtitle': 'Occasional activity',
      'icon': Icons.directions_walk,
    },
    {
      'value': 'intermediate',
      'title': '3 - 5',
      'subtitle': 'Regular weekly activity',
      'icon': Icons.directions_run,
    },
    {
      'value': 'advanced',
      'title': '6+',
      'subtitle': 'Daily fitness enthusiast',
      'icon': Icons.fitness_center,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Ensure no activity level is pre-selected by default
    setState(() {
      _selectedLevel = null;
    });
  }

  // Current page in the onboarding flow
  final int _currentPage = Constants.activityLevelScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;

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
                      // Small activity icon at the top
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
                            Icons.directions_run,
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
                        'How active are you\nper week?',
                        style: AppTextStyles.heading2.copyWith(
                          color: textColor,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, duration: 600.ms),

                      const SizedBox(height: 8),

                      Text(
                        'We\'ll use this to personalize your nutrition plan.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: subtitleColor,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms),

                      const SizedBox(height: 32),

                      // Activity level options
                      _buildActivityOption(_activityOptions[0], _activityOptions[0]['value'] == _selectedLevel, 0,
                        onTap: () {
                          setState(() {
                            _selectedLevel = _activityOptions[0]['value'];
                          });
                          // Add haptic feedback
                          HapticFeedback.lightImpact();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildActivityOption(_activityOptions[1], _activityOptions[1]['value'] == _selectedLevel, 1,
                        onTap: () {
                          setState(() {
                            _selectedLevel = _activityOptions[1]['value'];
                          });
                          // Add haptic feedback
                          HapticFeedback.lightImpact();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildActivityOption(_activityOptions[2], _activityOptions[2]['value'] == _selectedLevel, 2,
                        onTap: () {
                          setState(() {
                            _selectedLevel = _activityOptions[2]['value'];
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
                  onPressed: _selectedLevel != null
                      ? () {
                          // Add haptic feedback
                          HapticFeedback.mediumImpact();

                          setState(() {
                            _isLoading = true;
                          });

                          // Add activity level to user data
                          final Map<String, dynamic> updatedUserData = {
                            ...widget.userData ?? {},
                            'activity_level': _selectedLevel,
                          };

                          // Save activity level data to UserService
                          final userService = UserService();
                          userService.saveUserData({
                            'activity_level': _selectedLevel,
                          });

                          debugPrint('Activity level saved: $_selectedLevel');

                          setState(() {
                            _isLoading = false;
                          });

                          // Navigate to experience screen using push
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ExperienceScreen(
                                userData: updatedUserData,
                                onNext: widget.onNext,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedLevel != null
                        ? AppColors.primaryColor
                        : isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    foregroundColor: _selectedLevel != null
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

  Widget _buildActivityOption(
    Map<String, dynamic> option,
    bool isSelected,
    int index, {
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final delay = Duration(milliseconds: 600 + (index * 200));

    // Create a simpler, more reliable activity option button
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
                  // Activity icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.2)
                          : isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildActivityIcon(option, isSelected, index),
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

  Widget _buildActivityIcon(Map<String, dynamic> option, bool isSelected, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isSelected
        ? AppColors.primaryColor
        : isDarkMode ? Colors.grey[400] : Colors.grey[600];

    // Different icon layouts based on the activity level
    switch (index) {
      case 0: // Beginner - single dot
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow for selected state
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),

              // Main dot
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
              ),
            ],
          ),
        );

      case 1: // Intermediate - three dots
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 3,
                      spreadRadius: 0.5,
                    ),
                  ] : null,
                ),
              ),
            ],
          ),
        );

      case 2: // Advanced - grid of dots
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 2,
                          spreadRadius: 0.5,
                        ),
                      ] : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      default:
        return Icon(
          option['icon'],
          color: isSelected
              ? AppColors.primaryColor
              : isDarkMode ? Colors.grey[400] : Colors.grey[600],
          size: 28,
        );
    }
  }


}
