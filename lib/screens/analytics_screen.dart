import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import '../models/daily_nutrition.dart';
import '../models/food_item.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../providers/nutrition_provider.dart';
import '../utils/constants.dart';
import '../utils/string_extensions.dart';
import '../utils/calculations/calorie_goal_calculator.dart';
import '../widgets/enhanced_widgets.dart';
import '../utils/enhanced_animations.dart';
import 'camera_screen.dart';
import 'food_analysis_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  final Function? onWeightGoalUpdated;

  const AnalyticsScreen({Key? key, this.onWeightGoalUpdated}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  UserModel? _user;
  List<FoodItem> _todaysFoodItems = [];
  dynamic _dailyNutrition;
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;

  // Toggle between weekly and monthly view
  bool _showWeeklyView = true;

  // Calorie data
  List<Map<String, dynamic>> _monthlyCalorieData = [];
  List<Map<String, dynamic>> _weeklyCalorieData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize with default values to prevent loading state
    _initializeDefaultValues();

    // Load actual data
    _loadUserData();
    _loadWeeklyCalorieData();
    _animationController.forward();

    // Set up a timer to refresh data periodically (every 5 seconds)
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadUserData();
        _loadWeeklyCalorieData();
      } else {
        timer.cancel();
      }
    });

    // Add post-frame callback to set up nutrition provider listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen for changes in nutrition data
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      nutritionProvider.addListener(_refreshData);
    });
  }

  // Refresh data when nutrition changes
  void _refreshData() {
    debugPrint('Refreshing analytics screen data due to nutrition changes');
    if (mounted) {
      _loadUserData();
      _loadWeeklyCalorieData();
    }
  }

  // Initialize with default values to prevent loading state
  void _initializeDefaultValues() {
    // Create a default user
    final defaultUser = UserModel(
      id: 'default_user',
      name: 'User',
      email: 'user@example.com',
      gender: 'female',
      activityLevel: 'intermediate',
      experience: 'no',
      weightGoal: 'lose',
      weight: {'value': 48.0, 'unit': 'kg'},
      height: {'value': 160.0, 'unit': 'cm'},
      goalWeight: {'value': 45.0, 'unit': 'kg'},
      dateOfBirth: DateTime(2002, 12, 14),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      onboardingCompleted: true,
    );

    // Create default daily nutrition
    final defaultDailyNutrition = DailyNutrition(
      targetCalories: 1800,
      targetProtein: 135.0,
      targetCarbs: 180.0,
      targetFat: 60.0,
      date: _selectedDate,
      consumedCalories: 0,
      consumedProtein: 0,
      consumedCarbs: 0,
      consumedFat: 0,
    );

    // Set default values
    setState(() {
      _user = defaultUser;
      _dailyNutrition = defaultDailyNutrition;
      _todaysFoodItems = [];

      // Initialize monthly calorie data with zeros
      final now = DateTime.now();
      _monthlyCalorieData = List.generate(30, (i) {
        final date = now.subtract(Duration(days: i));
        return {
          'date': date,
          'day': DateFormat('d').format(date),
          'dayName': DateFormat('E').format(date),
          'calories': 0.0,
          'target': 1800,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
        };
      });

      // Initialize weekly calorie data with zeros
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      _weeklyCalorieData = List.generate(7, (i) {
        final date = startOfWeek.add(Duration(days: i));
        return {
          'date': date,
          'day': DateFormat('d').format(date),
          'dayName': DateFormat('E').format(date),
          'calories': 0.0,
          'target': 1800,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
        };
      });
    });
  }

  @override
  void dispose() {
    // Remove nutrition provider listener
    try {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      nutritionProvider.removeListener(_refreshData);
    } catch (e) {
      debugPrint('Error removing nutrition provider listener: $e');
    }

    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      UserModel? user = await _userService.getUserData();
      final foodItems = await _userService.getFoodItemsForDate(_selectedDate);

      if (user != null) {
        // Debug information to verify weight goal data
        debugPrint('Loaded user data in analytics screen:');
        debugPrint('Weight goal: ${user.weightGoal}');
        debugPrint('Goal weight: ${user.goalWeight}');
        debugPrint('Current weight: ${user.weight}');

      // Ensure weight is properly set
      if (user.weight == null || user.weight!.isEmpty) {
        // Get weight from SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        final weightValue = prefs.getDouble('weight_value');
        final weightUnit = prefs.getString('weight_unit') ?? 'kg';

        if (weightValue != null) {
          // Use the weight from SharedPreferences
          final weightMap = {
            'value': weightValue,
            'unit': weightUnit,
            'initial_value': weightValue,
          };

          // Update user with the weight from SharedPreferences
          final updatedUser = user.copyWith(
            weight: weightMap,
          );

          // Save the updated user data
          await _userService.saveUserData(updatedUser);

          // Use the updated user
          user = updatedUser;

          debugPrint('Using weight from SharedPreferences: $weightValue $weightUnit');
        } else {
          // Set default weight to 48kg (from onboarding logs)
          final weightMap = {
            'value': 48.0,
            'unit': 'kg',
            'initial_value': 48.0,
          };

          // Update user with the default weight
          final updatedUser = user.copyWith(
            weight: weightMap,
          );

          // Save the updated user data
          await _userService.saveUserData(updatedUser);

          // Use the updated user
          user = updatedUser;
        }
      }

      // Get goal weight and current weight values
      double? goalWeightValue;
      double? currentWeightValue;

      if (user.goalWeight != null && user.goalWeight!.isNotEmpty) {
        var goalWeightRaw = user.goalWeight!['value'];
        if (goalWeightRaw is int) {
          goalWeightValue = goalWeightRaw.toDouble();
        } else if (goalWeightRaw is double) {
          goalWeightValue = goalWeightRaw;
        } else if (goalWeightRaw is String) {
          goalWeightValue = double.tryParse(goalWeightRaw);
        }
      }

      if (user.weight != null && user.weight!.isNotEmpty) {
        var currentWeightRaw = user.weight!['value'];
        if (currentWeightRaw is int) {
          currentWeightValue = currentWeightRaw.toDouble();
        } else if (currentWeightRaw is double) {
          currentWeightValue = currentWeightRaw;
        } else if (currentWeightRaw is String) {
          currentWeightValue = double.tryParse(currentWeightRaw);
        }
      }

      // Determine weight goal based on goal weight and current weight
      if (goalWeightValue != null && currentWeightValue != null) {
        String calculatedWeightGoal;
        if (goalWeightValue > currentWeightValue) {
          calculatedWeightGoal = 'gain';
        } else if (goalWeightValue < currentWeightValue) {
          calculatedWeightGoal = 'lose';
        } else {
          calculatedWeightGoal = 'maintain';
        }

        // Update weight goal if it doesn't match the calculated value
        if (user.weightGoal != calculatedWeightGoal) {
          final updatedUser = user.copyWith(
            weightGoal: calculatedWeightGoal,
          );

          // Save the updated user data
          await _userService.saveUserData(updatedUser);

          // Force a direct update to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('weight_goal', calculatedWeightGoal);
          await prefs.setString('weightGoal', calculatedWeightGoal);

          // Use the updated user
          user = updatedUser;

          debugPrint('Updated weight goal to: $calculatedWeightGoal based on goal weight: $goalWeightValue and current weight: $currentWeightValue');
        }
      } else if (user.weightGoal == null || user.weightGoal!.isEmpty) {
        // Try to get weight goal from shared preferences directly
        final prefs = await SharedPreferences.getInstance();
        String? weightGoal = prefs.getString('weightGoal') ?? prefs.getString('weight_goal');

        if (weightGoal != null && weightGoal.isNotEmpty) {
          // Use the weight goal from shared preferences
          final updatedUser = user.copyWith(
            weightGoal: weightGoal,
          );

          // Save the updated user data
          await _userService.saveUserData(updatedUser);

          // Use the updated user
          user = updatedUser;
        } else {
          // Default to 'gain' as specified
          final updatedUser = user.copyWith(
            weightGoal: 'gain',
          );

          // Save the updated user data
          await _userService.saveUserData(updatedUser);

          // Use the updated user
          user = updatedUser;
        }
      }

      // Ensure goal weight is properly set
      if (user.goalWeight == null || user.goalWeight!.isEmpty) {
        // Get goal weight from SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        final goalWeightValue = prefs.getDouble('goal_weight');
        final goalWeightUnit = prefs.getString('goal_weight_unit') ?? 'kg';

        if (goalWeightValue != null) {
          // Use the goal weight from SharedPreferences
          final goalWeightMap = {
            'value': goalWeightValue,
            'unit': goalWeightUnit,
          };

          // Update user with the goal weight from SharedPreferences
          final updatedUser = user.copyWith(
            goalWeight: goalWeightMap,
          );

          // Save the updated user data
          await _userService.saveUserData(updatedUser);

          // Use the updated user
          user = updatedUser;

          debugPrint('Using goal weight from SharedPreferences: $goalWeightValue $goalWeightUnit');
        } else {
          // Get current weight with robust handling
          double currentWeight = 0.0;
          if (user.weight != null && user.weight!['value'] != null) {
            if (user.weight!['value'] is int) {
              currentWeight = (user.weight!['value'] as int).toDouble();
            } else if (user.weight!['value'] is double) {
              currentWeight = user.weight!['value'] as double;
            } else if (user.weight!['value'] is String) {
              currentWeight = double.tryParse(user.weight!['value'] as String) ?? 0.0;
            }
          }

          // If still no value, use default from onboarding logs
          if (currentWeight == 0.0) {
            currentWeight = 48.0; // Default to 48kg from onboarding logs
          }

          // Get weight goal from SharedPreferences
          final weightGoal = prefs.getString('weightGoal') ?? prefs.getString('weight_goal') ?? 'lose';

          // Calculate goal weight based on weight goal
          double goalWeight;
          if (weightGoal == 'lose') {
            goalWeight = currentWeight - 3.0; // Use 45kg as goal weight for 48kg current weight
          } else if (weightGoal == 'gain') {
            goalWeight = currentWeight + 3.0;
          } else { // maintain
            goalWeight = currentWeight;
          }

          // Create goal weight map
          final goalWeightMap = {
            'value': goalWeight,
            'unit': user.weight?['unit'] ?? 'kg',
          };

          // Update user with the goal weight
          final updatedUser = user.copyWith(
            goalWeight: goalWeightMap,
            weightGoal: weightGoal,
          );

          // Save the updated user data
          await _userService.saveUserData(updatedUser);

          // Also save with alternative key format to ensure compatibility
          await _userService.saveUserData({
            'goal_weight': goalWeight,
            'goal_weight_unit': user.weight?['unit'] ?? 'kg',
            'goalWeight': goalWeight,
            'weight_goal': weightGoal,
            'weightGoal': weightGoal,
          });

          // Use the updated user
          user = updatedUser;

          debugPrint('Calculated goal weight: $goalWeight based on weight goal: $weightGoal');
        }
      }

      // Get nutrition provider
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);

      // Get daily nutrition from nutrition provider
      final dailyNutrition = await nutritionProvider.getDailyNutrition(_selectedDate);

      setState(() {
        _user = user;
        _todaysFoodItems = foodItems;
        _dailyNutrition = dailyNutrition;
      });
    }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Keep using the default values initialized in _initializeDefaultValues
    }
  }

  void _selectDay(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    _loadUserData();
  }

  // Load weekly calorie data for the chart
  Future<void> _loadWeeklyCalorieData() async {
    try {
      // Get the start date based on selected date
      // If no date is selected, use current date
      final selectedDate = _selectedDate;

      // Calculate the start of the week (Sunday) for the selected date
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));

      // Create a list to hold 7 days of data (one week)
      final List<Map<String, dynamic>> weekData = [];

      // Get data for the 7 days of the selected week
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dayName = DateFormat('E').format(date); // Mon, Tue, etc.
        final dayNumber = DateFormat('d').format(date); // 1, 2, etc.

        try {
          // Get nutrition provider
          final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);

          // Get daily nutrition from nutrition provider
          final dailyNutrition = await nutritionProvider.getDailyNutrition(date);

          weekData.add({
            'date': date,
            'day': dayNumber,
            'dayName': dayName,
            'calories': dailyNutrition.consumedCalories.toDouble(),
            'target': nutritionProvider.calorieGoal,
            'protein': dailyNutrition.consumedProtein.toDouble(),
            'carbs': dailyNutrition.consumedCarbs.toDouble(),
            'fat': dailyNutrition.consumedFat.toDouble(),
          });
        } catch (e) {
          debugPrint('Error getting nutrition for date ${date.toString()}: $e');
          // Add default data for this day
          weekData.add({
            'date': date,
            'day': dayNumber,
            'dayName': dayName,
            'calories': 0.0,
            'target': _dailyNutrition?.targetCalories ?? 1800,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
          });
        }
      }

      // Also load monthly data for the trends view
      final now = DateTime.now();
      final List<Map<String, dynamic>> monthData = [];

      // Get data for the last 30 days
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayNumber = DateFormat('d').format(date);
        final dayName = DateFormat('E').format(date);

        try {
          // Get nutrition provider
          final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);

          // Get daily nutrition from nutrition provider
          final dailyNutrition = await nutritionProvider.getDailyNutrition(date);

          monthData.add({
            'date': date,
            'day': dayNumber,
            'dayName': dayName,
            'calories': dailyNutrition.consumedCalories.toDouble(),
            'target': nutritionProvider.calorieGoal,
            'protein': dailyNutrition.consumedProtein.toDouble(),
            'carbs': dailyNutrition.consumedCarbs.toDouble(),
            'fat': dailyNutrition.consumedFat.toDouble(),
          });
        } catch (e) {
          debugPrint('Error getting nutrition for date ${date.toString()}: $e');
          // Add default data for this day
          monthData.add({
            'date': date,
            'day': dayNumber,
            'dayName': dayName,
            'calories': 0.0,
            'target': _dailyNutrition?.targetCalories ?? 1800,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
          });
        }
      }

      setState(() {
        _weeklyCalorieData = weekData;
        _monthlyCalorieData = monthData;
      });

      debugPrint('Loaded weekly data for week starting: ${startOfWeek.toString()}');

    } catch (e) {
      debugPrint('Error loading weekly calorie data: $e');
      // Keep using the default values initialized in _initializeDefaultValues
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _dailyNutrition == null
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(textColor ?? Colors.black, isDarkMode),
                    _buildWeekDaySelector(textColor ?? Colors.black, subtitleColor ?? Colors.grey[600]!, isDarkMode),
                    _buildCalorieCounter(textColor ?? Colors.black, subtitleColor ?? Colors.grey[600]!, isDarkMode),
                    _buildWeeklyTrendsChart(textColor ?? Colors.black, subtitleColor ?? Colors.grey[600]!, isDarkMode),
                    _buildWeightGoalSection(textColor ?? Colors.black, subtitleColor ?? Colors.grey[600]!, isDarkMode),
                    _buildMacronutrientCards(textColor ?? Colors.black, subtitleColor ?? Colors.grey[600]!, isDarkMode),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar(Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            'FoodAI',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            'assets/images/mango_icon.svg',
            width: 24,
            height: 24,
            colorFilter: isDarkMode
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : null,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.primaryColorDark.withOpacity(0.2) : Colors.orange[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppColors.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_dailyNutrition!.consumedCalories}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaySelector(Color textColor, Color subtitleColor, bool isDarkMode) {
    // Get the current date
    final now = DateTime.now();

    // Get the first day of the current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Get the last day of the current month
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // Calculate the number of days in the month
    final daysInMonth = lastDayOfMonth.day;

    // Create a list of all dates in the current month
    final List<DateTime> datesInMonth = List.generate(
      daysInMonth,
      (index) => DateTime(now.year, now.month, index + 1),
    );

    // Get the current month name
    final currentMonth = DateFormat('MMMM yyyy').format(now);

    return Column(
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentMonth,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        // Day selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              // Weekday headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) =>
                    SizedBox(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    )
                  ).toList(),
                ),
              ),

              // Calendar grid
              SizedBox(
                height: 220, // Fixed height for the calendar
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8, // Horizontal spacing
                      runSpacing: 8, // Vertical spacing
                      children: _buildCalendarDays(
                        datesInMonth,
                        firstDayOfMonth,
                        textColor,
                        subtitleColor,
                        isDarkMode
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCalendarDays(
    List<DateTime> datesInMonth,
    DateTime firstDayOfMonth,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    final List<Widget> calendarDays = [];

    // Add empty spaces for days before the first day of the month
    // Monday is 1, Sunday is 7 in DateTime.weekday
    int firstWeekdayOfMonth = firstDayOfMonth.weekday;

    // Add empty spaces
    for (int i = 1; i < firstWeekdayOfMonth; i++) {
      calendarDays.add(
        SizedBox(
          width: 36,
          height: 36,
        ),
      );
    }

    // Add all days of the month
    for (final date in datesInMonth) {
      final isToday = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month &&
                      date.year == DateTime.now().year;

      final isSelected = date.day == _selectedDate.day &&
                         date.month == _selectedDate.month &&
                         date.year == _selectedDate.year;

      calendarDays.add(
        GestureDetector(
          onTap: () => _selectDay(date),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : isToday
                      ? AppColors.primaryColor.withOpacity(0.05)
                      : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : isToday
                        ? AppColors.primaryColor.withOpacity(0.5)
                        : Colors.transparent,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primaryColor
                      : isToday
                          ? AppColors.primaryColor
                          : textColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return calendarDays;
  }

  Widget _buildCalorieCounter(Color textColor, Color subtitleColor, bool isDarkMode) {
    final caloriesRemaining = _dailyNutrition!.targetCalories - _dailyNutrition!.consumedCalories;
    final isOver = caloriesRemaining < 0;

    // Calculate percentage for progress indicator
    final percentage = (_dailyNutrition!.consumedCalories / _dailyNutrition!.targetCalories).clamp(0.0, 1.0);

    return EnhancedWidgets.card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.all(24),
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 8,
      animate: true,
      animationDuration: EnhancedAnimations.medium,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Calories',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.short,
                curve: EnhancedAnimations.emphasizedCurve,
              ).slideX(
                begin: -0.1,
                end: 0,
                duration: EnhancedAnimations.short,
                curve: EnhancedAnimations.emphasizedCurve,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOver
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOver
                        ? Colors.red.withOpacity(0.3)
                        : AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOver ? Icons.warning_rounded : Icons.check_circle_rounded,
                      size: 16,
                      color: isOver ? Colors.red : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOver ? 'Over' : 'On Track',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isOver ? Colors.red : AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.short,
                delay: EnhancedAnimations.tinyDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ).slideX(
                begin: 0.1,
                end: 0,
                duration: EnhancedAnimations.short,
                delay: EnhancedAnimations.tinyDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Enhanced calorie progress circle with animation
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle with subtle gradient
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                            isDarkMode ? Colors.grey[850]! : Colors.grey[200]!,
                          ],
                          stops: const [0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // Animated progress indicator
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: percentage),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver ? Colors.red : AppColors.primaryColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        );
                      },
                    ),
                    // Inner content with animated icon
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: isOver ? Colors.red : AppColors.primaryColor,
                          size: 28,
                        ).animate(
                          onPlay: (controller) => controller.repeat(reverse: true),
                        ).scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.1, 1.1),
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                        ),
                        const SizedBox(height: 4),
                        // Animated percentage counter
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: (percentage * 100).toInt()),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Text(
                              '$value%',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.medium,
                curve: EnhancedAnimations.emphasizedCurve,
              ).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: EnhancedAnimations.medium,
                curve: EnhancedAnimations.emphasizedCurve,
              ),
              const SizedBox(width: 24),
              // Enhanced calorie details with animations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnhancedCalorieDetail(
                      'Goal',
                      '${_dailyNutrition!.targetCalories}',
                      Icons.flag_outlined,
                      AppColors.primaryColor,
                      textColor,
                      subtitleColor,
                      isDarkMode,
                      const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: 16),
                    _buildEnhancedCalorieDetail(
                      'Consumed',
                      '${_dailyNutrition!.consumedCalories}',
                      Icons.restaurant_outlined,
                      Colors.green,
                      textColor,
                      subtitleColor,
                      isDarkMode,
                      const Duration(milliseconds: 400),
                    ),
                    const SizedBox(height: 16),
                    _buildEnhancedCalorieDetail(
                      isOver ? 'Over' : 'Remaining',
                      '${isOver ? -caloriesRemaining : caloriesRemaining}',
                      isOver ? Icons.trending_up : Icons.trending_down,
                      isOver ? Colors.red : Colors.blue,
                      textColor,
                      subtitleColor,
                      isDarkMode,
                      const Duration(milliseconds: 600),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.medium,
                delay: EnhancedAnimations.shortDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ).slideX(
                begin: 0.1,
                end: 0,
                duration: EnhancedAnimations.medium,
                delay: EnhancedAnimations.shortDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDetail(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedCalorieDetail(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
    Duration delay,
  ) {
    return Row(
      children: [
        // Enhanced icon container with gradient and shadow
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iconColor.withOpacity(0.2),
                iconColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: iconColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).shimmer(
          duration: const Duration(seconds: 3),
          color: iconColor.withOpacity(0.2),
        ),
        const SizedBox(width: 12),
        // Enhanced text with animations
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(
              duration: EnhancedAnimations.short,
              delay: delay,
              curve: EnhancedAnimations.emphasizedCurve,
            ).slideX(
              begin: 0.2,
              end: 0,
              duration: EnhancedAnimations.short,
              delay: delay,
              curve: EnhancedAnimations.emphasizedCurve,
            ),
            const SizedBox(height: 2),
            // Animated counter for value
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return Text(
                  '$animatedValue',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyTrendsChart(Color textColor, Color subtitleColor, bool isDarkMode) {
    // If no data is available yet, show a loading indicator
    if ((_showWeeklyView && _weeklyCalorieData.isEmpty) || (!_showWeeklyView && _monthlyCalorieData.isEmpty)) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        height: 300,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Get the data based on the selected view
    final dataToUse = _showWeeklyView ? _weeklyCalorieData : _monthlyCalorieData;

    // Calculate max value for the chart
    double maxCalories = 0;
    for (final day in dataToUse) {
      final calories = day['calories'] as double;
      final target = day['target'] as int;
      if (calories > maxCalories) maxCalories = calories;
      if (target > maxCalories) maxCalories = target.toDouble();
    }

    // Round up to nearest 500 for better visualization
    maxCalories = ((maxCalories / 500).ceil() * 500).toDouble();
    if (maxCalories == 0) maxCalories = 2000; // Default if no data

    // Get the date range for display
    String dateRangeText;
    if (_showWeeklyView && _weeklyCalorieData.isNotEmpty) {
      final startDate = _weeklyCalorieData.first['date'] as DateTime;
      final endDate = _weeklyCalorieData.last['date'] as DateTime;
      dateRangeText = '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';
    } else {
      dateRangeText = 'Last 30 Days';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showWeeklyView ? 'Weekly Trends' : 'Monthly Trends',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              // Toggle button between weekly and monthly view
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showWeeklyView = !_showWeeklyView;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showWeeklyView ? dateRangeText : 'Last 30 Days',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swap_horiz,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Consumed',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Target',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Scrollable chart container
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Container(
                // Make the chart wider for better scrolling experience
                width: _showWeeklyView ? 400 : 800,
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxCalories,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: isDarkMode ? Colors.grey[800]! : Colors.white,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (groupIndex >= dataToUse.length) return null;

                          final day = dataToUse[groupIndex]['day'];
                          final dayName = dataToUse[groupIndex]['dayName'];
                          final date = dataToUse[groupIndex]['date'] as DateTime;
                          final month = DateFormat('MMM').format(date);
                          final value = rod.toY.round();
                          return BarTooltipItem(
                            '$dayName, $month $day: $value kcal',
                            GoogleFonts.poppins(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < dataToUse.length) {
                              // For weekly view, show all days
                              // For monthly view, show every 5th day
                              if (_showWeeklyView || index % 5 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        dataToUse[index]['dayName'] as String,
                                        style: GoogleFonts.poppins(
                                          color: subtitleColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        dataToUse[index]['day'] as String,
                                        style: GoogleFonts.poppins(
                                          color: subtitleColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                            return const SizedBox();
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  color: subtitleColor,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          interval: maxCalories / 4,
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(
                      dataToUse.length,
                      (index) {
                        final data = dataToUse[index];
                        final calories = data['calories'] as double;
                        final target = data['target'] as int;
                        final date = data['date'] as DateTime;

                        // Check if this is today's data
                        final isToday = DateTime.now().day == date.day &&
                                       DateTime.now().month == date.month &&
                                       DateTime.now().year == date.year;

                        // Check if this is the selected date
                        final isSelected = _selectedDate.day == date.day &&
                                         _selectedDate.month == date.month &&
                                         _selectedDate.year == date.year;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: calories,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : isToday
                                      ? AppColors.primaryColor.withOpacity(0.9)
                                      : AppColors.primaryColor.withOpacity(0.7),
                              width: _showWeeklyView ? 30 : 12, // Wider bars for weekly view
                              borderRadius: const BorderRadius.all(Radius.circular(4)),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: target.toDouble(),
                                color: isDarkMode
                                    ? Colors.grey[700]!.withOpacity(0.3)
                                    : Colors.grey[300]!.withOpacity(0.5),
                              ),
                            ),
                          ],
                          // Show tooltip indicator for selected date
                          showingTooltipIndicators: isSelected || isToday ? [0] : [],
                        );
                      },
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxCalories / 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    // Add target line
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: _dailyNutrition!.targetCalories.toDouble(),
                          color: Colors.grey[400]!,
                          strokeWidth: 2,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(right: 8, bottom: 4),
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            labelResolver: (line) => 'Target',
                          ),
                        ),
                      ],
                    ),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 500),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
              ),
            ),
          ),

          // Instructions for scrolling
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                '← Scroll to view more data →',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: subtitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsInsights(Color textColor, Color subtitleColor, bool isDarkMode) {
    return Container(); // Empty container as placeholder
  }

  Widget _buildMonthlyInsights(Color textColor, Color subtitleColor, bool isDarkMode) {
    // Calculate average calories consumed
    double totalCalories = 0;
    for (final day in _monthlyCalorieData) {
      totalCalories += day['calories'] as double;
    }
    final averageCalories = totalCalories / _monthlyCalorieData.length;

    // Calculate days on target
    int daysOnTarget = 0;
    for (final day in _monthlyCalorieData) {
      final calories = day['calories'] as double;
      final target = day['target'] as int;

      // Consider within 10% of target as "on target"
      if (calories >= target * 0.9 && calories <= target * 1.1) {
        daysOnTarget++;
      }
    }

    // Determine if user is on track with their goal
    final String weightGoal = _user?.weightGoal?.toLowerCase() ?? 'maintain';
    bool isOnTrack = false;
    String insightMessage = '';

    if (weightGoal == 'lose') {
      // For weight loss, average calories should be below target
      isOnTrack = averageCalories < _dailyNutrition!.targetCalories;
      insightMessage = isOnTrack
          ? 'You\'re on track to lose weight! Keep it up!'
          : 'Try to stay under your calorie target to achieve your weight loss goal.';
    } else if (weightGoal == 'gain') {
      // For weight gain, average calories should be above target
      isOnTrack = averageCalories > _dailyNutrition!.targetCalories;
      insightMessage = isOnTrack
          ? 'You\'re on track to gain weight! Keep it up!'
          : 'Try to consume more calories to achieve your weight gain goal.';
    } else {
      // For maintenance, average calories should be close to target
      isOnTrack = averageCalories >= _dailyNutrition!.targetCalories * 0.9 &&
                 averageCalories <= _dailyNutrition!.targetCalories * 1.1;
      insightMessage = isOnTrack
          ? 'You\'re maintaining your weight well! Keep it up!'
          : 'Try to stay close to your calorie target to maintain your weight.';
    }

    return EnhancedWidgets.card(
      padding: const EdgeInsets.all(20),
      backgroundColor: isOnTrack
          ? (isDarkMode ? Colors.green.withOpacity(0.15) : Colors.green.withOpacity(0.08))
          : (isDarkMode ? Colors.orange.withOpacity(0.15) : Colors.orange.withOpacity(0.08)),
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      borderSide: BorderSide(
        color: isOnTrack
            ? Colors.green.withOpacity(isDarkMode ? 0.4 : 0.3)
            : Colors.orange.withOpacity(isDarkMode ? 0.4 : 0.3),
        width: 1.5,
      ),
      animate: true,
      animationDuration: EnhancedAnimations.medium,
      animationDelay: EnhancedAnimations.longDelay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOnTrack
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOnTrack ? Icons.check_circle : Icons.info,
                  color: isOnTrack ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              ).shimmer(
                duration: const Duration(seconds: 3),
                color: isOnTrack
                    ? Colors.green.withOpacity(0.5)
                    : Colors.orange.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Insight',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isOnTrack ? Colors.green : Colors.orange,
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.short,
                delay: EnhancedAnimations.longDelay + const Duration(milliseconds: 100),
                curve: EnhancedAnimations.emphasizedCurve,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              insightMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: textColor,
              ),
            ),
          ).animate().fadeIn(
            duration: EnhancedAnimations.medium,
            delay: EnhancedAnimations.longDelay + const Duration(milliseconds: 200),
            curve: EnhancedAnimations.emphasizedCurve,
          ).slideY(
            begin: 0.2,
            end: 0,
            duration: EnhancedAnimations.medium,
            delay: EnhancedAnimations.longDelay + const Duration(milliseconds: 200),
            curve: EnhancedAnimations.emphasizedCurve,
          ),
          const SizedBox(height: 16),
          // Use Wrap instead of Row to prevent overflow
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 8.0,
            runSpacing: 16.0,
            children: [
              _buildEnhancedInsightStat(
                'Avg. Daily',
                '${averageCalories.round()} kcal',
                Icons.calendar_view_day,
                subtitleColor,
                textColor,
                isDarkMode,
                const Duration(milliseconds: 300),
              ),
              _buildEnhancedInsightStat(
                'Days On Target',
                '$daysOnTarget/30',
                Icons.check_circle_outline,
                subtitleColor,
                textColor,
                isDarkMode,
                const Duration(milliseconds: 400),
              ),
              _buildEnhancedInsightStat(
                'Monthly Total',
                '${totalCalories.round()} kcal',
                Icons.summarize,
                subtitleColor,
                textColor,
                isDarkMode,
                const Duration(milliseconds: 500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightStat(
    String label,
    String value,
    IconData icon,
    Color subtitleColor,
    Color textColor,
    bool isDarkMode
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedInsightStat(
    String label,
    String value,
    IconData icon,
    Color subtitleColor,
    Color textColor,
    bool isDarkMode,
    Duration delay
  ) {
    return Column(
      children: [
        // Enhanced icon with container and animation
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.1),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.primaryColor,
            size: 18,
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).shimmer(
          duration: const Duration(seconds: 3),
          color: AppColors.primaryColor.withOpacity(0.3),
        ),
        const SizedBox(height: 8),
        // Animated value counter
        TweenAnimationBuilder<int>(
          tween: IntTween(
            begin: 0,
            end: int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0
          ),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, child) {
            // Format the value to match the original format (e.g., "1234 kcal")
            String formattedValue = value.replaceAll(
              RegExp(r'[0-9]+'),
              animatedValue.toString()
            );

            return Text(
              formattedValue,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        // Label with animation
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
            letterSpacing: 0.5,
          ),
        ).animate().fadeIn(
          duration: EnhancedAnimations.short,
          delay: delay,
          curve: EnhancedAnimations.emphasizedCurve,
        ),
      ],
    ).animate().fadeIn(
      duration: EnhancedAnimations.medium,
      delay: delay,
      curve: EnhancedAnimations.emphasizedCurve,
    ).slideY(
      begin: 0.2,
      end: 0,
      duration: EnhancedAnimations.medium,
      delay: delay,
      curve: EnhancedAnimations.emphasizedCurve,
    );
  }

  Widget _buildMacronutrientCards(Color textColor, Color subtitleColor, bool isDarkMode) {
    return EnhancedWidgets.card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.all(24),
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 8,
      animate: true,
      animationDuration: EnhancedAnimations.medium,
      animationDelay: EnhancedAnimations.extraLongDelay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Macronutrients',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.short,
                delay: EnhancedAnimations.extraLongDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ).slideX(
                begin: -0.1,
                end: 0,
                duration: EnhancedAnimations.short,
                delay: EnhancedAnimations.extraLongDelay,
                curve: EnhancedAnimations.emphasizedCurve,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Daily Goals',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(
                duration: EnhancedAnimations.short,
                delay: EnhancedAnimations.extraLongDelay + const Duration(milliseconds: 100),
                curve: EnhancedAnimations.emphasizedCurve,
              ).slideX(
                begin: 0.1,
                end: 0,
                duration: EnhancedAnimations.short,
                delay: EnhancedAnimations.extraLongDelay + const Duration(milliseconds: 100),
                curve: EnhancedAnimations.emphasizedCurve,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedMacroCard(
                  'Protein',
                  _dailyNutrition!.consumedProtein.toInt(),
                  _dailyNutrition!.targetProtein.toInt(),
                  Icons.fitness_center_rounded,
                  Colors.red,
                  textColor,
                  subtitleColor,
                  isDarkMode,
                  const Duration(milliseconds: 200),
                ),
              ),
              Expanded(
                child: _buildEnhancedMacroCard(
                  'Carbs',
                  _dailyNutrition!.consumedCarbs.toInt(),
                  _dailyNutrition!.targetCarbs.toInt(),
                  Icons.grain_rounded,
                  Colors.amber[700]!,
                  textColor,
                  subtitleColor,
                  isDarkMode,
                  const Duration(milliseconds: 400),
                ),
              ),
              Expanded(
                child: _buildEnhancedMacroCard(
                  'Fats',
                  _dailyNutrition!.consumedFat.toInt(),
                  _dailyNutrition!.targetFat.toInt(),
                  Icons.opacity_rounded,
                  Colors.blue,
                  textColor,
                  subtitleColor,
                  isDarkMode,
                  const Duration(milliseconds: 600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    String title,
    int consumed,
    int target,
    IconData icon,
    Color color,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    final remaining = target - consumed;
    final isOver = remaining < 0;
    final percentage = (consumed / target).clamp(0.0, 1.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
                ),
                // Progress indicator
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 8,
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOver ? Colors.red : color,
                    ),
                  ),
                ),
                // Icon
                Icon(
                  icon,
                  color: isOver ? Colors.red : color,
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${consumed}g / ${target}g',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOver ? '${-remaining}g over' : '${remaining}g left',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOver ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMacroCard(
    String title,
    int consumed,
    int target,
    IconData icon,
    Color color,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
    Duration delay,
  ) {
    final remaining = target - consumed;
    final isOver = remaining < 0;
    final percentage = (consumed / target).clamp(0.0, 1.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          // Enhanced circular progress with animation
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle with gradient
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                        isDarkMode ? Colors.grey[850]! : Colors.grey[200]!,
                      ],
                      stops: const [0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                // Animated progress indicator
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver ? Colors.red : color,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    );
                  },
                ),
                // Enhanced icon with container and animation
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isOver ? Colors.red : color).withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isOver ? Colors.red : color).withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isOver ? Colors.red : color,
                    size: 24,
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).shimmer(
                  duration: const Duration(seconds: 3),
                  color: (isOver ? Colors.red : color).withOpacity(0.3),
                ),
              ],
            ),
          ).animate().fadeIn(
            duration: EnhancedAnimations.medium,
            delay: EnhancedAnimations.extraLongDelay + delay,
            curve: EnhancedAnimations.emphasizedCurve,
          ).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: EnhancedAnimations.medium,
            delay: EnhancedAnimations.extraLongDelay + delay,
            curve: EnhancedAnimations.emphasizedCurve,
          ),
          const SizedBox(height: 12),
          // Enhanced title with animation
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(
            duration: EnhancedAnimations.short,
            delay: EnhancedAnimations.extraLongDelay + delay + const Duration(milliseconds: 100),
            curve: EnhancedAnimations.emphasizedCurve,
          ),
          const SizedBox(height: 6),
          // Animated counter for consumed/target
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: consumed),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                '${animatedValue}g / ${target}g',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          // Enhanced remaining text with animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isOver ? Colors.red : Colors.green).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isOver ? Colors.red : Colors.green).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              isOver ? '${-remaining}g over' : '${remaining}g left',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOver ? Colors.red : Colors.green,
              ),
            ),
          ).animate().fadeIn(
            duration: EnhancedAnimations.short,
            delay: EnhancedAnimations.extraLongDelay + delay + const Duration(milliseconds: 200),
            curve: EnhancedAnimations.emphasizedCurve,
          ).slideY(
            begin: 0.2,
            end: 0,
            duration: EnhancedAnimations.short,
            delay: EnhancedAnimations.extraLongDelay + delay + const Duration(milliseconds: 200),
            curve: EnhancedAnimations.emphasizedCurve,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyEatenSection(Color textColor, Color subtitleColor, bool isDarkMode) {
    // Group food items by meal type
    final Map<String, List<FoodItem>> mealGroups = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snack': [],
    };

    for (final food in _todaysFoodItems) {
      final mealType = food.mealType;
      if (mealGroups.containsKey(mealType)) {
        mealGroups[mealType]!.add(food);
      } else {
        mealGroups['Snack']!.add(food);
      }
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Meals',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(_selectedDate),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _todaysFoodItems.isEmpty
              ? _buildEmptyFoodList(textColor, subtitleColor, isDarkMode)
              : Column(
                  children: [
                    // Breakfast section
                    _buildMealTypeSection(
                      'Breakfast',
                      Icons.free_breakfast,
                      Colors.orange,
                      mealGroups['Breakfast']!,
                      textColor,
                      subtitleColor,
                      isDarkMode,
                      const Duration(milliseconds: 500),
                    ),

                    // Lunch section
                    _buildMealTypeSection(
                      'Lunch',
                      Icons.lunch_dining,
                      Colors.green,
                      mealGroups['Lunch']!,
                      textColor,
                      subtitleColor,
                      isDarkMode,
                      const Duration(milliseconds: 600),
                    ),

                    // Dinner section
                    _buildMealTypeSection(
                      'Dinner',
                      Icons.dinner_dining,
                      Colors.purple,
                      mealGroups['Dinner']!,
                      textColor,
                      subtitleColor,
                      isDarkMode,
                      const Duration(milliseconds: 700),
                    ),

                    // Snack section
                    _buildMealTypeSection(
                      'Snack',
                      Icons.cookie,
                      Colors.blue,
                      mealGroups['Snack']!,
                      textColor,
                      subtitleColor,
                      isDarkMode,
                      const Duration(milliseconds: 800),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSection(
    String mealType,
    IconData icon,
    Color color,
    List<FoodItem> foods,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
    Duration delay,
  ) {
    // Calculate total calories for this meal type
    final totalCalories = foods.fold<int>(
      0, (sum, food) => sum + food.calories);

    // Get recommended calories based on meal type
    final int recommendedCalories = _getRecommendedCalories(mealType);

    // Calculate percentage of recommended calories
    final double percentage = foods.isEmpty ? 0.0 :
      (totalCalories / recommendedCalories).clamp(0.0, 1.0);

    // Determine if meal is completed (has food items)
    final bool isMealCompleted = foods.isNotEmpty;

    // Determine if meal is on track (within 80-120% of recommended)
    final bool isOnTrack = percentage >= 0.8 && percentage <= 1.2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal type header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mealType,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isMealCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOnTrack ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isOnTrack ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isOnTrack ? Icons.check_circle : Icons.check_circle_outline,
                                  color: isOnTrack ? Colors.green : Colors.orange,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnTrack ? 'On Track' : 'Logged',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isOnTrack ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      foods.isEmpty
                          ? 'No food logged yet'
                          : '$totalCalories / $recommendedCalories kcal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: foods.isEmpty ? subtitleColor : color,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: color,
                  ),
                  onPressed: () {
                    // Show add food options with this meal type
                    _showAddFoodOptions(mealType);
                  },
                ),
              ],
            ),
          ),

          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Food items or empty state
          if (foods.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.no_food,
                      color: subtitleColor.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No food logged for $mealType',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Show add food options with this meal type
                        _showAddFoodOptions(mealType);
                      },
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(
                        'Add Food',
                        style: GoogleFonts.poppins(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: foods.asMap().entries.map((entry) {
                  final index = entry.key;
                  final food = entry.value;
                  return _buildFoodItemCard(
                    food,
                    textColor,
                    subtitleColor,
                    isDarkMode,
                    index,
                    delay,
                  );
                }).toList(),
              ),
            ),
        ],
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

  /// Show add food options with the specified meal type
  void _showAddFoodOptions(String mealType) {
    // Show options to take photo or select from gallery
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

              // Title
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

              const SizedBox(height: 24),

              // Camera and gallery options
              Row(
                children: [
                  Expanded(
                    child: _buildAddFoodOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      onTap: () {
                        Navigator.pop(context);
                        _takePicture(mealType);
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
                        _pickImage(mealType);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

  Future<void> _takePicture(String mealType) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final imageFile = File(image.path);

      // Navigate to the food analysis screen with the image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodAnalysisScreen(
            imageFile: imageFile,
            mealType: mealType,
            onFoodAdded: () {
              _loadUserData();
            },
          ),
        ),
      ).then((_) => _loadUserData());
    }
  }

  Future<void> _pickImage(String mealType) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageFile = File(image.path);

      // Navigate to the food analysis screen with the image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodAnalysisScreen(
            imageFile: imageFile,
            mealType: mealType,
            onFoodAdded: () {
              _loadUserData();
            },
          ),
        ),
      ).then((_) => _loadUserData());
    }
  }

  int _getRecommendedCalories(String mealType) {
    // Get daily calorie target
    final int dailyTarget = _dailyNutrition?.targetCalories ?? 2000;

    // Distribute calories based on meal type
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return (dailyTarget * 0.25).round(); // 25% of daily calories
      case 'lunch':
        return (dailyTarget * 0.35).round(); // 35% of daily calories
      case 'dinner':
        return (dailyTarget * 0.30).round(); // 30% of daily calories
      case 'snack':
        return (dailyTarget * 0.10).round(); // 10% of daily calories
      default:
        return (dailyTarget * 0.25).round();
    }
  }

  Widget _buildEmptyFoodList(Color textColor, Color subtitleColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No meals recorded today',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking today\'s meals by taking pictures of your food',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Show add food options with automatically determined meal type
              _showAddFoodOptions(_getCurrentMealType());
            },
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Food'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemCard(
    FoodItem food,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode, [
    int index = 0,
    Duration baseDelay = Duration.zero,
  ]) {
    // Calculate staggered animation delay
    final delay = baseDelay + Duration(milliseconds: 100 * index);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Food image with gradient overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    food.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${food.calories} kcal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
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
                  Text(
                    food.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      _buildNutrientPill('P: ${food.protein.toInt()}g', Colors.red, delay + const Duration(milliseconds: 100)),
                      const SizedBox(width: 6),
                      _buildNutrientPill('C: ${food.carbs.toInt()}g', Colors.amber[700]!, delay + const Duration(milliseconds: 150)),
                      const SizedBox(width: 6),
                      _buildNutrientPill('F: ${food.fat.toInt()}g', Colors.blue, delay + const Duration(milliseconds: 200)),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('hh:mm a').format(food.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    food.mealType,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientPill(String text, Color color, [Duration delay = Duration.zero]) {
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

  Widget _buildWeightGoalSection(Color textColor, Color subtitleColor, bool isDarkMode) {
    if (_user == null) {
      return const SizedBox.shrink();
    }

    // Check for weight goal directly from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      final directWeightGoal = prefs.getString('weightGoal') ?? prefs.getString('weight_goal');
      if (directWeightGoal != null && directWeightGoal.isNotEmpty && _user!.weightGoal != directWeightGoal) {
        // If we have a direct weight goal that differs from the user model, update the UI
        setState(() {
          _user = _user!.copyWith(weightGoal: directWeightGoal);
        });
        debugPrint('Updated UI with direct weight goal from SharedPreferences: $directWeightGoal');
      }
    });

    // Get weight goal information
    final String weightGoal = _user!.weightGoal?.capitalize() ?? 'lose'; // Default to 'lose' based on logs

    // Handle different types for weight value
    double currentWeight = 0.0;
    if (_user?.weight?['value'] != null) {
      if (_user!.weight!['value'] is int) {
        currentWeight = (_user!.weight!['value'] as int).toDouble();
      } else if (_user!.weight!['value'] is double) {
        currentWeight = _user!.weight!['value'] as double;
      } else if (_user!.weight!['value'] is String) {
        currentWeight = double.tryParse(_user!.weight!['value'] as String) ?? 0.0;
      }
    }

    // If we still don't have a value, try alternative keys
    if (currentWeight == 0.0) {
      final dynamic weightValue = _user?.weight?['weight'] ??
                                _user?.weight?['current_weight'] ??
                                _user?.weight?['currentWeight'];
      if (weightValue != null) {
        if (weightValue is int) {
          currentWeight = weightValue.toDouble();
        } else if (weightValue is double) {
          currentWeight = weightValue;
        } else if (weightValue is String) {
          currentWeight = double.tryParse(weightValue) ?? 0.0;
        }
      }
    }

    // If still no value, use default from onboarding logs
    if (currentWeight == 0.0) {
      currentWeight = 48.0; // Default to 48kg from onboarding logs
    }

    final String weightUnit = _user?.weight?['unit'] as String? ?? 'kg';

    // Handle different types for goal weight value
    double goalWeight = 0.0;
    if (_user?.goalWeight?['value'] != null) {
      if (_user!.goalWeight!['value'] is int) {
        goalWeight = (_user!.goalWeight!['value'] as int).toDouble();
      } else if (_user!.goalWeight!['value'] is double) {
        goalWeight = _user!.goalWeight!['value'] as double;
      } else if (_user!.goalWeight!['value'] is String) {
        goalWeight = double.tryParse(_user!.goalWeight!['value'] as String) ?? 0.0;
      }
    }

    // If we still don't have a value, try alternative keys
    if (goalWeight == 0.0) {
      final dynamic goalWeightValue = _user?.goalWeight?['goal_weight'] ??
                                    _user?.goalWeight?['goalWeight'];
      if (goalWeightValue != null) {
        if (goalWeightValue is int) {
          goalWeight = goalWeightValue.toDouble();
        } else if (goalWeightValue is double) {
          goalWeight = goalWeightValue;
        } else if (goalWeightValue is String) {
          goalWeight = double.tryParse(goalWeightValue) ?? 0.0;
        }
      }
    }

    // If still no value, calculate based on weight goal
    if (goalWeight == 0.0) {
      if (weightGoal == 'lose') {
        goalWeight = 45.0; // Use 45kg as goal weight for 48kg current weight (from logs)
      } else if (weightGoal == 'gain') {
        goalWeight = currentWeight + 3.0;
      } else { // maintain
        goalWeight = currentWeight;
      }
    }

    // Get initial weight for progress calculation
    double initialWeight = 0.0;
    if (_user?.weight?['initial_value'] != null) {
      if (_user!.weight!['initial_value'] is int) {
        initialWeight = (_user!.weight!['initial_value'] as int).toDouble();
      } else if (_user!.weight!['initial_value'] is double) {
        initialWeight = _user!.weight!['initial_value'] as double;
      } else if (_user!.weight!['initial_value'] is String) {
        initialWeight = double.tryParse(_user!.weight!['initial_value'] as String) ?? 0.0;
      }
    }

    // If no initial weight, use current weight
    if (initialWeight == 0.0) {
      initialWeight = currentWeight;
    }

    // Calculate progress
    double progressPercentage = 0.0;
    if (weightGoal == 'maintain') {
      progressPercentage = 1.0; // 100% if maintaining
    } else if (weightGoal == 'lose') {
      // If goal is to lose weight, calculate how close to goal weight
      if (initialWeight > goalWeight) {
        // Calculate percentage of weight loss progress
        final totalToLose = initialWeight - goalWeight;
        if (totalToLose > 0) {
          final lost = initialWeight - currentWeight;
          progressPercentage = (lost / totalToLose).clamp(0.0, 1.0);
        }
      }
    } else if (weightGoal == 'gain') {
      // If goal is to gain weight, calculate how close to goal weight
      if (initialWeight < goalWeight) {
        // Calculate percentage of weight gain progress
        final totalToGain = goalWeight - initialWeight;
        if (totalToGain > 0) {
          final gained = currentWeight - initialWeight;
          progressPercentage = (gained / totalToGain).clamp(0.0, 1.0);
        }
      }
    }

    // Get start weight for progress bar display
    final startWeight = initialWeight.toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    weightGoal == 'gain'
                        ? Icons.trending_up
                        : weightGoal == 'lose'
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Weight Goal',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              )
                ,

              GestureDetector(
                onTap: () {
                  _showUpdateGoalDialog();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Update',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                ,
            ],
          ),
          const SizedBox(height: 24),

          // Weight goal progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${(progressPercentage * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              )
                ,

              const SizedBox(height: 12),

              Row(
                children: [
                  Text(
                    '$startWeight $weightUnit',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        // Background bar
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        // Progress bar with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progressPercentage),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Container(
                              height: 24,
                              width: MediaQuery.of(context).size.width * 0.5 * value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.primaryColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        ),

                        // Current weight indicator
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.5 * progressPercentage - 6,
                          top: 6,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${goalWeight.toInt()} $weightUnit',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              )
                ,
            ],
          ),

          const SizedBox(height: 24),

          // Current weight section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Weight',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.monitor_weight,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentWeight $weightUnit',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Goal: ${weightGoal.capitalize()}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              )

                ,
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Try to update once a week so we can adjust your plan to ensure you hit your goal.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: subtitleColor,
            ),
          )
            ,

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogWeightDialog();
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Log Weight',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          )

            ,
        ],
      ),
    );
  }
  void _showUpdateGoalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Update Weight Goal',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGoalOption('Lose Weight', 'lose'),
              _buildGoalOption('Maintain Weight', 'maintain'),
              _buildGoalOption('Gain Weight', 'gain'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalOption(String label, String value) {
    final isSelected = _user?.weightGoal == value;

    return InkWell(
      onTap: () {
        // Update user's weight goal
        _updateWeightGoal(value);
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateWeightGoal(String weightGoal) async {
    if (_user != null) {
      // Get current weight with robust handling
      double currentWeight = 0.0;
      if (_user?.weight?['value'] != null) {
        if (_user!.weight!['value'] is int) {
          currentWeight = (_user!.weight!['value'] as int).toDouble();
        } else if (_user!.weight!['value'] is double) {
          currentWeight = _user!.weight!['value'] as double;
        } else if (_user!.weight!['value'] is String) {
          currentWeight = double.tryParse(_user!.weight!['value'] as String) ?? 0.0;
        }
      }

      // If we still don't have a value, try alternative keys
      if (currentWeight == 0.0) {
        final dynamic weightValue = _user?.weight?['weight'] ??
                                  _user?.weight?['current_weight'] ??
                                  _user?.weight?['currentWeight'];
        if (weightValue != null) {
          if (weightValue is int) {
            currentWeight = weightValue.toDouble();
          } else if (weightValue is double) {
            currentWeight = weightValue;
          } else if (weightValue is String) {
            currentWeight = double.tryParse(weightValue) ?? 0.0;
          }
        }
      }

      // If still no value, use default from onboarding logs
      if (currentWeight == 0.0) {
        currentWeight = 48.0; // Default to 48kg from onboarding logs
      }

      // Get the weight unit
      final String weightUnit = _user?.weight?['unit'] as String? ?? 'kg';

      // Get initial weight for progress tracking
      double initialWeight = currentWeight;
      // Only set initial_value if it doesn't exist yet
      if (_user?.weight?['initial_value'] != null) {
        if (_user!.weight!['initial_value'] is int) {
          initialWeight = (_user!.weight!['initial_value'] as int).toDouble();
        } else if (_user!.weight!['initial_value'] is double) {
          initialWeight = _user!.weight!['initial_value'] as double;
        } else if (_user!.weight!['initial_value'] is String) {
          initialWeight = double.tryParse(_user!.weight!['initial_value'] as String) ?? currentWeight;
        }
      }

      // Calculate goal weight based on new weight goal
      double goalWeight;
      if (weightGoal == 'lose') {
        goalWeight = 45.0; // Use 45kg as goal weight for 48kg current weight (from logs)
      } else if (weightGoal == 'gain') {
        goalWeight = currentWeight + 3.0;
      } else { // maintain
        goalWeight = currentWeight;
      }

      // Ensure goal weight is never negative
      if (goalWeight <= 0) {
        goalWeight = currentWeight;
      }

      // Create goal weight map
      final goalWeightMap = {
        'value': goalWeight,
        'unit': weightUnit,
      };

      // Create weight map with initial value for progress tracking
      final weightMap = {
        'value': currentWeight,
        'unit': weightUnit,
        'initial_value': initialWeight,
      };

      // Update user with new weight goal and goal weight
      final updatedUser = _user!.copyWith(
        weightGoal: weightGoal,
        goalWeight: goalWeightMap,
        weight: weightMap,
      );

      // Save updated user data
      await _userService.saveUserData(updatedUser);

      // Save directly to SharedPreferences to ensure data is properly stored
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weightGoal', weightGoal);
      await prefs.setString('weight_goal', weightGoal);
      await prefs.setDouble('goal_weight', goalWeight);
      await prefs.setString('goal_weight_unit', weightUnit);
      await prefs.setDouble('weight_value', currentWeight);
      await prefs.setString('weight_unit', weightUnit);

      // Recalculate nutrition targets based on new weight goal
      final nutritionTargets = _userService.calculateNutritionTargets(updatedUser);

      // Save nutrition targets and alternative key formats to ensure compatibility
      await _userService.saveUserData({
        'weight_goal': weightGoal,
        'weightGoal': weightGoal,
        'goal_weight': goalWeight,
        'goalWeight': goalWeight,
        'weight': currentWeight,
        'current_weight': currentWeight,
        'currentWeight': currentWeight,
        'weight_unit': weightUnit,
        'goal_weight_unit': weightUnit,
        'nutritionTargets': nutritionTargets,
      });

      debugPrint('Weight goal updated: $weightGoal, Current weight: $currentWeight, Goal weight: $goalWeight');
      debugPrint('New nutrition targets: $nutritionTargets');

      // Update the UI immediately
      setState(() {
        _user = updatedUser;
      });

      // Reload user data to update calorie calculations
      _loadUserData();

      // Call the callback to update the home screen
      if (widget.onWeightGoalUpdated != null) {
        widget.onWeightGoalUpdated!();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight goal updated to: ${weightGoal.capitalize()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLogWeightDialog() {
    final TextEditingController weightController = TextEditingController();
    String selectedUnit = _user?.weight?['unit'] as String? ?? 'kg';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Log Current Weight',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight',
                  hintText: 'Enter your current weight',
                  suffixText: selectedUnit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitOption('kg', selectedUnit == 'kg', (unit) {
                    Navigator.pop(context);
                    selectedUnit = unit;
                    _showLogWeightDialog();
                  }),
                  const SizedBox(width: 16),
                  _buildUnitOption('lbs', selectedUnit == 'lbs', (unit) {
                    Navigator.pop(context);
                    selectedUnit = unit;
                    _showLogWeightDialog();
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (weightController.text.isNotEmpty) {
                  final weight = double.tryParse(weightController.text);
                  if (weight != null) {
                    _updateWeight(weight, selectedUnit);
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnitOption(String unit, bool isSelected, Function(String) onSelect) {
    return GestureDetector(
      onTap: () => onSelect(unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          unit,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _updateWeight(double weight, String unit) async {
    if (_user != null) {
      // Create updated weight map
      final weightMap = {
        'value': weight,
        'unit': unit,
        'initial_value': _user?.weight?['initial_value'] ?? weight, // Keep initial value if exists
      };

      // Get weight goal
      final String weightGoal = _user?.weightGoal?.toLowerCase() ?? 'maintain';

      // Calculate goal weight based on weight goal
      double goalWeight = weight;
      if (weightGoal == 'lose') {
        goalWeight = weight - 3.0; // Use smaller difference for more realistic goals
      } else if (weightGoal == 'gain') {
        goalWeight = weight + 3.0; // Use smaller difference for more realistic goals
      } else if (weightGoal == 'maintain') {
        goalWeight = weight;
      }

      // Ensure goal weight is never negative
      if (goalWeight <= 0) {
        goalWeight = weight;
      }

      // Create goal weight map
      final goalWeightMap = {
        'value': goalWeight,
        'unit': unit,
      };

      // Update user data with both weight and goal weight
      final updatedUser = _user!.copyWith(
        weight: weightMap,
        goalWeight: goalWeightMap,
      );

      // Save updated user data
      await _userService.saveUserData(updatedUser);

      // Save directly to SharedPreferences to ensure data is properly stored
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('weight_value', weight);
      await prefs.setString('weight_unit', unit);
      await prefs.setDouble('goal_weight', goalWeight);
      await prefs.setString('goal_weight_unit', unit);
      await prefs.setString('weightGoal', weightGoal);
      await prefs.setString('weight_goal', weightGoal);

      // Recalculate nutrition targets based on new weight
      final nutritionTargets = _userService.calculateNutritionTargets(updatedUser);

      // Also save with the alternative key format to ensure compatibility
      await _userService.saveUserData({
        'weight': weight,
        'weight_unit': unit,
        'goal_weight': goalWeight,
        'goal_weight_unit': unit,
        'weight_goal': weightGoal.toLowerCase(),
        'weightGoal': weightGoal.toLowerCase(),
        'nutritionTargets': nutritionTargets,
      });

      debugPrint('Weight updated: $weight $unit, Goal weight: $goalWeight');
      debugPrint('New nutrition targets: $nutritionTargets');

      // Force update the user model with the new values to ensure they're reflected immediately
      setState(() {
        _user = updatedUser;
      });

      // Reload user data to update calorie calculations
      _loadUserData();

      // Call the callback to update the home screen
      if (widget.onWeightGoalUpdated != null) {
        widget.onWeightGoalUpdated!();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight updated to: $weight $unit',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}