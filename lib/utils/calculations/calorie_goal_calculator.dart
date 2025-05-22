import '../../models/user_model.dart';
import 'tdee_calculator.dart';

/// Calorie Goal Calculator
class CalorieGoalCalculator {
  /// Calculate daily calorie goal based on user's TDEE and weight goal
  /// Uses a more personalized approach based on the user's current weight and goal
  static int calculateCalorieGoal(UserModel? user) {
    if (user == null || user.weightGoal == null) {
      return 2000; // Default value if user or weight goal is missing
    }

    // Calculate TDEE
    double tdee = TDEECalculator.calculateTDEE(user);

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

    // Adjust based on weight goal and current weight
    switch (user.weightGoal) {
      case 'lose':
        // For heavier individuals, a slightly larger deficit is safe
        double deficit = weightInKg > 90 ? 600 : (weightInKg > 70 ? 500 : 400);
        return (tdee - deficit).round();
      case 'maintain':
        return tdee.round(); // Maintain current weight
      case 'gain':
        // For lighter individuals, a slightly smaller surplus is better for lean gains
        double surplus = weightInKg < 60 ? 400 : (weightInKg < 80 ? 500 : 600);
        return (tdee + surplus).round();
      default:
        return tdee.round();
    }
  }

  /// Calculate weekly weight change based on calorie goal
  /// Uses a more accurate calculation based on the actual calorie deficit/surplus
  static double calculateWeeklyWeightChange(UserModel? user) {
    if (user == null || user.weightGoal == null) {
      return 0.0;
    }

    // Calculate TDEE and calorie goal
    double tdee = TDEECalculator.calculateTDEE(user);
    int calorieGoal = calculateCalorieGoal(user);

    // Calculate daily calorie deficit/surplus
    double dailyCalorieDifference = calorieGoal - tdee;

    // 1 kg of fat is approximately 7700 calories
    // Weekly weight change = (daily calorie difference * 7) / 7700
    double weeklyWeightChange = (dailyCalorieDifference * 7) / 7700;

    // Round to 1 decimal place for better readability
    return double.parse(weeklyWeightChange.toStringAsFixed(1));
  }
}
