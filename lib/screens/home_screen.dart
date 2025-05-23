import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/food_recognition_service.dart';
import '../services/notification_service.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/mango_logo.dart';
import '../widgets/enhanced_widgets.dart';
import '../utils/enhanced_animations.dart';
import 'camera_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'food_analysis_screen.dart';
import 'voice_input_screen.dart';
import '../widgets/speed_dial_fab.dart';
import '../utils/string_extensions.dart';
import '../utils/constants.dart';
import '../models/daily_nutrition.dart';
import '../utils/calculations/calorie_goal_calculator.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/water_tracking.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Enum for food input types
enum FoodInputType { camera, gallery, voice }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// Flow delegate for the animated FAB menu
class FlowMenuDelegate extends FlowDelegate {
  final bool isFabExpanded;
  final VoidCallback closeOnTap;

  FlowMenuDelegate({
    required this.isFabExpanded,
    required this.closeOnTap,
  });

  @override
  void paintChildren(FlowPaintingContext context) {
    final size = context.size;
    final xStart = size.width - 56; // FAB size
    final yStart = size.height - 56;

    // Main FAB position
    context.paintChild(
      0,
      transform: Matrix4.translationValues(xStart, yStart, 0),
    );

    if (isFabExpanded) {
      // Camera option - positioned above main FAB
      context.paintChild(
        1,
        transform: Matrix4.translationValues(
          xStart,
          yStart - 70, // Position above main FAB
          0,
        ),
        opacity: 1.0,
      );

      // Voice option - positioned to the left of main FAB
      context.paintChild(
        2,
        transform: Matrix4.translationValues(
          xStart - 70, // Position to the left of main FAB
          yStart,
          0,
        ),
        opacity: 1.0,
      );
    } else {
      // Hide the options when not expanded
      context.paintChild(
        1,
        transform: Matrix4.translationValues(xStart, yStart, 0),
        opacity: 0.0,
      );
      context.paintChild(
        2,
        transform: Matrix4.translationValues(xStart, yStart, 0),
        opacity: 0.0,
      );
    }
  }

  @override
  bool shouldRepaint(FlowMenuDelegate oldDelegate) {
    return oldDelegate.isFabExpanded != isFabExpanded;
  }
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final UserService _userService = UserService();
  final FoodRecognitionService _foodRecognitionService = FoodRecognitionService();
  final NotificationService _notificationService = NotificationService();
  UserModel? _user;
  List<FoodItem> _recentFoodItems = [];
  DailyNutrition? _dailyNutrition;

  // Loading state to prevent multiple actions and show loading indicators
  bool _isLoading = true;

  String weightGoal = 'maintain';
  int caloriesTotal = 2000;
  int caloriesConsumed = 0;
  int caloriesLeft = 2000;
  DateTime _selectedDate = DateTime.now();
  int waterIntake = 0;
  int waterGoal = 12;
  bool waterNotificationsEnabled = false;
  bool mealNotificationsEnabled = false;
  late AnimationController _animationController;

