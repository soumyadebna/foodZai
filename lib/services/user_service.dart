import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/food_item.dart';
import '../models/daily_nutrition.dart' as nutrition;
import '../utils/calculations/tdee_calculator.dart';
import '../utils/calculations/calorie_goal_calculator.dart';
import '../utils/calculations/macro_calculator.dart';
import 'firebase_service.dart';

class UserService {
  static const String _userKey = 'user_data';
  static const String _foodItemsKey = 'food_items';
  static const String _dailyNutritionKey = 'daily_nutrition';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  // Firebase service instance
  final FirebaseService _firebaseService = FirebaseService();

  // Check if user is signed in with Firebase
  bool get isUserSignedIn => FirebaseAuth.instance.currentUser != null;

  // Save user data to SharedPreferences and Firebase if signed in
  Future<void> saveUserData(dynamic userData) async {
    final prefs = await SharedPreferences.getInstance();
    UserModel? userModel;

    if (userData is UserModel) {
      // If userData is already a UserModel, save it directly
      userModel = userData;
      final userJson = jsonEncode(userData.toJson());
      await prefs.setString(_userKey, userJson);

      // Also save individual fields to SharedPreferences for direct access
      await _saveUserFieldsToPrefs(userData, prefs);
    } else if (userData is Map<String, dynamic>) {
      try {
        // First, try to get existing user data to avoid overwriting fields
        UserModel? existingUser;
        final existingUserData = prefs.getString(_userKey);
        if (existingUserData != null) {
          try {
            existingUser = UserModel.fromJson(jsonDecode(existingUserData));
          } catch (e) {
            print('Error parsing existing user data: $e');
          }
        }

        // Extract required fields from the map
        final String id = userData['id'] as String? ?? existingUser?.id ?? 'default_user_${DateTime.now().millisecondsSinceEpoch}';
        final String name = userData['name'] as String? ?? existingUser?.name ?? 'User';
        final String email = userData['email'] as String? ?? existingUser?.email ?? 'user@example.com';
        final String gender = userData['gender'] as String? ?? existingUser?.gender ?? 'male';
        final String activityLevel = userData['activity_level'] as String? ?? existingUser?.activityLevel ?? 'moderate';
        final String experience = userData['experience'] as String? ?? existingUser?.experience ?? 'beginner';
        final String weightGoal = userData['weight_goal'] as String? ?? userData['weightGoal'] as String? ?? existingUser?.weightGoal ?? 'maintain';

        // Extract weight and height
        Map<String, dynamic> weight;
        if (userData['weight'] != null) {
          if (userData['weight'] is Map) {
            weight = userData['weight'] as Map<String, dynamic>;
          } else if (userData['weight'] is num) {
            weight = {
              'value': userData['weight'],
              'unit': userData['weight_unit'] ?? 'kg',
            };
          } else {
            weight = existingUser?.weight ?? {'value': 48, 'unit': 'kg'}; // Default to 48kg from onboarding logs
          }
        } else {
          weight = existingUser?.weight ?? {'value': 48, 'unit': 'kg'}; // Default to 48kg from onboarding logs
        }

        Map<String, dynamic> height;
        if (userData['height'] != null) {
          if (userData['height'] is Map) {
            height = userData['height'] as Map<String, dynamic>;
          } else if (userData['height'] is num) {
            height = {
              'value': userData['height'],
              'unit': userData['height_unit'] ?? 'cm',
            };
          } else {
            height = existingUser?.height ?? {'value': 160, 'unit': 'cm'}; // Default to 160cm from onboarding logs
          }
        } else {
          height = existingUser?.height ?? {'value': 160, 'unit': 'cm'}; // Default to 160cm from onboarding logs
        }

        // Extract goal weight
        Map<String, dynamic>? goalWeight;
        if (userData['goal_weight'] != null) {
          if (userData['goal_weight'] is Map) {
            goalWeight = userData['goal_weight'] as Map<String, dynamic>;
          } else if (userData['goal_weight'] is num) {
            goalWeight = {
              'value': userData['goal_weight'],
              'unit': userData['goal_weight_unit'] ?? 'kg',
            };
          }
        } else if (userData['goalWeight'] != null) {
          if (userData['goalWeight'] is Map) {
            goalWeight = userData['goalWeight'] as Map<String, dynamic>;
          } else if (userData['goalWeight'] is num) {
            goalWeight = {
              'value': userData['goalWeight'],
              'unit': userData['goal_weight_unit'] ?? 'kg',
            };
          }
        } else {
          goalWeight = existingUser?.goalWeight;
        }

        // Extract date of birth
        DateTime? dateOfBirth;
        if (userData['date_of_birth'] != null) {
          dateOfBirth = userData['date_of_birth'] is DateTime
              ? userData['date_of_birth'] as DateTime
              : DateTime.parse(userData['date_of_birth'] as String);
        } else if (userData['dateOfBirth'] != null) {
          dateOfBirth = userData['dateOfBirth'] is DateTime
              ? userData['dateOfBirth'] as DateTime
              : DateTime.parse(userData['dateOfBirth'] as String);
        } else {
          dateOfBirth = existingUser?.dateOfBirth ?? DateTime(2002, 12, 14); // Default to date from logs
        }

        // Extract meal times
        List<Map<String, dynamic>>? mealTimes;
        if (userData['meal_times'] != null) {
          if (userData['meal_times'] is List) {
            mealTimes = (userData['meal_times'] as List)
                .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
                .toList();
          }
        } else if (userData['mealTimes'] != null) {
          if (userData['mealTimes'] is List) {
            mealTimes = (userData['mealTimes'] as List)
                .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
                .toList();
          }
        } else {
          mealTimes = existingUser?.mealTimes;
        }

        // Create UserModel
        final UserModel user = UserModel(
          id: id,
          name: name,
          email: email,
          gender: gender,
          activityLevel: activityLevel,
          experience: experience,
          weightGoal: weightGoal,
          weight: weight,
          height: height,
          goalWeight: goalWeight,
          dateOfBirth: dateOfBirth,
          mealTimes: mealTimes,
          createdAt: existingUser?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          onboardingCompleted: userData['onboarding_completed'] as bool? ?? existingUser?.onboardingCompleted ?? false,
        );

        userModel = user;

        // Save the user model to SharedPreferences
        final userJson = jsonEncode(user.toJson());
        await prefs.setString(_userKey, userJson);

        // Also save individual fields to SharedPreferences for direct access
        await _saveUserFieldsToPrefs(user, prefs);

        // Debug output
        debugPrint('Saved user data to SharedPreferences: ${user.toJson()}');
      } catch (e) {
        debugPrint('Error converting map to UserModel: $e');
        throw Exception('Failed to save user data: $e');
      }
    } else {
      throw Exception('Invalid user data type');
    }

    // If user is signed in with Firebase, also save to Firestore
    if (isUserSignedIn && userModel != null) {
      try {
        await _firebaseService.saveUserData(userModel);
        debugPrint('Saved user data to Firebase');
      } catch (e) {
        debugPrint('Error saving user data to Firebase: $e');
        // Continue even if Firebase save fails
      }
    }
  }

