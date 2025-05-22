import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/daily_nutrition.dart';
import '../models/food_item.dart';
import '../services/user_service.dart';
import '../utils/calculations/calorie_goal_calculator.dart';
import '../utils/calculations/macro_calculator.dart';

/// A provider class for nutrition-related data
/// This ensures consistent nutrition goals across the app
class NutritionProvider extends ChangeNotifier {
  static const String _calorieGoalKey = 'calorie_goal';
  static const String _proteinGoalKey = 'protein_goal';
  static const String _carbsGoalKey = 'carbs_goal';
  static const String _fatGoalKey = 'fat_goal';

  final UserService _userService = UserService();

  // Cached values for quick access
  int _calorieGoal = 2000;
  double _proteinGoal = 150.0;
  double _carbsGoal = 250.0;
  double _fatGoal = 70.0;

  // Daily nutrition data for the current day
  DailyNutrition? _todayNutrition;

  // Getter for calorie goal
  int get calorieGoal => _calorieGoal;

  // Getter for protein goal
  double get proteinGoal => _proteinGoal;

  // Getter for carbs goal
  double get carbsGoal => _carbsGoal;

  // Getter for fat goal
  double get fatGoal => _fatGoal;

  // Getter for today's nutrition
  DailyNutrition? get todayNutrition => _todayNutrition;

  // Constructor
  NutritionProvider() {
    // Initialize immediately and asynchronously
    _initializeAsync();
  }

  // Initialize asynchronously
  Future<void> _initializeAsync() async {
    try {
      await _loadNutritionGoals();
      print('NutritionProvider initialized successfully');
    } catch (e) {
      print('Error initializing NutritionProvider: $e');
      // Try to recover with default values
      _calorieGoal = 2000;
      _proteinGoal = 150.0;
      _carbsGoal = 250.0;
      _fatGoal = 70.0;
      notifyListeners();
    }
  }

  /// Load nutrition goals from SharedPreferences or calculate them
  Future<void> _loadNutritionGoals() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to load from SharedPreferences first
    final storedCalorieGoal = prefs.getInt(_calorieGoalKey);
    final storedProteinGoal = prefs.getDouble(_proteinGoalKey);
    final storedCarbsGoal = prefs.getDouble(_carbsGoalKey);
    final storedFatGoal = prefs.getDouble(_fatGoalKey);

    if (storedCalorieGoal != null &&
        storedProteinGoal != null &&
        storedCarbsGoal != null &&
        storedFatGoal != null) {
      // Use stored values
      _calorieGoal = storedCalorieGoal;
      _proteinGoal = storedProteinGoal;
      _carbsGoal = storedCarbsGoal;
      _fatGoal = storedFatGoal;
    } else {
      // Calculate and store values
      await _calculateAndStoreNutritionGoals();
    }

    // Load today's nutrition
    await _loadTodayNutrition();

    // Notify listeners
    notifyListeners();
  }

  /// Calculate and store nutrition goals
  Future<void> _calculateAndStoreNutritionGoals() async {
    final user = await _userService.getUserData();
    if (user == null) return;

    // Calculate calorie goal
    _calorieGoal = CalorieGoalCalculator.calculateCalorieGoal(user);

    // Calculate macro goals
    final macros = MacroCalculator.calculateMacroTargets(user);
    _proteinGoal = macros['protein']!;
    _carbsGoal = macros['carbs']!;
    _fatGoal = macros['fat']!;

    // Store values in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calorieGoalKey, _calorieGoal);
    await prefs.setDouble(_proteinGoalKey, _proteinGoal);
    await prefs.setDouble(_carbsGoalKey, _carbsGoal);
    await prefs.setDouble(_fatGoalKey, _fatGoal);
  }

  /// Load today's nutrition data
  Future<void> _loadTodayNutrition() async {
    final today = DateTime.now();
    final foodItems = await _userService.getFoodItemsForDate(today);

    _todayNutrition = DailyNutrition(
      targetCalories: _calorieGoal,
      targetProtein: _proteinGoal,
      targetCarbs: _carbsGoal,
      targetFat: _fatGoal,
      date: today,
    );

    // Add food items
    for (final foodItem in foodItems) {
      _todayNutrition!.addFoodItem(foodItem);
    }
  }

  /// Update nutrition goals when user data changes
  Future<void> updateNutritionGoals() async {
    await _calculateAndStoreNutritionGoals();
    await _loadTodayNutrition();
    notifyListeners();
  }

  /// Get daily nutrition for a specific date
  Future<DailyNutrition> getDailyNutrition(DateTime date) async {
    final foodItems = await _userService.getFoodItemsForDate(date);

    final dailyNutrition = DailyNutrition(
      targetCalories: _calorieGoal,
      targetProtein: _proteinGoal,
      targetCarbs: _carbsGoal,
      targetFat: _fatGoal,
      date: date,
    );

    // Add food items
    for (final foodItem in foodItems) {
      dailyNutrition.addFoodItem(foodItem);
    }

    return dailyNutrition;
  }

  /// Add a food item to today's nutrition
  Future<void> addFoodItem(FoodItem foodItem) async {
    try {
      debugPrint('Adding food item: ${foodItem.name} with calories: ${foodItem.calories}, protein: ${foodItem.protein}, carbs: ${foodItem.carbs}, fat: ${foodItem.fat}, meal type: ${foodItem.mealType}');

      // Save the food item
      await _userService.addFoodItem(foodItem);

      // Reload today's nutrition
      await _loadTodayNutrition();

      // Notify listeners
      notifyListeners();

      debugPrint('Food item added successfully. Updated nutrition - Calories: ${_todayNutrition?.consumedCalories}, Protein: ${_todayNutrition?.consumedProtein}, Carbs: ${_todayNutrition?.consumedCarbs}, Fat: ${_todayNutrition?.consumedFat}');
    } catch (e) {
      debugPrint('Error adding food item: $e');
      // Try to recover
      await _loadTodayNutrition();
      notifyListeners();
    }
  }

  /// Remove a food item from today's nutrition
  Future<void> removeFoodItem(FoodItem foodItem) async {
    try {
      debugPrint('Removing food item: ${foodItem.name} with calories: ${foodItem.calories}, protein: ${foodItem.protein}, carbs: ${foodItem.carbs}, fat: ${foodItem.fat}, meal type: ${foodItem.mealType}');

      // Remove the food item
      await _userService.removeFoodItem(foodItem);

      // Reload today's nutrition
      await _loadTodayNutrition();

      // Notify listeners
      notifyListeners();

      debugPrint('Food item removed successfully. Updated nutrition - Calories: ${_todayNutrition?.consumedCalories}, Protein: ${_todayNutrition?.consumedProtein}, Carbs: ${_todayNutrition?.consumedCarbs}, Fat: ${_todayNutrition?.consumedFat}');
    } catch (e) {
      debugPrint('Error removing food item: $e');
      // Try to recover
      await _loadTodayNutrition();
      notifyListeners();
    }
  }

  /// Force refresh of nutrition data
  Future<void> refresh() async {
    debugPrint('Refreshing nutrition data');
    await _loadNutritionGoals();
    notifyListeners();
    debugPrint('Nutrition data refreshed - Calories: ${_todayNutrition?.consumedCalories}/${_calorieGoal}, Protein: ${_todayNutrition?.consumedProtein}/${_proteinGoal}, Carbs: ${_todayNutrition?.consumedCarbs}/${_carbsGoal}, Fat: ${_todayNutrition?.consumedFat}/${_fatGoal}');
  }
}
