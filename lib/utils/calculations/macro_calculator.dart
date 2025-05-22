import '../../models/user_model.dart';
import 'calorie_goal_calculator.dart';

/// Macronutrient Calculator
class MacroCalculator {
  // Calorie content per gram of macronutrients
  static const double _caloriesPerGramCarbs = 4.0;
  static const double _caloriesPerGramProtein = 4.0;
  static const double _caloriesPerGramFat = 9.0;

  // Default macronutrient distribution
  static const double _defaultCarbsPercentage = 0.50; // 50% of calories from carbs
  static const double _defaultProteinPercentage = 0.25; // 25% of calories from protein
  static const double _defaultFatPercentage = 0.25; // 25% of calories from fat

  /// Calculate macronutrient targets based on calorie goal and body weight
  /// Uses a more personalized approach based on the user's weight and activity level
  static Map<String, double> calculateMacroTargets(UserModel user) {
    // Get calorie goal
    int calorieGoal = CalorieGoalCalculator.calculateCalorieGoal(user);

    // Get weight in kg
    double weightInKg = 70.0; // Default weight if missing
    if (user.weight != null) {
      try {
        double weightValue = (user.weight!['value'] as num).toDouble();
        String unit = user.weight!['unit'] as String;

        if (unit == 'lbs') {
          weightInKg = weightValue * 0.453592; // Convert lbs to kg
        } else {
          weightInKg = weightValue; // Already in kg
        }
      } catch (e) {
        print('Error calculating weight in kg: $e');
      }
    }

    // Calculate protein based on body weight (higher for weight loss, moderate for maintenance, lower for gain)
    double proteinGramsPerKg;
    if (user.weightGoal == 'lose') {
      proteinGramsPerKg = 2.0; // Higher protein for weight loss (2.0g per kg)
    } else if (user.weightGoal == 'maintain') {
      proteinGramsPerKg = 1.6; // Moderate protein for maintenance (1.6g per kg)
    } else { // gain
      proteinGramsPerKg = 1.8; // Moderate-high protein for muscle gain (1.8g per kg)
    }

    // Calculate protein grams based on weight
    double proteinGrams = weightInKg * proteinGramsPerKg;

    // Calculate fat grams (minimum healthy amount is 0.8g per kg)
    double fatGramsPerKg;
    if (user.weightGoal == 'lose') {
      fatGramsPerKg = 0.8; // Minimum fat for weight loss (0.8g per kg)
    } else if (user.weightGoal == 'maintain') {
      fatGramsPerKg = 1.0; // Moderate fat for maintenance (1.0g per kg)
    } else { // gain
      fatGramsPerKg = 1.0; // Moderate fat for muscle gain (1.0g per kg)
    }

    // Calculate fat grams based on weight
    double fatGrams = weightInKg * fatGramsPerKg;

    // Calculate calories from protein and fat
    double proteinCalories = proteinGrams * _caloriesPerGramProtein;
    double fatCalories = fatGrams * _caloriesPerGramFat;

    // Calculate remaining calories for carbs
    double carbsCalories = calorieGoal - proteinCalories - fatCalories;

    // Calculate carbs grams
    double carbsGrams = carbsCalories / _caloriesPerGramCarbs;

    // Ensure minimum carbs (at least 100g for brain function)
    if (carbsGrams < 100) {
      carbsGrams = 100;
      // Recalculate fat to accommodate minimum carbs
      double carbsCalories = carbsGrams * _caloriesPerGramCarbs;
      double remainingCalories = calorieGoal - proteinCalories - carbsCalories;
      fatGrams = remainingCalories / _caloriesPerGramFat;
    }

    return {
      'carbs': carbsGrams,
      'protein': proteinGrams,
      'fat': fatGrams,
    };
  }
}