  // Helper method to save individual user fields to SharedPreferences
  Future<void> _saveUserFieldsToPrefs(UserModel user, SharedPreferences prefs) async {
    // Save gender
    if (user.gender != null) {
      await prefs.setString('gender', user.gender!);
    }

    // Save activity level
    if (user.activityLevel != null) {
      await prefs.setString('activity_level', user.activityLevel!);
    }

    // Save experience
    if (user.experience != null) {
      await prefs.setString('experience', user.experience!);
    }

    // Save weight goal
    if (user.weightGoal != null) {
      await prefs.setString('weightGoal', user.weightGoal!);
      await prefs.setString('weight_goal', user.weightGoal!);
    }

    // Save weight
    if (user.weight != null) {
      if (user.weight!['value'] != null) {
        double weightValue = 0.0;
        if (user.weight!['value'] is int) {
          weightValue = (user.weight!['value'] as int).toDouble();
        } else if (user.weight!['value'] is double) {
          weightValue = user.weight!['value'] as double;
        } else if (user.weight!['value'] is String) {
          weightValue = double.tryParse(user.weight!['value'] as String) ?? 0.0;
        }

        if (weightValue > 0) {
          await prefs.setDouble('weight_value', weightValue);
        }
      }

      if (user.weight!['unit'] != null) {
        await prefs.setString('weight_unit', user.weight!['unit'] as String);
      }
    }

    // Save height
    if (user.height != null) {
      if (user.height!['value'] != null) {
        double heightValue = 0.0;
        if (user.height!['value'] is int) {
          heightValue = (user.height!['value'] as int).toDouble();
        } else if (user.height!['value'] is double) {
          heightValue = user.height!['value'] as double;
        } else if (user.height!['value'] is String) {
          heightValue = double.tryParse(user.height!['value'] as String) ?? 0.0;
        }

        if (heightValue > 0) {
          await prefs.setDouble('height_value', heightValue);
        }
      }

      if (user.height!['unit'] != null) {
        await prefs.setString('height_unit', user.height!['unit'] as String);
      }
    }

    // Save goal weight
    if (user.goalWeight != null) {
      if (user.goalWeight!['value'] != null) {
        double goalWeightValue = 0.0;
        if (user.goalWeight!['value'] is int) {
          goalWeightValue = (user.goalWeight!['value'] as int).toDouble();
        } else if (user.goalWeight!['value'] is double) {
          goalWeightValue = user.goalWeight!['value'] as double;
        } else if (user.goalWeight!['value'] is String) {
          goalWeightValue = double.tryParse(user.goalWeight!['value'] as String) ?? 0.0;
        }

        if (goalWeightValue > 0) {
          await prefs.setDouble('goal_weight', goalWeightValue);
        }
      }

      if (user.goalWeight!['unit'] != null) {
        await prefs.setString('goal_weight_unit', user.goalWeight!['unit'] as String);
      }
    }

    // Save date of birth
    if (user.dateOfBirth != null) {
      await prefs.setString('date_of_birth', user.dateOfBirth!.toIso8601String());
    }
  }

