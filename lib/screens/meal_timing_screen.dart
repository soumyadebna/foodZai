import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import 'nutrition_plan_screen.dart';
import '../widgets/standard_button.dart';
import '../utils/navigation_helper.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';

class MealTimingScreen extends StatefulWidget {
  final VoidCallback? onNext;
  final Map<String, dynamic> userData;

  const MealTimingScreen({
    Key? key,
    this.onNext,
    required this.userData,
  }) : super(key: key);

  @override
  State<MealTimingScreen> createState() => _MealTimingScreenState();
}

class _MealTimingScreenState extends State<MealTimingScreen> with SingleTickerProviderStateMixin {
  // Current page in the onboarding flow
  final int _currentPage = Constants.mealTimingScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;
  bool _notificationsEnabled = false;

  // Meal times
  final List<MealTime> _mealTimes = [
    MealTime(name: 'Breakfast', time: null),
    MealTime(name: 'Lunch', time: null),
    MealTime(name: 'Dinner', time: null),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();

    // Initialize notification service
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      // Initialize the notification service
      await _notificationService.init();

      // Check if meal notifications are already enabled
      final enabled = await _notificationService.areMealNotificationsEnabled();

      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
        });
      }

      debugPrint('Notification service initialized, meal notifications enabled: $_notificationsEnabled');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        color: isActive ? AppColors.primaryColor : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showTimePicker(int index) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _mealTimes[index].time ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      setState(() {
        _mealTimes[index].time = pickedTime;
      });

      // Save meal time to UserService
      final mealTimesData = _mealTimes
          .where((meal) => meal.time != null)
          .map((meal) => {
                'name': meal.name,
                'time': '${meal.time!.hour}:${meal.time!.minute}',
              })
          .toList();

      await _userService.saveUserData({
        'meal_times': mealTimesData,
      });

      // Schedule meal notifications if at least one meal time is set
      if (mealTimesData.isNotEmpty) {
        try {
          // Schedule notifications with custom times
          await _notificationService.scheduleMealTimeNotificationsWithCustomTimes(
            mealTimesData.cast<Map<String, dynamic>>(),
          );

          // Update notification status
          setState(() {
            _notificationsEnabled = true;
          });

          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Meal notification set for ${_mealTimes[index].name}',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.primaryColor,
            ),
          );

          debugPrint('Meal notifications scheduled for ${_mealTimes[index].name} at ${pickedTime.format(context)}');
        } catch (e) {
          debugPrint('Error scheduling meal notifications: $e');

          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to set notification. Please try again.',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool get _canProceed {
    // Check if at least one meal time is set
    return _mealTimes.any((meal) => meal.time != null);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button and progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 20
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Progress dots
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildPageIndicator(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set reminders for your daily meals to maintain a consistent eating schedule',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: subtitleColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Meal time inputs
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: _mealTimes.length,
                itemBuilder: (context, index) {
                  return _buildMealTimeItem(
                    index,
                    isDarkMode,
                    textColor ?? Colors.black,
                    subtitleColor ?? Colors.grey[600]!,
                    cardColor ?? Colors.white)

                    .animate().fadeIn(
                      delay: Duration(milliseconds: 300 + (index * 100)),
                      duration: const Duration(milliseconds: 500),
                    );
                },
              ),
            ),

            // Skip and Next buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Skip button
                  TextButton(
                    onPressed: () {
                      // Navigate to nutrition plan screen without meal times
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => NutritionPlanScreen(
                            userData: widget.userData,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Next button
                  Expanded(
                    child: StandardButton(
                      text: 'Next',
                      onPressed: () async {
                        // Add haptic feedback
                        HapticFeedback.mediumImpact();

                        // Get meal times data
                        final mealTimesData = _mealTimes
                            .where((meal) => meal.time != null)
                            .map((meal) => {
                                  'name': meal.name,
                                  'time': '${meal.time!.hour}:${meal.time!.minute}',
                                })
                            .toList();

                        // Save meal times to user data
                        final Map<String, dynamic> updatedUserData = {
                          ...widget.userData,
                          'meal_times': mealTimesData,
                        };

                        // Schedule meal notifications if any meal times are set
                        if (mealTimesData.isNotEmpty) {
                          try {
                            // Schedule notifications with custom times
                            await _notificationService.scheduleMealTimeNotificationsWithCustomTimes(
                              mealTimesData.cast<Map<String, dynamic>>(),
                            );

                            debugPrint('Meal notifications scheduled for ${mealTimesData.length} meals');
                          } catch (e) {
                            debugPrint('Error scheduling meal notifications: $e');
                          }
                        }

                        // Also schedule water notifications
                        try {
                          await _notificationService.scheduleWaterIntakeNotifications();
                          debugPrint('Water intake notifications scheduled');
                        } catch (e) {
                          debugPrint('Error scheduling water notifications: $e');
                        }

                        // Navigate to nutrition plan screen using pushReplacement
                        // This will replace the current screen in the navigation stack
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => NutritionPlanScreen(
                              userData: updatedUserData,
                            ),
                          ),
                        );
                      },
                      isEnabled: true, // Always enabled, user can skip
                      backgroundColor: AppColors.primaryColor,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTimeItem(int index, bool isDarkMode, Color textColor, Color subtitleColor, Color cardColor) {
    final meal = _mealTimes[index];
    final timeString = meal.time != null
        ? DateFormat('h:mm a').format(DateTime(
            2022, 1, 1, meal.time!.hour, meal.time!.minute))
        : '';

    // Get meal-specific colors and icons
    final List<Color> gradientColors;
    final IconData mealIcon;
    final String mealDescription;

    switch (index) {
      case 0: // Breakfast
        gradientColors = [
          const Color(0xFFFFB74D),
          const Color(0xFFFF9800),
        ];
        mealIcon = Icons.wb_sunny_outlined;
        mealDescription = 'Morning energy boost';
        break;
      case 1: // Lunch
        gradientColors = [
          const Color(0xFFFFA726), // Light orange
          const Color(0xFFFF9800), // Orange
        ];
        mealIcon = Icons.restaurant_outlined;
        mealDescription = 'Midday refuel';
        break;
      case 2: // Dinner
        gradientColors = [
          const Color(0xFFFF5252),
          const Color(0xFFD32F2F),
        ];
        mealIcon = Icons.nightlight_outlined;
        mealDescription = 'Evening nourishment';
        break;
      default:
        gradientColors = [
          AppColors.primaryColor,
          AppColors.primaryColor.withOpacity(0.7),
        ];
        mealIcon = Icons.restaurant;
        mealDescription = 'Set your meal time';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTimePicker(index),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Meal icon with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    mealIcon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mealDescription,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                      if (meal.time != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: gradientColors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            timeString,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: gradientColors[0],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Time picker button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meal.time != null
                        ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100)
                        : AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      meal.time != null ? Icons.edit : Icons.add,
                      color: meal.time != null
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _showTimePicker(index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MealTime {
  final String name;
  TimeOfDay? time;

  MealTime({required this.name, this.time});
}
