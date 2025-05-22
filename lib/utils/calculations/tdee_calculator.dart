import '../../models/user_model.dart';

/// Total Daily Energy Expenditure Calculator
class TDEECalculator {
  /// Calculates TDEE using the Mifflin-St Jeor equation, which is more accurate
  /// for most individuals than the Institute of Medicine (IOM) equation.
  ///
  /// Mifflin MD, St Jeor ST, et al. A new predictive equation for resting energy
  /// expenditure in healthy individuals. Am J Clin Nutr. 1990;51(2):241-247.
  static double calculateTDEE(UserModel user) {
    if (user.gender == null ||
        user.dateOfBirth == null ||
        user.weight == null ||
        user.height == null ||
        user.activityLevel == null) {
      return 2000.0; // Default value if data is missing
    }

    // Calculate age
    final now = DateTime.now();
    final age = now.year - user.dateOfBirth!.year -
      (now.month > user.dateOfBirth!.month ||
      (now.month == user.dateOfBirth!.month && now.day >= user.dateOfBirth!.day) ? 0 : 1);

    // Get weight in kg
    double weightInKg = _getWeightInKg(user.weight!);

    // Get height in cm
    double heightInCm = _getHeightInCm(user.height!);

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (user.gender == 'male') {
      bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * age) - 161;
    }

    // Get activity multiplier
    double activityMultiplier = _getActivityMultiplier(user.activityLevel!);

    // Calculate TDEE
    double tdee = bmr * activityMultiplier;

    return tdee;
  }

  /// Get height in cm from height map
  static double _getHeightInCm(Map<String, dynamic> height) {
    double heightValue = (height['value'] as num).toDouble();
    String unit = height['unit'] as String;

    if (unit == 'cm') {
      return heightValue; // Already in cm
    } else if (unit == 'ft/in') {
      // Assuming the value is stored in total inches
      return heightValue * 2.54; // Convert inches to cm
    } else if (unit == 'm') {
      return heightValue * 100; // Convert meters to cm
    }

    return heightValue; // Default fallback
  }

  /// Get weight in kg from weight map
  static double _getWeightInKg(Map<String, dynamic> weight) {
    double weightValue = (weight['value'] as num).toDouble();
    String unit = weight['unit'] as String;

    if (unit == 'lbs') {
      return weightValue * 0.453592; // Convert lbs to kg
    }

    return weightValue; // Already in kg
  }

  /// Get height in meters from height map
  static double _getHeightInMeters(Map<String, dynamic> height) {
    double heightValue = (height['value'] as num).toDouble();
    String unit = height['unit'] as String;

    if (unit == 'cm') {
      return heightValue / 100; // Convert cm to meters
    } else if (unit == 'ft/in') {
      // Assuming the value is stored in total inches
      return heightValue * 0.0254; // Convert inches to meters
    }

    return heightValue; // Already in meters
  }

  /// Get activity multiplier based on activity level
  /// These are more accurate multipliers based on the Mifflin-St Jeor equation
  static double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel) {
      case 'sedentary':
        return 1.2; // Little or no exercise
      case 'low_active':
        return 1.375; // Light exercise 1-3 days/week
      case 'active':
        return 1.55; // Moderate exercise 3-5 days/week
      case 'very_active':
        return 1.725; // Hard exercise 6-7 days/week
      case 'extra_active':
        return 1.9; // Very hard exercise, physical job or training twice a day
      default:
        return 1.2; // Default to sedentary
    }
  }
}