  // Get user data from Firebase if signed in, otherwise from SharedPreferences
  Future<UserModel?> getUserData() async {
    try {
      // Import the global flag from main.dart
      final skipLoadingUserData = false; // Set to false to always load user data

      // Check if we should skip loading user data (for debugging)
      if (skipLoadingUserData) {
        debugPrint('Skip loading user data flag is set, returning default user');
        return _getDefaultUser();
      }

      // If user is signed in with Firebase, try to get data from Firestore first
      if (isUserSignedIn) {
        try {
          final firebaseUser = await _firebaseService.getUserData();
          if (firebaseUser != null) {
            debugPrint('Retrieved user data from Firebase');
            return firebaseUser;
          }
        } catch (e) {
          debugPrint('Error getting user data from Firebase: $e');
          // Continue to try SharedPreferences if Firebase fails
        }
      }

      // Fix any data type issues before loading user data from SharedPreferences
      // This is critical to prevent type errors when reading preferences
      await fixDataTypeIssues();

      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      // Try to build a user model from individual fields in SharedPreferences
      UserModel? userFromPrefs = await _getUserFromIndividualPrefs(prefs);

      if (userData != null) {
        try {
          // Parse the stored user model
          UserModel user = UserModel.fromJson(jsonDecode(userData));

          // If we have individual fields that might be more up-to-date, merge them
          if (userFromPrefs != null) {
            // Update with any newer individual fields
            user = _mergeUserData(user, userFromPrefs);

            // Save the merged user data back to ensure consistency
            // Use a try-catch to prevent errors during saving
            try {
              await saveUserData(user);
              debugPrint('Merged user data from individual preferences');
            } catch (e) {
              debugPrint('Error saving merged user data: $e');
              // Continue with the merged user even if saving fails
            }
          }

          // Check for direct weightGoal in SharedPreferences (highest priority)
          final directWeightGoal = prefs.getString('weightGoal');
          if (directWeightGoal != null && directWeightGoal.isNotEmpty && user.weightGoal != directWeightGoal) {
            // If we have a direct weight goal, use it
            final updatedUser = user.copyWith(
              weightGoal: directWeightGoal,
            );

            // Save the updated user data to ensure consistency
            try {
              await saveUserData(updatedUser);
              debugPrint('Updated UI with direct weight goal from SharedPreferences: $directWeightGoal');
              return updatedUser;
            } catch (e) {
              debugPrint('Error saving updated user with weight goal: $e');
              // Return the updated user even if saving fails
              return updatedUser;
            }
          }

          return user;
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          // If there's an error parsing the user data, try to use the individual fields
          if (userFromPrefs != null) {
            return userFromPrefs;
          }
        }
      } else if (userFromPrefs != null) {
        // If we don't have a stored user model but have individual fields, use those
        return userFromPrefs;
      }

      // If we couldn't load user data, return a default user
      final defaultUser = _getDefaultUser();

      // Save the default user
      try {
        await saveUserData(defaultUser);
        debugPrint('Created default user');
      } catch (e) {
        debugPrint('Error saving default user: $e');
        // Continue with the default user even if saving fails
      }

      return defaultUser;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return _getDefaultUser();
    }
  }

