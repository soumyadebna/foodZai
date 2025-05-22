import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/daily_nutrition.dart';
import '../utils/calculations/calorie_goal_calculator.dart';
import '../utils/calculations/macro_calculator.dart';
import 'user_service.dart';

/// A central service for nutrition-related functionality
class NutritionService {
  static const String _calorieGoalKey = 'calorie_goal';
  static const String _proteinGoalKey = 'protein_goal';
  static const String _carbsGoalKey = 'carbs_goal';
  static const String _fatGoalKey = 'fat_goal';

  final UserService _userService = UserService();

  /// Get the user's calorie goal
  Future<int> getCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();

    // First try to get from SharedPreferences for consistency
    final storedGoal = prefs.getInt(_calorieGoalKey);
    if (storedGoal != null) {
      return storedGoal;
    }

    // If not stored, calculate and store
    final user = await _userService.getUserData();
    // Handle null user
    if (user == null) {
      // Return a default value
      return 2000;
    }

    final calorieGoal = CalorieGoalCalculator.calculateCalorieGoal(user);

    // Store for future use
    await prefs.setInt(_calorieGoalKey, calorieGoal);

    return calorieGoal;
  }

  /// Get the user's protein goal in grams
  Future<double> getProteinGoal() async {
    final prefs = await SharedPreferences.getInstance();

    // First try to get from SharedPreferences for consistency
    final storedGoal = prefs.getDouble(_proteinGoalKey);
    if (storedGoal != null) {
      return storedGoal;
    }

    // If not stored, calculate and store
    final user = await _userService.getUserData();
    // Handle null user
    if (user == null) {
      // Return a default value
      return 150.0;
    }

    final macros = MacroCalculator.calculateMacroTargets(user);

    // Store for future use
    await prefs.setDouble(_proteinGoalKey, macros['protein']!);

    return macros['protein']!;
  }

  /// Get the user's carbs goal in grams
  Future<double> getCarbsGoal() async {
    final prefs = await SharedPreferences.getInstance();

    // First try to get from SharedPreferences for consistency
    final storedGoal = prefs.getDouble(_carbsGoalKey);
    if (storedGoal != null) {
      return storedGoal;
    }

    // If not stored, calculate and store
    final user = await _userService.getUserData();
    // Handle null user
    if (user == null) {
      // Return a default value
      return 250.0;
    }

    final macros = MacroCalculator.calculateMacroTargets(user);

    // Store for future use
    await prefs.setDouble(_carbsGoalKey, macros['carbs']!);

    return macros['carbs']!;
  }

  /// Get the user's fat goal in grams
  Future<double> getFatGoal() async {
    final prefs = await SharedPreferences.getInstance();

    // First try to get from SharedPreferences for consistency
    final storedGoal = prefs.getDouble(_fatGoalKey);
    if (storedGoal != null) {
      return storedGoal;
    }

    // If not stored, calculate and store
    final user = await _userService.getUserData();
    // Handle null user
    if (user == null) {
      // Return a default value
      return 70.0;
    }

    final macros = MacroCalculator.calculateMacroTargets(user);

    // Store for future use
    await prefs.setDouble(_fatGoalKey, macros['fat']!);

    return macros['fat']!;
  }

  /// Update nutrition goals when user data changes
  Future<void> updateNutritionGoals() async {
    final user = await _userService.getUserData();
    // Handle null user
    if (user == null) {
      return;
    }

    final calorieGoal = CalorieGoalCalculator.calculateCalorieGoal(user);
    final macros = MacroCalculator.calculateMacroTargets(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_calorieGoalKey, calorieGoal);
    await prefs.setDouble(_proteinGoalKey, macros['protein']!);
    await prefs.setDouble(_carbsGoalKey, macros['carbs']!);
    await prefs.setDouble(_fatGoalKey, macros['fat']!);
  }

  /// Get daily nutrition for a specific date
  Future<DailyNutrition> getDailyNutrition(DateTime date) async {
    // Get nutrition goals
    final calorieGoal = await getCalorieGoal();
    final proteinGoal = await getProteinGoal();
    final carbsGoal = await getCarbsGoal();
    final fatGoal = await getFatGoal();

    // Get food items for the date
    final foodItems = await _userService.getFoodItemsForDate(date);

    // Create daily nutrition object
    final dailyNutrition = DailyNutrition(
      targetCalories: calorieGoal,
      targetProtein: proteinGoal,
      targetCarbs: carbsGoal,
      targetFat: fatGoal,
      date: date,
    );

    // Add food items
    for (final foodItem in foodItems) {
      dailyNutrition.addFoodItem(foodItem);
    }

    return dailyNutrition;
  }
}
