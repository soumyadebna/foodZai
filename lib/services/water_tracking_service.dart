import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class WaterTrackingService {
  static const String _waterIntakeKey = 'water_intake';
  static const String _waterGoalKey = 'water_goal';
  static const int defaultWaterGoal = 12; // Default 12 glasses per day

  // Firebase service instance
  final FirebaseService _firebaseService = FirebaseService();
  
  // Check if user is signed in with Firebase
  bool get isUserSignedIn => FirebaseAuth.instance.currentUser != null;

  // Get water intake for a specific date
  Future<int> getWaterIntake(DateTime date) async {
    // If user is signed in with Firebase, try to get from Firestore first
    if (isUserSignedIn) {
      try {
        final firebaseWaterIntake = await _firebaseService.getWaterIntake(date);
        debugPrint('Retrieved water intake for date from Firebase: $firebaseWaterIntake');
        return firebaseWaterIntake;
      } catch (e) {
        debugPrint('Error getting water intake from Firebase: $e');
        // Continue to try SharedPreferences if Firebase fails
      }
    }

    // Fall back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return prefs.getInt('${_waterIntakeKey}_$dateKey') ?? 0;
  }

  // Set water intake for a specific date
  Future<void> setWaterIntake(DateTime date, int intake) async {
    // If user is signed in with Firebase, save to Firestore
    if (isUserSignedIn) {
      try {
        await _firebaseService.setWaterIntake(date, intake);
        debugPrint('Saved water intake to Firebase: $intake');
      } catch (e) {
        debugPrint('Error saving water intake to Firebase: $e');
        // Continue to save to SharedPreferences even if Firebase fails
      }
    }

    // Also save to SharedPreferences as fallback
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    await prefs.setInt('${_waterIntakeKey}_$dateKey', intake);
  }

  // Increment water intake for a specific date
  Future<int> incrementWaterIntake(DateTime date) async {
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
  Future<void> resetWaterIntake(DateTime date) async {
    await setWaterIntake(date, 0);
  }

  // Get water goal (number of glasses per day)
  Future<int> getWaterGoal() async {
    // If user is signed in with Firebase, try to get from Firestore first
    if (isUserSignedIn) {
      try {
        final firebaseWaterGoal = await _firebaseService.getWaterGoal();
        debugPrint('Retrieved water goal from Firebase: $firebaseWaterGoal');
        return firebaseWaterGoal;
      } catch (e) {
        debugPrint('Error getting water goal from Firebase: $e');
        // Continue to try SharedPreferences if Firebase fails
      }
    }

    // Fall back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_waterGoalKey) ?? defaultWaterGoal;
  }

  // Set water goal (number of glasses per day)
  Future<void> setWaterGoal(int goal) async {
    // If user is signed in with Firebase, save to Firestore
    if (isUserSignedIn) {
      try {
        await _firebaseService.setWaterGoal(goal);
        debugPrint('Saved water goal to Firebase: $goal');
      } catch (e) {
        debugPrint('Error saving water goal to Firebase: $e');
        // Continue to save to SharedPreferences even if Firebase fails
      }
    }

    // Also save to SharedPreferences as fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterGoalKey, goal);
  }

  // Get water intake progress (0.0 to 1.0)
  Future<double> getWaterProgress(DateTime date) async {
    final intake = await getWaterIntake(date);
    final goal = await getWaterGoal();
    return intake / goal;
  }
}