  // Helper method to get a default user
  UserModel _getDefaultUser() {
    return UserModel(
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
      onboardingCompleted: true, // Set to true to skip onboarding
    );
  }

  // Helper method to build a user model from individual fields in SharedPreferences
  Future<UserModel?> _getUserFromIndividualPrefs(SharedPreferences prefs) async {
    try {
      // Check if we have enough individual fields to build a user model
      final gender = prefs.getString('gender');
      final activityLevel = prefs.getString('activity_level');
      final weightGoal = prefs.getString('weightGoal') ?? prefs.getString('weight_goal');
      final weightValue = prefs.getDouble('weight_value');
      final weightUnit = prefs.getString('weight_unit');
      final heightValue = prefs.getDouble('height_value');
      final heightUnit = prefs.getString('height_unit');
      final goalWeightValue = prefs.getDouble('goal_weight');
      final goalWeightUnit = prefs.getString('goal_weight_unit');
      final dateOfBirthStr = prefs.getString('date_of_birth');

      // Only proceed if we have at least some basic data
      if (gender != null || activityLevel != null || weightGoal != null || weightValue != null) {
        // Build weight map
        Map<String, dynamic>? weight;
        if (weightValue != null) {
          weight = {
            'value': weightValue,
            'unit': weightUnit ?? 'kg',
          };
        }

        // Build height map
        Map<String, dynamic>? height;
        if (heightValue != null) {
          height = {
            'value': heightValue,
            'unit': heightUnit ?? 'cm',
          };
        }

        // Build goal weight map
        Map<String, dynamic>? goalWeight;
        if (goalWeightValue != null) {
          goalWeight = {
            'value': goalWeightValue,
            'unit': goalWeightUnit ?? 'kg',
          };
        }

        // Parse date of birth
        DateTime? dateOfBirth;
        if (dateOfBirthStr != null) {
          try {
            dateOfBirth = DateTime.parse(dateOfBirthStr);
          } catch (e) {
            debugPrint('Error parsing date of birth: $e');
          }
        }

        // Create user model
        return UserModel(
          id: 'user_from_prefs',
          gender: gender,
          activityLevel: activityLevel,
          weightGoal: weightGoal,
          weight: weight,
          height: height,
          goalWeight: goalWeight,
          dateOfBirth: dateOfBirth,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error building user from individual preferences: $e');
    }

    return null;
  }

  // Helper method to merge two user models, preferring non-null values from the second one
  UserModel _mergeUserData(UserModel base, UserModel overlay) {
    return UserModel(
      id: overlay.id ?? base.id,
      name: overlay.name ?? base.name,
      email: overlay.email ?? base.email,
      photoUrl: overlay.photoUrl ?? base.photoUrl,
      gender: overlay.gender ?? base.gender,
      activityLevel: overlay.activityLevel ?? base.activityLevel,
      experience: overlay.experience ?? base.experience,
      weightGoal: overlay.weightGoal ?? base.weightGoal,
      weight: overlay.weight ?? base.weight,
      height: overlay.height ?? base.height,
      goalWeight: overlay.goalWeight ?? base.goalWeight,
      dateOfBirth: overlay.dateOfBirth ?? base.dateOfBirth,
      mealTimes: overlay.mealTimes ?? base.mealTimes,
      nutritionTargets: overlay.nutritionTargets ?? base.nutritionTargets,
      createdAt: base.createdAt,
      updatedAt: DateTime.now(),
      onboardingCompleted: overlay.onboardingCompleted ?? base.onboardingCompleted,
    );
  }

  // Save food items to SharedPreferences and Firebase if signed in
  Future<void> saveFoodItems(List<FoodItem> foodItems) async {
    final prefs = await SharedPreferences.getInstance();
    final foodItemsData = foodItems.map((item) => item.toJson()).toList();
    await prefs.setString(_foodItemsKey, jsonEncode(foodItemsData));
  }

  // Get food items from Firebase if signed in, otherwise from SharedPreferences
  Future<List<FoodItem>> getFoodItems() async {
    // If user is signed in with Firebase, try to get data from Firestore first
    if (isUserSignedIn) {
      try {
        final firebaseFoodItems = await _firebaseService.getFoodItems();
        if (firebaseFoodItems.isNotEmpty) {
          debugPrint('Retrieved ${firebaseFoodItems.length} food items from Firebase');
          return firebaseFoodItems;
        }
      } catch (e) {
        debugPrint('Error getting food items from Firebase: $e');
        // Continue to try SharedPreferences if Firebase fails
      }
    }

    // Fall back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final foodItemsData = prefs.getString(_foodItemsKey);
    if (foodItemsData != null) {
      final List<dynamic> decodedData = jsonDecode(foodItemsData);
      return decodedData
          .map((item) => FoodItem.fromJson(item))
          .toList();
    }

    // Return empty list if no food items exist
    return [];
  }

  // Add a food item
  Future<void> addFoodItem(FoodItem foodItem) async {
    // If user is signed in with Firebase, save to Firestore
    if (isUserSignedIn) {
      try {
        await _firebaseService.saveFoodItem(foodItem);
        debugPrint('Saved food item to Firebase');
        return; // Skip SharedPreferences if Firebase save succeeds
      } catch (e) {
        debugPrint('Error saving food item to Firebase: $e');
        // Continue to save to SharedPreferences if Firebase fails
      }
    }

    // Fall back to SharedPreferences
    final foodItems = await getFoodItems();
    foodItems.add(foodItem);
    await saveFoodItems(foodItems);
  }

  // Remove a food item
  Future<void> removeFoodItem(FoodItem foodItem) async {
    // If user is signed in with Firebase, remove from Firestore
    if (isUserSignedIn) {
      try {
        await _firebaseService.removeFoodItem(foodItem);
        debugPrint('Removed food item from Firebase');
        return; // Skip SharedPreferences if Firebase remove succeeds
      } catch (e) {
        debugPrint('Error removing food item from Firebase: $e');
        // Continue to remove from SharedPreferences if Firebase fails
      }
    }

    // Fall back to SharedPreferences
    final foodItems = await getFoodItems();
    foodItems.removeWhere((item) =>
      item.name == foodItem.name &&
      item.timestamp.toString() == foodItem.timestamp.toString()
    );
    await saveFoodItems(foodItems);
  }

  // Get food items for a specific date
  Future<List<FoodItem>> getFoodItemsForDate(DateTime date) async {
    // If user is signed in with Firebase, get from Firestore
    if (isUserSignedIn) {
      try {
        final firebaseFoodItems = await _firebaseService.getFoodItemsForDate(date);
        if (firebaseFoodItems.isNotEmpty) {
          debugPrint('Retrieved ${firebaseFoodItems.length} food items for date from Firebase');
          return firebaseFoodItems;
        }
      } catch (e) {
        debugPrint('Error getting food items for date from Firebase: $e');
        // Continue to try SharedPreferences if Firebase fails
      }
    }

    // Fall back to SharedPreferences
    final foodItems = await getFoodItems();
    return foodItems.where((item) =>
      item.timestamp.year == date.year &&
      item.timestamp.month == date.month &&
      item.timestamp.day == date.day
    ).toList();
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if this is the first run of the app after installation
    if (!prefs.containsKey(_onboardingCompletedKey)) {
      // This is the first run, so onboarding is not completed
      return false;
    }

    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Set onboarding completed status
  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  // Check if this is the first run of the app
  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = !prefs.containsKey('first_run_completed');

    if (isFirstRun) {
      // Mark first run as completed
      await prefs.setBool('first_run_completed', true);
    }

    return isFirstRun;
  }

  // Reset all app data (for testing)
  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Fix any data type issues in SharedPreferences
  Future<void> fixDataTypeIssues() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys to check for type issues
      final keys = prefs.getKeys();
      debugPrint('Checking ${keys.length} SharedPreferences keys for data type issues');

      // Fields that should be stored as strings
      final stringFields = [
        'gender', 'activity_level', 'experience', 'weightGoal', 'weight_goal',
        'weight_unit', 'height_unit', 'goal_weight_unit', 'date_of_birth',
        'name', 'email', 'profile_image', 'user_id', 'auth_token'
      ];

      // Fields that should be stored as integers
      final intFields = [
        'calorie_goal', 'water_goal', 'height', 'weight'
      ];

      // Fields that should be stored as doubles
      final doubleFields = [
        'protein_goal', 'carbs_goal', 'fat_goal', 'goal_weight', 'goal_weight_value'
      ];

      // Fields that should be stored as booleans
      final boolFields = [
        'onboarding_completed', 'first_run_completed', 'water_notifications_enabled',
        'meal_notifications_enabled'
      ];

      // Check and fix string fields stored as lists
      for (final field in stringFields) {
        if (keys.contains(field)) {
          try {
            // Try to get as string first (normal case)
            final stringValue = prefs.getString(field);
            if (stringValue == null) {
              // If null, check if it's stored as a list
              try {
                final listValue = prefs.getStringList(field);
                if (listValue != null && listValue.isNotEmpty) {
                  debugPrint('Found $field as List<String>, fixing...');

                  // Remove the list
                  await prefs.remove(field);

                  // Set as a single string
                  await prefs.setString(field, listValue.first);
                  debugPrint('Fixed $field: ${listValue.first}');
                }
              } catch (e) {
                debugPrint('Error checking $field as list: $e');
              }
            }
          } catch (e) {
            debugPrint('Error checking $field: $e');
          }
        }
      }

      // Check and fix int fields stored incorrectly
      for (final field in intFields) {
        if (keys.contains(field)) {
          try {
            // Try to get as int first (normal case)
            final intValue = prefs.getInt(field);
            if (intValue == null) {
              // If null, check if it's stored as a string
              try {
                final stringValue = prefs.getString(field);
                if (stringValue != null) {
                  debugPrint('Found $field as String, fixing...');

                  // Try to parse as int
                  try {
                    final parsedInt = int.parse(stringValue);

                    // Remove the string
                    await prefs.remove(field);

                    // Set as int
                    await prefs.setInt(field, parsedInt);
                    debugPrint('Fixed $field: $parsedInt');
                  } catch (e) {
                    debugPrint('Error parsing $field as int: $e');
                  }
                }
              } catch (e) {
                debugPrint('Error checking $field as string: $e');
              }

              // Also check if it's stored as a list
              try {
                final listValue = prefs.getStringList(field);
                if (listValue != null && listValue.isNotEmpty) {
                  debugPrint('Found $field as List<String>, fixing...');

                  // Try to parse as int
                  try {
                    final parsedInt = int.parse(listValue.first);

                    // Remove the list
                    await prefs.remove(field);

                    // Set as int
                    await prefs.setInt(field, parsedInt);
                    debugPrint('Fixed $field: $parsedInt');
                  } catch (e) {
                    debugPrint('Error parsing $field from list as int: $e');
                  }
                }
              } catch (e) {
                debugPrint('Error checking $field as list: $e');
              }
            }
          } catch (e) {
            debugPrint('Error checking $field: $e');
          }
        }
      }

      // Check and fix double fields stored incorrectly
      for (final field in doubleFields) {
        if (keys.contains(field)) {
          try {
            // Try to get as double first (normal case)
            final doubleValue = prefs.getDouble(field);
            if (doubleValue == null) {
              // If null, check if it's stored as a string
              try {
                final stringValue = prefs.getString(field);
                if (stringValue != null) {
                  debugPrint('Found $field as String, fixing...');

                  // Try to parse as double
                  try {
                    final parsedDouble = double.parse(stringValue);

                    // Remove the string
                    await prefs.remove(field);

                    // Set as double
                    await prefs.setDouble(field, parsedDouble);
                    debugPrint('Fixed $field: $parsedDouble');
                  } catch (e) {
                    debugPrint('Error parsing $field as double: $e');
                  }
                }
              } catch (e) {
                debugPrint('Error checking $field as string: $e');
              }

              // Also check if it's stored as a list
              try {
                final listValue = prefs.getStringList(field);
                if (listValue != null && listValue.isNotEmpty) {
                  debugPrint('Found $field as List<String>, fixing...');

                  // Try to parse as double
                  try {
                    final parsedDouble = double.parse(listValue.first);

                    // Remove the list
                    await prefs.remove(field);

                    // Set as double
                    await prefs.setDouble(field, parsedDouble);
                    debugPrint('Fixed $field: $parsedDouble');
                  } catch (e) {
                    debugPrint('Error parsing $field from list as double: $e');
                  }
                }
              } catch (e) {
                debugPrint('Error checking $field as list: $e');
              }
            }
          } catch (e) {
            debugPrint('Error checking $field: $e');
          }
        }
      }

      // Check and fix boolean fields stored incorrectly
      for (final field in boolFields) {
        if (keys.contains(field)) {
          try {
            // Try to get as bool first (normal case)
            final boolValue = prefs.getBool(field);
            if (boolValue == null) {
              // If null, check if it's stored as a string
              try {
                final stringValue = prefs.getString(field);
                if (stringValue != null) {
                  debugPrint('Found $field as String, fixing...');

                  // Parse as bool
                  final parsedBool = stringValue.toLowerCase() == 'true';

                  // Remove the string
                  await prefs.remove(field);

                  // Set as bool
                  await prefs.setBool(field, parsedBool);
                  debugPrint('Fixed $field: $parsedBool');
                }
              } catch (e) {
                debugPrint('Error checking $field as string: $e');
              }

              // Also check if it's stored as a list
              try {
                final listValue = prefs.getStringList(field);
                if (listValue != null && listValue.isNotEmpty) {
                  debugPrint('Found $field as List<String>, fixing...');

                  // Parse as bool
                  final parsedBool = listValue.first.toLowerCase() == 'true';

                  // Remove the list
                  await prefs.remove(field);

                  // Set as bool
                  await prefs.setBool(field, parsedBool);
                  debugPrint('Fixed $field: $parsedBool');
                }
              } catch (e) {
                debugPrint('Error checking $field as list: $e');
              }
            }
          } catch (e) {
            debugPrint('Error checking $field: $e');
          }
        }
      }

      debugPrint('Data type issues fixed');
    } catch (e) {
      debugPrint('Error fixing data type issues: $e');
    }
  }