  // Meal notification times
  List<MealTime> _mealTimes = [
    MealTime(name: 'Breakfast', time: null),
    MealTime(name: 'Lunch', time: null),
    MealTime(name: 'Dinner', time: null),
    MealTime(name: 'Snack', time: null),
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _refreshTimer; // Timer for periodic data refresh

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadUserData();
    _loadWaterData();
    _loadNotificationSettings();
    _animationController.forward();

    // Set up a timer to refresh data periodically (every 60 seconds)
    // This reduces unnecessary refreshes while still keeping data updated
    // Store the timer so we can cancel it properly in dispose
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        debugPrint('Periodic refresh timer triggered');
        // Only refresh if the app is in the foreground
        if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
          _loadUserData();
        } else {
          debugPrint('App not in foreground, skipping refresh');
        }
      } else {
        timer.cancel();
        debugPrint('Timer cancelled because widget is not mounted');
      }
    });

    // Add post-frame callback to set up nutrition provider listener
    // This ensures the widget is fully built before accessing the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only add the listener if the widget is still mounted
      if (mounted) {
        try {
          // Listen for changes in nutrition data
          final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
          // Remove any existing listener first to avoid duplicates
          nutritionProvider.removeListener(_refreshData);
          // Add the listener
          nutritionProvider.addListener(_refreshData);
          debugPrint('Successfully added nutrition provider listener');
        } catch (e) {
          debugPrint('Error setting up nutrition provider listener: $e');
        }
      }
    });
  }

  // Refresh data when nutrition changes
  void _refreshData() {
    debugPrint('Nutrition provider notified changes');
    if (mounted) {
      // Use a debounce mechanism to prevent multiple rapid refreshes
      // This is important because the nutrition provider might notify multiple times in quick succession
      if (_debounceTimer?.isActive ?? false) {
        _debounceTimer!.cancel();
      }

      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        debugPrint('Debounce timer completed, refreshing home screen data');
        _loadUserData();
      });
    }
  }

  // Timer for debouncing refreshes
  Timer? _debounceTimer;

  Future<void> _loadWaterData() async {
    try {
      final today = DateTime.now();
      final intake = await WaterTracking.getWaterIntake(today);
      final goal = await WaterTracking.getWaterGoal();

      if (mounted) {
        setState(() {
          waterIntake = intake;
          waterGoal = goal;
        });
      }
    } catch (e) {
      print('Error loading water data: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final waterEnabled = await _notificationService.areWaterNotificationsEnabled();
      final mealEnabled = await _notificationService.areMealNotificationsEnabled();

      if (mounted) {
        setState(() {
          waterNotificationsEnabled = waterEnabled;
          mealNotificationsEnabled = mealEnabled;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  @override
  void dispose() {
    // Cancel all timers
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      debugPrint('Refresh timer cancelled in dispose');
    }

    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
      debugPrint('Debounce timer cancelled in dispose');
    }

    // Remove nutrition provider listener safely
    try {
      // Check if the widget is still mounted before accessing the context
      if (mounted) {
        // Use a try-catch to handle the case where the provider is not available
        try {
          final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
          nutritionProvider.removeListener(_refreshData);
          debugPrint('Successfully removed nutrition provider listener');
        } catch (e) {
          debugPrint('Provider not available when removing listener: $e');
        }
      }
    } catch (e) {
      debugPrint('Error removing nutrition provider listener: $e');
    }

    // Always dispose the animation controller
    _animationController.dispose();

    super.dispose();
  }



  // Track the last time data was loaded to prevent too frequent refreshes
  DateTime _lastLoadTime = DateTime.now().subtract(const Duration(minutes: 5));

  Future<void> _loadUserData() async {
    // Check if data was loaded recently (within the last 10 seconds)
    // This prevents multiple rapid refreshes that can happen due to various events
    final now = DateTime.now();
    if (now.difference(_lastLoadTime).inSeconds < 10) {
      debugPrint('Skipping data load - last load was ${now.difference(_lastLoadTime).inSeconds} seconds ago');
      return;
    }

    // Update the last load time
    _lastLoadTime = now;

    // Only show loading indicator on initial load, not on refreshes
    if (_user == null) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load data in parallel for better performance
      final userFuture = _userService.getUserData();
      final recentFoodItemsFuture = _foodRecognitionService.getRecentFoodItems();

      // Get nutrition provider
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      final dailyNutritionFuture = nutritionProvider.getDailyNutrition(_selectedDate);

      // Wait for all futures to complete
      final results = await Future.wait([
        userFuture,
        recentFoodItemsFuture,
        dailyNutritionFuture,
      ]);

      final user = results[0] as UserModel?;
      final recentFoodItems = results[1] as List<FoodItem>;
      final dailyNutrition = results[2] as DailyNutrition;

      // Remove duplicate food items from daily nutrition
      if (dailyNutrition.foodItems.isNotEmpty) {
        final uniqueFoodItems = _removeDuplicateFoodItems(dailyNutrition.foodItems);
        if (uniqueFoodItems.length < dailyNutrition.foodItems.length) {
          debugPrint('Removed ${dailyNutrition.foodItems.length - uniqueFoodItems.length} duplicate food items');
          // Update the daily nutrition with unique food items
          dailyNutrition.foodItems = uniqueFoodItems;
          // Recalculate nutrition totals
          dailyNutrition.recalculateNutrition();
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _recentFoodItems = recentFoodItems;
          _dailyNutrition = dailyNutrition;

          // Set weight goal
          weightGoal = user?.weightGoal ?? 'maintain';

          // Set calories
          caloriesTotal = nutritionProvider.calorieGoal;
          caloriesConsumed = dailyNutrition.consumedCalories.toInt();
          caloriesLeft = caloriesTotal - caloriesConsumed;
          if (caloriesLeft < 0) caloriesLeft = 0;

          _isLoading = false;
        });

        debugPrint('Data loaded successfully - Calories: $caloriesConsumed/$caloriesTotal');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to remove duplicate food items
  List<FoodItem> _removeDuplicateFoodItems(List<FoodItem> foodItems) {
    final uniqueFoodItems = <FoodItem>[];
    final seenItems = <String>{};

    for (final food in foodItems) {
      // Create a unique key for each food item
      final key = '${food.name}_${food.calories}_${food.timestamp.millisecondsSinceEpoch}';
      if (!seenItems.contains(key)) {
        seenItems.add(key);
        uniqueFoodItems.add(food);
      } else {
        debugPrint('Removed duplicate food item: ${food.name}');
      }
    }

    return uniqueFoodItems;
  }

  // Load meal notification times from user data
  Future<void> _loadMealNotificationTimes() async {
    try {
      if (_user == null) return;

      // Get meal times from user data
      final mealTimesData = _user!.mealTimes;
      if (mealTimesData == null || mealTimesData.isEmpty) return;

      // Update meal times
      for (final mealTimeData in mealTimesData) {
        final name = mealTimeData['name'] as String;
        final timeString = mealTimeData['time'] as String;

        // Parse time string (format: "hour:minute")
        final timeParts = timeString.split(':');
        if (timeParts.length != 2) continue;

        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);

        if (hour == null || minute == null) continue;

        // Find the meal time in the list
        final index = _mealTimes.indexWhere((meal) => meal.name.toLowerCase() == name.toLowerCase());
        if (index != -1) {
          setState(() {
            _mealTimes[index].time = TimeOfDay(hour: hour, minute: minute);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading meal notification times: $e');
    }
  }

  // Save meal times to user data
  Future<void> _saveMealTimes() async {
    try {
      // Get meal times data
      final mealTimesData = _mealTimes
          .where((meal) => meal.time != null)
          .map((meal) => {
                'name': meal.name,
                'time': '${meal.time!.hour}:${meal.time!.minute}',
              })
          .toList();

      // Save meal times to user data
      await _userService.saveUserData({
        'meal_times': mealTimesData,
      });

      debugPrint('Meal times saved: $mealTimesData');
    } catch (e) {
      debugPrint('Error saving meal times: $e');
    }
  }

  // Schedule meal notifications
  Future<void> _scheduleMealNotifications() async {
    try {
      // Get meal times data
      final mealTimesData = _mealTimes
          .where((meal) => meal.time != null)
          .map((meal) => {
                'name': meal.name,
                'time': '${meal.time!.hour}:${meal.time!.minute}',
              })
          .toList();

      // Schedule notifications
      if (mealTimesData.isNotEmpty) {
        await _notificationService.scheduleMealTimeNotificationsWithCustomTimes(
          mealTimesData.cast<Map<String, dynamic>>(),
        );

        // Update notification status
        setState(() {
          mealNotificationsEnabled = true;
        });

        debugPrint('Meal notifications scheduled for ${mealTimesData.length} meals');
      }
    } catch (e) {
      debugPrint('Error scheduling meal notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        // Use SafeArea to handle notches and system UI elements
        top: false, // Don't add padding at the top since we handle it manually
        bottom: false, // Don't add padding at the bottom since we have a bottom nav bar
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading your nutrition data...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                  ],
                ).animate().fadeIn(
                      duration: EnhancedAnimations.medium,
                      curve: EnhancedAnimations.standardCurve,
                    ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildBody(),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Add haptic feedback
          HapticFeedback.lightImpact();

          setState(() {
            _currentIndex = index;
          });
        },
      ),
      // Always show FAB on home tab to ensure functionality
      floatingActionButton: _currentIndex == 0
          ? _buildAnimatedFab()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Show meal time picker dialog
  void _showMealTimePickerDialog(String mealType) {
    // Find the meal time in the list
    final mealTimeIndex = _mealTimes.indexWhere((meal) => meal.name.toLowerCase() == mealType.toLowerCase());
    if (mealTimeIndex == -1) return;

    final mealTime = _mealTimes[mealTimeIndex];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasNotification = mealTime.time != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    '$mealType Notification',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current notification time
                  if (hasNotification) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Notification',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Set for ${mealTime.time!.format(context)} daily',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              // Remove notification time
                              setState(() {
                                mealTime.time = null;
                              });

                              // Update in parent widget
                              this.setState(() {});

                              // Save to user data
                              await _saveMealTimes();
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Set new time button
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Show time picker
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: mealTime.time ?? TimeOfDay.now(),
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

                        // Update time
                        setState(() {
                          mealTime.time = pickedTime;
                        });

                        // Update in parent widget
                        this.setState(() {});

                        // Save to user data
                        await _saveMealTimes();

                        // Schedule notifications
                        await _scheduleMealNotifications();

                        // Show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Meal notification set for ${mealType} at ${pickedTime.format(context)}',
                              style: GoogleFonts.poppins(),
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.primaryColor,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      hasNotification ? Icons.edit : Icons.add,
                      color: Colors.white,
                    ),
                    label: Text(
                      hasNotification ? 'Change Time' : 'Set Notification Time',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showAddFoodOptions({String? selectedMealType, FoodInputType? inputType}) {
    // Automatically determine meal type based on time if not specified
    final mealType = selectedMealType ?? _getCurrentMealType();

    // If input type is specified, navigate directly to that input method
    if (inputType != null) {
      switch (inputType) {
        case FoodInputType.camera:
          _navigateToCamera(ImageSource.camera, mealType);
          return;
        case FoodInputType.gallery:
          _navigateToCamera(ImageSource.gallery, mealType);
          return;
        case FoodInputType.voice:
          _navigateToVoiceInput(mealType);
          return;
      }
    }

    // Show options to take photo, select from gallery, or use voice input
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title with "Add Food" and meal type indicator
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Food',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCurrentMealTypeIndicator(mealType),
                ],
              ),

              const SizedBox(height: 24),

              // Camera and gallery options
              Row(
                children: [
                  Expanded(
                    child: _buildAddFoodOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToCamera(ImageSource.camera, mealType);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAddFoodOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToCamera(ImageSource.gallery, mealType);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Voice input option
              _buildAddFoodOption(
                icon: Icons.mic_rounded,
                label: 'Voice Input',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToVoiceInput(mealType);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Helper to show the current meal type with appropriate icon
  Widget _buildCurrentMealTypeIndicator(String mealType) {
    IconData icon;
    Color color;

    switch (mealType) {
      case 'Breakfast':
        icon = Icons.wb_sunny_rounded;
        color = Colors.orange;
        break;
      case 'Lunch':
        icon = Icons.lunch_dining_rounded;
        color = Colors.green;
        break;
      case 'Dinner':
        icon = Icons.dinner_dining_rounded;
        color = Colors.purple;
        break;
      default: // Snack
        icon = Icons.icecream_rounded;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            mealType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeOption(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddFoodOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Determine the current meal type based on time of day
  String _getCurrentMealType() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      return 'Breakfast';
    } else if (hour >= 11 && hour < 16) {
      return 'Lunch';
    } else if (hour >= 16 && hour < 22) {
      return 'Dinner';
    } else {
      return 'Snack';
    }
  }

  Future<void> _navigateToCamera(ImageSource source, String? mealType) async {
    // Prevent multiple taps
    if (_isLoading) {
      debugPrint('Navigation prevented: app is loading data');
      return;
    }

    // Set loading state to prevent multiple taps
    setState(() {
      _isLoading = true;
    });

    try {
      // If meal type is not provided, determine it based on current time
      final effectiveMealType = mealType ?? _getCurrentMealType();

      // Get the appropriate image source
      final ImagePicker picker = ImagePicker();

      // Use the appropriate method based on the source
      XFile? image;

      try {
        // Add haptic feedback
        HapticFeedback.mediumImpact();

        // Pick image with proper error handling
        image = await picker.pickImage(
          source: source,
          imageQuality: 85, // Slightly compress for better performance
          maxWidth: 1200,   // Limit size for better performance
          maxHeight: 1200,  // Limit size for better performance
        );
      } catch (e) {
        debugPrint('Error picking image: $e');

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error accessing ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } finally {
        // Reset loading state
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }

      // Process the image if selected
      if (image != null) {
        if (mounted) {
          _navigateToFoodAnalysis(File(image.path), effectiveMealType);
        }
      } else {
        debugPrint('No image selected');
      }
    } catch (e) {
      debugPrint('Error in _navigateToCamera: $e');

      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToFoodAnalysis(File imageFile, String mealType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodAnalysisScreen(
          imageFile: imageFile,
          mealType: mealType,
          onFoodAdded: () {
            // Refresh data on the home screen
            // This will be called when food is added
            _loadUserData();
          },
        ),
      ),
    );
    // Removed the .then(_loadUserData) to prevent double loading
  }

  Future<void> _navigateToVoiceInput(String mealType) async {
    // Prevent multiple taps
    if (_isLoading) {
      debugPrint('Navigation prevented: app is loading data');
      return;
    }

    // Set loading state to prevent multiple taps
    setState(() {
      _isLoading = true;
    });

    try {
      // Add haptic feedback
      HapticFeedback.mediumImpact();

      if (mounted) {
        // Navigate to voice input screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceInputScreen(
              mealType: mealType,
              onFoodAdded: () {
                // Refresh data on the home screen
                // This will be called when food is added
                _loadUserData();
              },
            ),
          ),
        );

        // Handle result if needed
        if (result == true) {
          debugPrint('Food added successfully via voice input');
          // Refresh data
          _loadUserData();
        }
      }
    } catch (e) {
      debugPrint('Error navigating to voice input: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error accessing voice input: $e',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAnimatedFab() {
    // Get the theme's color scheme for Material 3 design
    final colorScheme = Theme.of(context).colorScheme;

    // Use a custom purple color that matches the app's theme
    final fabColor = AppColors.primaryColor;

    return SpeedDialFab(
      onCameraSelected: () {
        if (_isLoading) {
          // Prevent navigation while loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait while data is loading...',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // Add haptic feedback
        HapticFeedback.mediumImpact();

        // Navigate with a slight delay to allow animation to complete
        Future.delayed(const Duration(milliseconds: 50), () {
          _navigateToCamera(ImageSource.camera, _getCurrentMealType());
        });
      },
      onGallerySelected: () {
        if (_isLoading) {
          // Prevent navigation while loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait while data is loading...',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // Add haptic feedback
        HapticFeedback.mediumImpact();

        // Navigate with a slight delay to allow animation to complete
        Future.delayed(const Duration(milliseconds: 50), () {
          _navigateToCamera(ImageSource.gallery, _getCurrentMealType());
        });
      },
      onVoiceSelected: () {
        if (_isLoading) {
          // Prevent navigation while loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait while data is loading...',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // Add haptic feedback
        HapticFeedback.mediumImpact();

        // Navigate with a slight delay to allow animation to complete
        Future.delayed(const Duration(milliseconds: 50), () {
          _navigateToVoiceInput(_getCurrentMealType());
        });
      },
      backgroundColor: fabColor, // Use custom purple color
      textColor: Colors.white,
    );
  }

  // Reference to the enum for food input types

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return AnalyticsScreen();
      case 2:
        return SettingsScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildAppBar(textColor ?? Colors.black, isDarkMode),
        ),
        SliverToBoxAdapter(
          child: _buildDateSelector(),
        ),
        SliverToBoxAdapter(
          child: _buildTabContent(textColor ?? Colors.black, subtitleColor ?? Colors.grey[600]!, isDarkMode),
        ),
        SliverToBoxAdapter(
          child: const SizedBox(height: 100), // Space for FAB
        ),
      ],
    );
  }

  Widget _buildAppBar(Color textColor, bool isDarkMode) {
    // Add extra padding at the top to account for the notch
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.0, // Add safe area padding
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),
      child: Row(
        children: [
          // Logo and app name
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/mango_icon.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FoodAI',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Notification and profile buttons
          Row(
            children: [
              // Notification button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
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
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Show notifications
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No new notifications',
                          style: GoogleFonts.poppins(),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDarkMode ? Colors.white : Colors.black54,
                ),
              ),

              const SizedBox(width: 12),

              // Profile button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
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
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
                      ),
                    ).then((_) => _loadUserData());
                  },
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDarkMode ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Selected date for the home screen

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;

    // Generate days for the week (Monday to Sunday)
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final dayNumbers = List.generate(7, (index) {
      final day = firstDayOfWeek.add(Duration(days: index));
      return day;
    });

    // Calculate selected day index
    int selectedDayIndex = 0;
    for (int i = 0; i < dayNumbers.length; i++) {
      if (dayNumbers[i].day == _selectedDate.day &&
          dayNumbers[i].month == _selectedDate.month &&
          dayNumbers[i].year == _selectedDate.year) {
        selectedDayIndex = i;
        break;
      }
    }

    return Column(
      children: [
        // Date header with arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 28,
                  color: textColor,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    _loadUserData(); // Reload data for the selected date
                  });
                },
              ),
              Text(
                _selectedDate.day == now.day &&
                _selectedDate.month == now.month &&
                _selectedDate.year == now.year
                    ? 'TODAY, ${DateFormat('d MMM').format(_selectedDate)}'
                    : DateFormat('EEE, d MMM').format(_selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: textColor,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                    _loadUserData(); // Reload data for the selected date
                  });
                },
              ),
            ],
          ),
        ),

        // Day selector (Monday to Sunday)
        Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              final isSelected = index == selectedDayIndex;
              final date = dayNumbers[index];
              final isToday = date.day == now.day &&
                             date.month == now.month &&
                             date.year == now.year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _loadUserData(); // Reload data for the selected date
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : backgroundColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        days[index],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primaryColor
                                  : subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primaryColor
                                  : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab content with multiple views
  Widget _buildTabContent(Color textColor, Color subtitleColor, bool isDarkMode) {
    // Create a PageView with sections in the requested order
    return Column(
      children: [
        // Calories circle section (at the top)
        _buildCaloriesCounter(textColor, subtitleColor, isDarkMode),

        // Macronutrients section
        _buildMacronutrientsSection(textColor, subtitleColor, isDarkMode),

        // Water tracking
        _buildWaterTracker(textColor, subtitleColor, isDarkMode),

        // Meal times section
        _buildMealTimesSection(textColor, subtitleColor, isDarkMode),
      ],
    );
  }

  Widget _buildWaterTracker(Color textColor, Color subtitleColor, bool isDarkMode) {
    // Material 3 color scheme
    final colorScheme = Theme.of(context).colorScheme;
    final waterColor = Color(0xFF2196F3); // Material blue
    final progressValue = waterIntake / waterGoal;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: waterColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: waterColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Water Intake',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Notification toggle button - using standard IconButton for compatibility
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _toggleWaterNotifications();
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: waterNotificationsEnabled
                                ? waterColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            waterNotificationsEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_outlined,
                            color: waterColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reset button - using standard approach for compatibility
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _resetWaterIntake();
                          HapticFeedback.mediumImpact();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: subtitleColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 20),

            // Progress indicator with text - Material 3 design
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Water icon with animation
                  Icon(
                    Icons.water_drop_rounded,
                    color: waterColor,
                    size: 24,
                  ).animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.2, 1.2),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                  ),
                  const SizedBox(width: 12),
                  // Water count
                  Text(
                    '$waterIntake/$waterGoal',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: waterColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'glasses',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  const Spacer(),
                  // Percentage chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: waterColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(progressValue * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: waterColor,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            ).slideY(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 16),

            // Water progress bar with Material 3 design
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progressValue),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: waterColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(waterColor),
                    minHeight: 16,
                  );
                },
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 24),

            // Water droplets with Material 3 design
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: List.generate(waterGoal, (index) {
                  final bool filled = index < waterIntake;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _updateWaterIntake(index + 1);
                        HapticFeedback.lightImpact();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: filled
                              ? waterColor.withOpacity(0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.water_drop_rounded,
                          color: filled ? waterColor : waterColor.withOpacity(0.3),
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 16),

            // Quick add/remove buttons with Material 3 design
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Remove button
                FilledButton.tonalIcon(
                  onPressed: waterIntake > 0
                      ? () {
                          _updateWaterIntake(waterIntake - 1);
                          HapticFeedback.lightImpact();
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove'),
                  style: FilledButton.styleFrom(
                    backgroundColor: waterColor.withOpacity(0.1),
                    foregroundColor: waterColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Add button
                FilledButton.icon(
                  onPressed: () {
                    _updateWaterIntake(waterIntake + 1);
                    HapticFeedback.mediumImpact();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    backgroundColor: waterColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 16),

            // Reminder text with Material 3 design
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: waterNotificationsEnabled
                      ? waterColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: waterNotificationsEnabled
                        ? waterColor.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      waterNotificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      color: waterNotificationsEnabled ? waterColor : subtitleColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      waterNotificationsEnabled
                          ? 'Reminders every 30 minutes'
                          : 'Reminders disabled',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: waterNotificationsEnabled ? waterColor : subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            ),

            // Achievement message if goal reached
            if (progressValue >= 1.0)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal Achieved!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Great job staying hydrated today.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
              ).slideY(
                begin: 0.2,
                end: 0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleWaterNotifications() async {
    try {
      // Set loading state to prevent multiple taps
      setState(() {
        _isLoading = true;
      });

      // Add debug log
      debugPrint('Toggling water notifications. Current state: $waterNotificationsEnabled');

      // Toggle notifications with proper error handling
      bool success = false;

      if (waterNotificationsEnabled) {
        // Cancel notifications
        debugPrint('Attempting to cancel water notifications');
        success = await _notificationService.cancelWaterNotifications();
        debugPrint('Cancel water notifications result: $success');
        if (success) {
          setState(() {
            waterNotificationsEnabled = false;
          });
        }
      } else {
        // Schedule notifications
        debugPrint('Attempting to schedule water notifications');
        success = await _notificationService.scheduleWaterIntakeNotifications();
        debugPrint('Schedule water notifications result: $success');
        if (success) {
          setState(() {
            waterNotificationsEnabled = true;
          });
        }
      }

      // Save the notification state to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('water_notifications_enabled', waterNotificationsEnabled);
      debugPrint('Saved water notifications state to preferences: $waterNotificationsEnabled');

      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (waterNotificationsEnabled
                      ? 'Water reminders enabled'
                      : 'Water reminders disabled')
                  : 'Failed to update notification settings',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling water notifications: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating notification settings',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetWaterIntake() async {
    try {
      final today = DateTime.now();
      await WaterTracking.resetWaterIntake(today);

      setState(() {
        waterIntake = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Water intake reset',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error resetting water intake: $e');
    }
  }

  Future<void> _updateWaterIntake(int count) async {
    try {
      final today = DateTime.now();
      await WaterTracking.setWaterIntake(today, count);

      setState(() {
        waterIntake = count;
      });
    } catch (e) {
      print('Error updating water intake: $e');
    }
  }

  Widget _buildMacronutrientsSection(Color textColor, Color subtitleColor, bool isDarkMode) {
    // Material 3 color scheme
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = colorScheme.surface;
    final surfaceContainerColor = colorScheme.surfaceContainer;

    // Get target macros from daily nutrition or use defaults
    final targetCarbs = _dailyNutrition?.targetCarbs.toInt() ?? 270;
    final targetProtein = _dailyNutrition?.targetProtein.toInt() ?? 135;
    final targetFat = _dailyNutrition?.targetFat.toInt() ?? 60;

    // Get consumed macros (always use actual data, never fake values)
    final consumedCarbs = _dailyNutrition?.consumedCarbs.toInt() ?? 0;
    final consumedProtein = _dailyNutrition?.consumedProtein.toInt() ?? 0;
    final consumedFat = _dailyNutrition?.consumedFat.toInt() ?? 0;

    // Calculate percentages (avoid division by zero)
    final carbsPercentage = targetCarbs > 0 ? (consumedCarbs / targetCarbs).clamp(0.0, 1.0) : 0.0;
    final proteinPercentage = targetProtein > 0 ? (consumedProtein / targetProtein).clamp(0.0, 1.0) : 0.0;
    final fatPercentage = targetFat > 0 ? (consumedFat / targetFat).clamp(0.0, 1.0) : 0.0;

    // Material 3 colors for macronutrients
    final carbsColor = colorScheme.tertiary;
    final proteinColor = colorScheme.primary;
    final fatColor = colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Macronutrients',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 24),

            // Macronutrient progress bars with staggered animations
            _buildMacronutrientProgressBar(
              'Carbs',
              '$consumedCarbs/${targetCarbs}g',
              carbsPercentage,
              carbsColor,
              textColor,
              subtitleColor,
              0
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            ).slideX(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 16),

            _buildMacronutrientProgressBar(
              'Protein',
              '$consumedProtein/${targetProtein}g',
              proteinPercentage,
              proteinColor,
              textColor,
              subtitleColor,
              1
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ).slideX(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            ),

            const SizedBox(height: 16),

            _buildMacronutrientProgressBar(
              'Fat',
              '$consumedFat/${targetFat}g',
              fatPercentage,
              fatColor,
              textColor,
              subtitleColor,
              2
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ).slideX(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),

            // Information tooltip
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextButton.icon(
                  onPressed: () {
                    // Show information about macronutrients
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'About Macronutrients',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMacroInfo('Carbs', 'Provide energy (4 calories per gram)', carbsColor),
                            const SizedBox(height: 8),
                            _buildMacroInfo('Protein', 'Builds muscle and tissue (4 calories per gram)', proteinColor),
                            const SizedBox(height: 8),
                            _buildMacroInfo('Fat', 'Supports cell growth (9 calories per gram)', fatColor),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Got it',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                  label: Text(
                    'Learn about macros',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 400),
              delay: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacronutrientProgressBar(
    String label,
    String value,
    double progress,
    Color color,
    Color textColor,
    Color subtitleColor,
    int index
  ) {
    final percentage = (progress * 100).toInt();
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add haptic feedback
          HapticFeedback.lightImpact();

          // Show detailed information
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$label: $value ($percentage% of daily goal)',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$percentage%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Material 3 LinearProgressIndicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(8),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PageController for Today's Meals and Today's Diary
  final PageController _mealsPageController = PageController();
  int _currentMealsPage = 0;

  Widget _buildMealTimesSection(Color textColor, Color subtitleColor, bool isDarkMode) {
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;

    // Group food items by meal type
    final Map<String, List<FoodItem>> mealGroups = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snacks': [],
    };

    // Get selected date's food items
    final selectedDateStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final selectedDateEnd = selectedDateStart.add(const Duration(days: 1));

    // Use food items from daily nutrition if available
    final selectedDateFoodItems = _dailyNutrition?.foodItems ?? [];

    // Group food items by meal type (case insensitive)
    for (final food in selectedDateFoodItems) {
      final mealType = food.mealType.toLowerCase();
      if (mealType.contains('breakfast')) {
        mealGroups['Breakfast']!.add(food);
      } else if (mealType.contains('lunch')) {
        mealGroups['Lunch']!.add(food);
      } else if (mealType.contains('dinner')) {
        mealGroups['Dinner']!.add(food);
      } else {
        mealGroups['Snacks']!.add(food);
      }
    }

    // Load meal notification times
    _loadMealNotificationTimes();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _currentMealsPage == 0 ? Icons.book : Icons.restaurant_menu,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currentMealsPage == 0 ? 'Today\'s Diary' : 'Today\'s Meals',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                // Page indicator dots
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _mealsPageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentMealsPage == 0
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _mealsPageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentMealsPage == 1
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            // height: 350, // Fixed height for the PageView - REMOVED
            child: PageView(
              controller: _mealsPageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentMealsPage = index;
                });
              },
              children: [
                // Today's Diary page (now first)
                _buildTodaysDiarySection(backgroundColor, textColor, subtitleColor, selectedDateFoodItems),

                // Today's Meals page (now second)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSimpleMealRow(
                        'Breakfast',
                        Icons.wb_sunny_rounded,
                        Colors.orange,
                        'Recommended 300-450 kcal',
                        mealGroups['Breakfast']!,
                        textColor,
                        subtitleColor,
                      ),
                      const Divider(height: 32),
                      _buildSimpleMealRow(
                        'Lunch',
                        Icons.lunch_dining_rounded,
                        Colors.green,
                        'Recommended 450-600 kcal',
                        mealGroups['Lunch']!,
                        textColor,
                        subtitleColor,
                      ),
                      const Divider(height: 32),
                      _buildSimpleMealRow(
                        'Dinner',
                        Icons.dinner_dining_rounded,
                        Colors.purple,
                        'Recommended 450-600 kcal',
                        mealGroups['Dinner']!,
                        textColor,
                        subtitleColor,
                      ),
                      const Divider(height: 32),
                      _buildSimpleMealRow(
                        'Snacks',
                        Icons.icecream_rounded,
                        Colors.red,
                        'Recommended 75-150 kcal',
                        mealGroups['Snacks']!,
                        textColor,
                        subtitleColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the Today's Diary section
  Widget _buildTodaysDiarySection(Color? backgroundColor, Color textColor, Color subtitleColor, List<FoodItem> foodItems) {
    if (foodItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: subtitleColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No food entries yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your food diary will show all the foods you\'ve added today',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showAddFoodOptions();
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Add Food',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Sort food items by timestamp (newest first)
    final sortedFoodItems = List<FoodItem>.from(foodItems)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Remove duplicates by comparing name, calories, and timestamp
    final uniqueFoodItems = <FoodItem>[];
    final seenItems = <String>{};

    for (final food in sortedFoodItems) {
      // Create a unique key for each food item
      final key = '${food.name}_${food.calories}_${food.timestamp.millisecondsSinceEpoch}';
      if (!seenItems.contains(key)) {
        seenItems.add(key);
        uniqueFoodItems.add(food);
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: uniqueFoodItems.length,
        itemBuilder: (context, index) {
          final food = uniqueFoodItems[index];
          return _buildDiaryFoodItem(food, textColor, subtitleColor);
        },
      ),
    );
  }

  // Build a food item for the diary
  Widget _buildDiaryFoodItem(FoodItem food, Color textColor, Color subtitleColor) {
    final timeString = DateFormat('h:mm a').format(food.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image or icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getMealTypeColor(food.mealType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              image: food.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: FileImage(File(food.imageUrl)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: food.imageUrl.isEmpty
                ? Icon(
                    _getMealTypeIcon(food.mealType),
                    color: _getMealTypeColor(food.mealType),
                    size: 24,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        food.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${food.calories} kcal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  food.portion,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getMealTypeColor(food.mealType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            food.mealType,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getMealTypeColor(food.mealType),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeString,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        _buildMacroIndicator('P', food.protein.toInt(), Colors.red),
                        const SizedBox(width: 4),
                        _buildMacroIndicator('C', food.carbs.toInt(), Colors.green),
                        const SizedBox(width: 4),
                        _buildMacroIndicator('F', food.fat.toInt(), Colors.blue),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get meal type color
  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.purple;
      default: // Snack
        return Colors.red;
    }
  }

  // Helper method to get meal type icon
  IconData _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      default: // Snack
        return Icons.icecream_rounded;
    }
  }

  // Build a macro indicator badge
  Widget _buildMacroIndicator(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:$value',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSimpleMealRow(
    String mealType,
    IconData icon,
    Color iconColor,
    String recommendation,
    List<FoodItem> foodItems,
    Color textColor,
    Color subtitleColor,
  ) {
    // Calculate total calories for this meal
    int totalCalories = 0;
    for (final food in foodItems) {
      totalCalories += food.calories.toInt();
    }

    // Determine if meal is completed (has food items)
    final bool isMealCompleted = foodItems.isNotEmpty;

    // Get recommended calories based on meal type
    int recommendedCalories = 0;
    switch (mealType) {
      case 'Breakfast':
        recommendedCalories = 400; // Average of 300-450
        break;
      case 'Lunch':
        recommendedCalories = 525; // Average of 450-600
        break;
      case 'Dinner':
        recommendedCalories = 525; // Average of 450-600
        break;
      case 'Snacks':
        recommendedCalories = 125; // Average of 75-150
        break;
    }

    // Calculate percentage of recommended calories
    final double percentage = recommendedCalories > 0 ?
        (totalCalories / recommendedCalories).clamp(0.0, 1.0) : 0.0;

    // Determine if meal is on track (within 80-120% of recommended)
    final bool isOnTrack = percentage >= 0.8 && percentage <= 1.2;

    // Find the meal time in the list
    final mealTimeIndex = _mealTimes.indexWhere((meal) => meal.name.toLowerCase() == mealType.toLowerCase());
    final mealTime = mealTimeIndex != -1 ? _mealTimes[mealTimeIndex] : null;
    final hasNotification = mealTime?.time != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            if (isMealCompleted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isOnTrack ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    mealType,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (isMealCompleted)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnTrack ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOnTrack ? 'On Track' : 'Logged',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isOnTrack ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  if (hasNotification) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 12,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mealTime!.time!.format(context),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                foodItems.isNotEmpty
                    ? '$totalCalories / $recommendedCalories kcal'
                    : recommendation,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),

        // Notification time button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showMealTimePickerDialog(mealType);
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasNotification
                    ? AppColors.primaryColor.withOpacity(0.2)
                    : (isDarkMode ? Colors.grey[800] : Colors.grey[200])!.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasNotification ? Icons.notifications_active : Icons.notifications_none,
                color: hasNotification ? AppColors.primaryColor : (isDarkMode ? Colors.white70 : Colors.black54),
                size: 20,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Add food button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Show add food options with this meal type
              _showAddFoodOptions(selectedMealType: mealType);
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTimeItem({
    required IconData icon,
    required String mealType,
    required String calories,
    required Color textColor,
    required Color subtitleColor,
    required Color? backgroundColor,
    required List<FoodItem> foodItems,
    required Color iconColor,
  }) {
    // Calculate total calories for this meal
    int totalCalories = 0;
    for (final food in foodItems) {
      totalCalories += food.calories.toInt();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: iconColor.withOpacity(0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          foodItems.isEmpty
                              ? calories
                              : '$totalCalories kcal consumed',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Show add food options with this meal type
                    _showAddFoodOptions(selectedMealType: mealType);
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Show food items if any
          if (foodItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: foodItems.length,
                itemBuilder: (context, index) {
                  final food = foodItems[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: food.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(food.imageUrl)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Food info
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name.capitalize(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange[300],
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${food.calories.toInt()} kcal',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    _buildNutrientBadge('P', food.protein.toInt(), Colors.red[300]!),
                                    const SizedBox(width: 4),
                                    _buildNutrientBadge('C', food.carbs.toInt(), Colors.green[300]!),
                                    const SizedBox(width: 4),
                                    _buildNutrientBadge('F', food.fat.toInt(), Colors.blue[300]!),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Delete button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Show delete confirmation
                                _showDeleteFoodConfirmation(food);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // Empty state
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant,
                    color: subtitleColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No food added yet',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add food',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: subtitleColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteFoodConfirmation(FoodItem food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Food',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${food.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () {
              // Remove food item
              _dailyNutrition?.removeFoodItem(food);
              _loadUserData();
              Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCounter(Color textColor, Color subtitleColor, bool isDarkMode) {
    // Get current weight and goal weight from user data (use actual user data)
    final currentWeight = _user?.weight?['value'] ?? 0.0;
    final goalWeight = _user?.goalWeight?['value'] ?? 0.0;
    final currentWeightUnit = _user?.weight?['unit'] ?? 'kg';

    // Get actual calorie data from daily nutrition
    final targetCalories = _dailyNutrition?.targetCalories ?? 0;

    // Only show consumed calories from actual food entries
    final consumedCalories = _dailyNutrition?.consumedCalories.toInt() ?? 0;
    final remainingCalories = targetCalories - consumedCalories;

    // Animation for the calories circle
    final calorieProgress = targetCalories > 0 ?
        (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;

    // Material 3 color scheme
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;
    final surfaceColor = colorScheme.surface;
    final secondaryColor = colorScheme.secondary;

    return Material(
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.4),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.85),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Calories circle with Material 3 animation
            Stack(
              alignment: Alignment.center,
              children: [
                // Background wave animation
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.2),
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOut,
                ),

                // Material 3 circular progress indicator
                SizedBox(
                  width: 220,
                  height: 220,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1 - calorieProgress),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        backgroundColor: secondaryColor.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(onPrimaryColor),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),

                // Inner circle with calories left
                Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surfaceColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: remainingCalories),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            '$value',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(reverse: true),
                          ).scale(
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.05, 1.05),
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      Text(
                        'KCAL LEFT',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Calories consumed with Material 3 card
            Card(
              elevation: 0,
              color: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: onPrimaryColor,
                      size: 20,
                    ).animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    ).scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.2, 1.2),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                    ),
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: consumedCalories),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          '$value / $targetCalories',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: onPrimaryColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(
              duration: EnhancedAnimations.medium,
              delay: EnhancedAnimations.shortDelay,
              curve: EnhancedAnimations.emphasizedCurve,
            ).slideY(
              begin: 0.2,
              end: 0,
              duration: EnhancedAnimations.medium,
              delay: EnhancedAnimations.shortDelay,
              curve: EnhancedAnimations.emphasizedCurve,
            ),

            const SizedBox(height: 8),
            Text(
              'CALORIES CONSUMED',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: onPrimaryColor.withOpacity(0.9),
              ),
            ).animate().fadeIn(
              duration: EnhancedAnimations.medium,
              delay: EnhancedAnimations.mediumDelay,
              curve: EnhancedAnimations.emphasizedCurve,
            ),

            const SizedBox(height: 24),

            // Weight goal with Material 3 card
            if (currentWeight > 0 && goalWeight > 0)
              Card(
                elevation: 0,
                color: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        weightGoal == 'gain' ? Icons.trending_up :
                        weightGoal == 'lose' ? Icons.trending_down : Icons.trending_flat,
                        color: onPrimaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Goal: ${currentWeight.toStringAsFixed(1)} → ${goalWeight.toStringAsFixed(1)} $currentWeightUnit',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.medium,
                delay: EnhancedAnimations.longDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ).slideY(
                begin: 0.2,
                end: 0,
                duration: EnhancedAnimations.medium,
                delay: EnhancedAnimations.longDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ),

            const SizedBox(height: 24),

            // Material 3 filled tonal button
            FilledButton.tonal(
              onPressed: () {
                // Add haptic feedback
                HapticFeedback.mediumImpact();
                setState(() {
                  _currentIndex = 1; // Switch to analytics tab
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: surfaceColor,
                foregroundColor: primaryColor,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VIEW ANALYTICS',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              duration: EnhancedAnimations.medium,
              delay: const Duration(milliseconds: 500),
              curve: EnhancedAnimations.emphasizedCurve,
            ).slideY(
              begin: 0.2,
              end: 0,
              duration: EnhancedAnimations.medium,
              delay: const Duration(milliseconds: 500),
              curve: EnhancedAnimations.emphasizedCurve,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyEatenSection() {
    if (_recentFoodItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No meals recorded today',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your meals by taking pictures of your food',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Get today's food items
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todaysFoodItems = _recentFoodItems.where((food) {
      return food.timestamp.isAfter(todayStart) && food.timestamp.isBefore(todayEnd);
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Eaten',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(today),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Food items list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todaysFoodItems.length > 3 ? 3 : todaysFoodItems.length,
            itemBuilder: (context, index) {
              final food = todaysFoodItems[index];
              return _buildFoodItem(food);
            },
          ),

          // View all button
          if (todaysFoodItems.length > 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1; // Switch to analytics tab
                    });
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Food image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              food.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildNutrientPill('P: ${food.protein.toInt()}g', Colors.red),
                    const SizedBox(width: 6),
                    _buildNutrientPill('C: ${food.carbs.toInt()}g', Colors.amber[700]!),
                    const SizedBox(width: 6),
                    _buildNutrientPill('F: ${food.fat.toInt()}g', Colors.blue),
                  ],
                ),
              ],
            ),
          ),

          // Calories and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${food.calories} kcal',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('hh:mm a').format(food.timestamp),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMacronutrientsBar() {
    if (_dailyNutrition == null) {
      return const SizedBox.shrink();
    }

    // Calculate percentages for each macronutrient
    final carbsPercentage = (_dailyNutrition!.consumedCarbs / _dailyNutrition!.targetCarbs).clamp(0.0, 1.0);
    final proteinPercentage = (_dailyNutrition!.consumedProtein / _dailyNutrition!.targetProtein).clamp(0.0, 1.0);
    final fatPercentage = (_dailyNutrition!.consumedFat / _dailyNutrition!.targetFat).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macronutrients',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          _buildMacronutrientBarItem(
            'Carbs',
            '${_dailyNutrition!.consumedCarbs.toInt()}/${_dailyNutrition!.targetCarbs.toInt()}g',
            const Color(0xFF4CAF50), // Green
            carbsPercentage,
            const Duration(milliseconds: 300),
          ),

          const SizedBox(height: 12),

          _buildMacronutrientBarItem(
            'Protein',
            '${_dailyNutrition!.consumedProtein.toInt()}/${_dailyNutrition!.targetProtein.toInt()}g',
            const Color(0xFFF44336), // Red
            proteinPercentage,
            const Duration(milliseconds: 500),
          ),

          const SizedBox(height: 12),

          _buildMacronutrientBarItem(
            'Fat',
            '${_dailyNutrition!.consumedFat.toInt()}/${_dailyNutrition!.targetFat.toInt()}g',
            const Color(0xFF2196F3), // Blue
            fatPercentage,
            const Duration(milliseconds: 700),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientBarItem(String label, String value, Color color, double percentage, Duration delay) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                children: [
                  // Background bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Progress bar with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: percentage),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Container(
                        height: 8,
                        width: MediaQuery.of(context).size.width * 0.6 * value,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Meal time class for notification settings
class MealTime {
  final String name;
  TimeOfDay? time;

  MealTime({required this.name, this.time});
}
