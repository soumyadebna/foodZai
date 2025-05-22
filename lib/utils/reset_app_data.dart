import 'package:shared_preferences/shared_preferences.dart';

/// Utility function to reset app data while preserving important user settings
Future<void> resetAppData() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Save important user data before clearing
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final calorieGoal = prefs.getInt('calorie_goal');
    final proteinGoal = prefs.getDouble('protein_goal');
    final carbsGoal = prefs.getDouble('carbs_goal');
    final fatGoal = prefs.getDouble('fat_goal');
    final weightGoal = prefs.getString('weightGoal');
    final themeMode = prefs.getString('theme_mode');

    // Clear all data
    await prefs.clear();

    // Restore important user data
    await prefs.setBool('onboarding_completed', onboardingCompleted);

    if (calorieGoal != null) {
      await prefs.setInt('calorie_goal', calorieGoal);
    }

    if (proteinGoal != null) {
      await prefs.setDouble('protein_goal', proteinGoal);
    }

    if (carbsGoal != null) {
      await prefs.setDouble('carbs_goal', carbsGoal);
    }

    if (fatGoal != null) {
      await prefs.setDouble('fat_goal', fatGoal);
    }

    if (weightGoal != null) {
      await prefs.setString('weightGoal', weightGoal);
    }

    if (themeMode != null) {
      await prefs.setString('theme_mode', themeMode);
    }

    print('App data reset successfully while preserving user settings');
  } catch (e) {
    print('Error resetting app data: $e');
  }
}