  // Calculate daily nutrition targets based on user data
  Future<Map<String, dynamic>> calculateNutritionTargets(UserModel user) async {
    // First check if we have stored values in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedCalories = prefs.getInt('calorie_goal');
    final storedProtein = prefs.getDouble('protein_goal');
    final storedCarbs = prefs.getDouble('carbs_goal');
    final storedFat = prefs.getDouble('fat_goal');

    // If we have all stored values, use them
    if (storedCalories != null && storedProtein != null && storedCarbs != null && storedFat != null) {
      return {
        'calories': storedCalories,
        'protein': storedProtein.round(),
        'carbs': storedCarbs.round(),
        'fat': storedFat.round(),
      };
    }

    // Otherwise calculate new values
    int calories = CalorieGoalCalculator.calculateCalorieGoal(user);
    Map<String, double> macros = MacroCalculator.calculateMacroTargets(user);

    // Store the calculated values for consistency
    await prefs.setInt('calorie_goal', calories);
    await prefs.setDouble('protein_goal', macros['protein']!);
    await prefs.setDouble('carbs_goal', macros['carbs']!);
    await prefs.setDouble('fat_goal', macros['fat']!);

    return {
      'calories': calories,
      'protein': macros['protein']!.round(),
      'carbs': macros['carbs']!.round(),
      'fat': macros['fat']!.round(),
    };
  }

