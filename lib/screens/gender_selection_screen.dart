import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../services/navigation_service.dart';
import '../utils/routes.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../utils/animations.dart';
import '../utils/ui_components.dart';
import '../models/user_model.dart';
import 'activity_level_screen.dart';

class GenderSelectionScreen extends StatefulWidget {
  final bool fromOnboarding;

  const GenderSelectionScreen({
    Key? key,
    this.fromOnboarding = true,
  }) : super(key: key);

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  String _selectedGender = ''; // Start with no selection so button is disabled
  bool _isLoading = false;
  int _currentDotIndex = 1; // For the dot indicator

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Don't pre-select gender even if it exists in user data
    // This ensures the button is disabled by default
    setState(() {
      _selectedGender = '';
    });
  }

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
    });

    // Debug log to verify selection
    debugPrint('Gender selected: $gender');

    // Force rebuild to ensure button state is updated
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveGenderAndContinue() async {
    setState(() {
      _isLoading = true;
    });

    // Save gender to user data
    await _userService.saveUserData({
      'gender': _selectedGender,
    });

    // Log the saved gender
    debugPrint('Gender saved: $_selectedGender');

    // Get the updated user data
    final user = await _userService.getUserData();
    debugPrint('Saved user data: $user');

    setState(() {
      _isLoading = false;
    });

    // Navigate to the next screen
    if (widget.fromOnboarding) {
      // Use push navigation instead of named routes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityLevelScreen(
            userData: {'gender': _selectedGender},
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
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
                      icon: Icon(Icons.arrow_back,
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
                          width: index == _currentDotIndex ? 24.0 : 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: index == _currentDotIndex
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
                      // Title with small gender icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose your\nGender',
                                  style: AppTextStyles.heading2.copyWith(
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This will be used to calibrate your nutrition plan.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Small gender icon
                          Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(left: 16, top: 8),
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
                              Icons.people_alt_outlined,
                              size: 30,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, duration: 600.ms),

                      const SizedBox(height: 32),

                      // Gender options
                      _buildGenderOption('Male', 'male', 'Optimized for male metabolism', 0),
                      const SizedBox(height: 16),
                      _buildGenderOption('Female', 'female', 'Tailored for female needs', 1),
                      const SizedBox(height: 16),
                      _buildGenderOption('Other', 'other', 'Personalized for your needs', 2),
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
                  onPressed: _selectedGender.isNotEmpty
                      ? () {
                          debugPrint('Next button pressed with gender: $_selectedGender');
                          _saveGenderAndContinue();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedGender.isNotEmpty
                        ? AppColors.primaryColor
                        : isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    foregroundColor: _selectedGender.isNotEmpty
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

  Widget _buildGenderOption(String label, String value, String description, int index) {
    final bool isSelected = _selectedGender == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final delay = Duration(milliseconds: 600 + (index * 200));

    // Create a simpler, more reliable gender option button
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          // Add haptic feedback
          HapticFeedback.lightImpact();
          _selectGender(value);

          // Debug print to verify the selection
          debugPrint('Gender option tapped: $value, isSelected: $isSelected');
        },
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
                  // Gender icon
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
                        value == 'male'
                            ? Icons.male
                            : value == 'female'
                                ? Icons.female
                                : Icons.person,
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
                          label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
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
