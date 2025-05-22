import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WaterTracking {
  static const String _waterIntakeKey = 'water_intake';
  static const String _waterGoalKey = 'water_goal';
  static const int defaultWaterGoal = 12; // Default 12 glasses per day

  // Get water intake for a specific date
  static Future<int> getWaterIntake(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return prefs.getInt('${_waterIntakeKey}_$dateKey') ?? 0;
  }

  // Set water intake for a specific date
  static Future<void> setWaterIntake(DateTime date, int intake) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    await prefs.setInt('${_waterIntakeKey}_$dateKey', intake);
  }

  // Increment water intake for a specific date
  static Future<int> incrementWaterIntake(DateTime date) async {
    final currentIntake = await getWaterIntake(date);
    final waterGoal = await getWaterGoal();
    
    // Only increment if below goal
    if (currentIntake < waterGoal) {
      final newIntake = currentIntake + 1;
      await setWaterIntake(date, newIntake);
      return newIntake;
    }
    
    return currentIntake;
  }

  // Reset water intake for a specific date
  static Future<void> resetWaterIntake(DateTime date) async {
    await setWaterIntake(date, 0);
  }

  // Get water goal (number of glasses per day)
  static Future<int> getWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_waterGoalKey) ?? defaultWaterGoal;
  }

  // Set water goal (number of glasses per day)
  static Future<void> setWaterGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterGoalKey, goal);
  }

  // Get water intake progress (0.0 to 1.0)
  static Future<double> getWaterProgress(DateTime date) async {
    final intake = await getWaterIntake(date);
    final goal = await getWaterGoal();
    return intake / goal;
  }
}