  // Get daily nutrition for a specific date
  Future<nutrition.DailyNutrition> getDailyNutrition(DateTime date) async {
    // If user is signed in with Firebase, try to get from Firestore first
    if (isUserSignedIn) {
      try {
        final firebaseDailyNutrition = await _firebaseService.getDailyNutrition(date);
        if (firebaseDailyNutrition != null) {
          debugPrint('Retrieved daily nutrition for date from Firebase');
          return firebaseDailyNutrition;
        }
      } catch (e) {
        debugPrint('Error getting daily nutrition from Firebase: $e');
        // Continue to try local calculation if Firebase fails
      }
    }

    // Fall back to local calculation
    try {
      final user = await getUserData();
      final foodItems = await getFoodItemsForDate(date);

      if (user != null) {
        final nutritionTargets = await calculateNutritionTargets(user);

        final dailyNutrition = nutrition.DailyNutrition(
          targetCalories: nutritionTargets['calories'] as int,
          targetProtein: (nutritionTargets['protein'] as num).toDouble(),
          targetCarbs: (nutritionTargets['carbs'] as num).toDouble(),
          targetFat: (nutritionTargets['fat'] as num).toDouble(),
          date: date,
        );

        // Add food items to daily nutrition
        for (final foodItem in foodItems) {
          dailyNutrition.addFoodItem(foodItem);
        }

        // If user is signed in with Firebase, save to Firestore
        if (isUserSignedIn) {
          try {
            await _firebaseService.saveDailyNutrition(dailyNutrition);
            debugPrint('Saved daily nutrition to Firebase');
          } catch (e) {
            debugPrint('Error saving daily nutrition to Firebase: $e');
            // Continue even if Firebase save fails
          }
        }

        return dailyNutrition;
      }
    } catch (e) {
      debugPrint('Error getting nutrition for date $date: $e');
    }

    // Get values from SharedPreferences as fallback
    final prefs = await SharedPreferences.getInstance();
    final calories = prefs.getInt('calorie_goal') ?? 2000;
    final protein = prefs.getDouble('protein_goal') ?? 150.0;
    final carbs = prefs.getDouble('carbs_goal') ?? 200.0;
    final fat = prefs.getDouble('fat_goal') ?? 65.0;

    // Return default daily nutrition if user is null or there was an error
    return nutrition.DailyNutrition(
      targetCalories: calories,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFat: fat,
      date: date,
    );
  }
}
