import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../models/daily_nutrition.dart';
import '../utils/constants.dart';

class FoodDatabaseService {
  final Logger _logger = Logger();
  static const String _foodItemsKey = 'food_items';
  static const String _dailyNutritionKey = 'daily_nutrition';
  static const String _currentDayNutritionKey = 'current_day_nutrition';

  // Save a food item to the database
  Future<void> saveFoodItem(FoodItem foodItem) async {
    try {
      _logger.i('Saving food item: ${foodItem.name}');
      _logger.i('Food item details: ${foodItem.toJson()}');

      // Validate food item
      if (foodItem.calories < 0 || foodItem.protein < 0 || foodItem.carbs < 0 || foodItem.fat < 0) {
        _logger.e('Invalid food item values: calories=${foodItem.calories}, protein=${foodItem.protein}, carbs=${foodItem.carbs}, fat=${foodItem.fat}');
        throw Exception('Invalid food item values');
      }

      final prefs = await SharedPreferences.getInstance();

      // Get existing food items
      final List<FoodItem> foodItems = await getFoodItems();
      _logger.i('Got ${foodItems.length} existing food items');

      // Check for duplicates before adding
      bool isDuplicate = false;
      for (final item in foodItems) {
        if (item.name == foodItem.name &&
            item.calories == foodItem.calories &&
            item.timestamp.millisecondsSinceEpoch == foodItem.timestamp.millisecondsSinceEpoch) {
          isDuplicate = true;
          _logger.i('Duplicate food item detected, skipping: ${foodItem.name}');
          break;
        }
      }

      // Only add if not a duplicate
      if (!isDuplicate) {
        // Add the new food item
        foodItems.add(foodItem);

        // Convert to JSON and save as a single JSON string
        final foodItemsData = foodItems.map((item) => item.toJson()).toList();
        final String foodItemsJson = jsonEncode(foodItemsData);

        _logger.i('Saving ${foodItems.length} food items to SharedPreferences');
        final bool success = await prefs.setString(_foodItemsKey, foodItemsJson);

        if (!success) {
          _logger.e('Failed to save food items to SharedPreferences');
          throw Exception('Failed to save food items to SharedPreferences');
        }

        // Update daily nutrition data
        _logger.i('Updating daily nutrition data');
        await _updateDailyNutrition(foodItem);

        _logger.i('Food item saved successfully: ${foodItem.name}');
      }
    } catch (e) {
      _logger.e('Error saving food item: $e');
      throw Exception('Failed to save food item: $e');
    }
  }

  // Get all food items from the database
  Future<List<FoodItem>> getFoodItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get food items JSON string (same as UserService)
      final String? foodItemsData = prefs.getString(_foodItemsKey);

      if (foodItemsData == null || foodItemsData.isEmpty) {
        return [];
      }

      try {
        // Decode the JSON string to a list of maps
        final List<dynamic> decodedData = jsonDecode(foodItemsData);

        // Convert each map to a FoodItem
        return decodedData
            .map((item) => FoodItem.fromJson(item))
            .toList();
      } catch (e) {
        _logger.e('Error decoding food items JSON: $e');

        // Try the old format (List<String>) for backward compatibility
        try {
          final List<String>? foodItemsJson = prefs.getStringList(_foodItemsKey);

          if (foodItemsJson != null && foodItemsJson.isNotEmpty) {
            _logger.i('Found food items in old format, converting...');

            // Convert JSON to FoodItem objects
            final List<FoodItem> foodItems = foodItemsJson.map((json) {
              try {
                return FoodItem.fromJson(jsonDecode(json));
              } catch (e) {
                _logger.e('Error parsing food item: $e');
                return null;
              }
            }).whereType<FoodItem>().toList();

            // Save in the new format for next time
            if (foodItems.isNotEmpty) {
              final foodItemsData = foodItems.map((item) => item.toJson()).toList();
              await prefs.setString(_foodItemsKey, jsonEncode(foodItemsData));
              _logger.i('Converted ${foodItems.length} food items to new format');
            }

            return foodItems;
          }
        } catch (e2) {
          _logger.e('Error trying to read old format: $e2');
        }
      }

      return [];
    } catch (e) {
      _logger.e('Error getting food items: $e');
      return [];
    }
  }

  // Get food items for a specific date
  Future<List<FoodItem>> getFoodItemsForDate(DateTime date) async {
    try {
      final List<FoodItem> allFoodItems = await getFoodItems();

      // Filter food items by date
      final List<FoodItem> foodItemsForDate = allFoodItems.where((item) {
        final itemDate = item.timestamp;
        return itemDate.year == date.year &&
               itemDate.month == date.month &&
               itemDate.day == date.day;
      }).toList();

      return foodItemsForDate;
    } catch (e) {
      _logger.e('Error getting food items for date: $e');
      return [];
    }
  }

  // Get food items for a specific meal type
  Future<List<FoodItem>> getFoodItemsForMealType(String mealType) async {
    try {
      final List<FoodItem> allFoodItems = await getFoodItems();

      // Filter food items by meal type
      final List<FoodItem> foodItemsForMealType = allFoodItems.where((item) {
        return item.mealType.toLowerCase() == mealType.toLowerCase();
      }).toList();

      return foodItemsForMealType;
    } catch (e) {
      _logger.e('Error getting food items for meal type: $e');
      return [];
    }
  }

  // Delete a food item from the database
  Future<void> deleteFoodItem(FoodItem foodItem) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing food items
      final List<FoodItem> foodItems = await getFoodItems();

      // Remove the food item
      foodItems.removeWhere((item) =>
        item.name == foodItem.name &&
        item.timestamp.millisecondsSinceEpoch == foodItem.timestamp.millisecondsSinceEpoch
      );

      // Convert to JSON and save as a single JSON string (same as UserService)
      final foodItemsData = foodItems.map((item) => item.toJson()).toList();
      final String foodItemsJson = jsonEncode(foodItemsData);

      await prefs.setString(_foodItemsKey, foodItemsJson);

      // Update daily nutrition data
      await _removeFoodItemFromDailyNutrition(foodItem);

      _logger.i('Food item deleted: ${foodItem.name}');
    } catch (e) {
      _logger.e('Error deleting food item: $e');
      throw Exception('Failed to delete food item: $e');
    }
  }

  // Clear all food items from the database
  Future<void> clearFoodItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove both formats to ensure complete cleanup
      await prefs.remove(_foodItemsKey);

      // Also clear any StringList that might exist
      try {
        await prefs.setStringList(_foodItemsKey, []);
      } catch (e) {
        _logger.i('No StringList to clear: $e');
      }

      _logger.i('All food items cleared');
    } catch (e) {
      _logger.e('Error clearing food items: $e');
      throw Exception('Failed to clear food items: $e');
    }
  }

  // Get daily nutrition for a specific date
  Future<DailyNutrition?> getDailyNutrition(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Check if we're requesting today's data and if it's available in the faster access key
      final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final DateTime requestedDate = DateTime(date.year, date.month, date.day);

      if (today.isAtSameMomentAs(requestedDate)) {
        final String? currentDayData = prefs.getString(_currentDayNutritionKey);
        if (currentDayData != null) {
          _logger.i('Using current_day_nutrition for faster access');
          return DailyNutrition.fromJson(jsonDecode(currentDayData));
        }
      }

      // Fall back to the regular nutrition data
      final String? nutritionData = prefs.getString(_dailyNutritionKey);

      if (nutritionData == null) {
        return null;
      }

      final Map<String, dynamic> nutritionMap = jsonDecode(nutritionData);

      if (!nutritionMap.containsKey(dateString)) {
        return null;
      }

      return DailyNutrition.fromJson(nutritionMap[dateString]);
    } catch (e) {
      _logger.e('Error getting daily nutrition: $e');
      return null;
    }
  }

  // Update daily nutrition with a new food item
  Future<void> _updateDailyNutrition(FoodItem foodItem) async {
    try {
      _logger.i('Updating daily nutrition for ${foodItem.name}');

      // Validate food item
      if (foodItem.calories < 0 || foodItem.protein < 0 || foodItem.carbs < 0 || foodItem.fat < 0) {
        _logger.e('Invalid food item values: calories=${foodItem.calories}, protein=${foodItem.protein}, carbs=${foodItem.carbs}, fat=${foodItem.fat}');
        throw Exception('Invalid food item values');
      }

      final prefs = await SharedPreferences.getInstance();
      final date = DateTime(
        foodItem.timestamp.year,
        foodItem.timestamp.month,
        foodItem.timestamp.day,
      );

      // Format date as string for map key
      final String dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _logger.i('Date string: $dateString');

      // Get existing nutrition data or create new map
      Map<String, dynamic> nutritionData = {};
      final String? existingData = prefs.getString(_dailyNutritionKey);

      if (existingData != null && existingData.isNotEmpty) {
        try {
          nutritionData = jsonDecode(existingData);
          _logger.i('Loaded existing nutrition data with ${nutritionData.length} entries');
        } catch (e) {
          _logger.e('Error decoding existing nutrition data: $e');
          // Continue with empty map
        }
      } else {
        _logger.i('No existing nutrition data found, creating new data');
      }

      // Get or create today's nutrition data
      Map<String, dynamic> todayNutrition = {};
      if (nutritionData.containsKey(dateString)) {
        try {
          todayNutrition = Map<String, dynamic>.from(nutritionData[dateString]);
          _logger.i('Found existing nutrition data for today');
        } catch (e) {
          _logger.e('Error loading today\'s nutrition data: $e');
          // Create new data
          todayNutrition = {};
        }
      }

      // If today's nutrition data is empty or invalid, create default data
      if (todayNutrition.isEmpty ||
          !todayNutrition.containsKey('consumedCalories') ||
          !todayNutrition.containsKey('mealData')) {
        _logger.i('Creating default nutrition data for today');
        // Create default nutrition data
        todayNutrition = {
          'date': dateString,
          'targetCalories': AppConstants.defaultCalorieGoal,
          'targetProtein': AppConstants.defaultProteinGoal,
          'targetCarbs': AppConstants.defaultCarbsGoal,
          'targetFat': AppConstants.defaultFatGoal,
          'consumedCalories': 0,
          'consumedProtein': 0,
          'consumedCarbs': 0,
          'consumedFat': 0,
          'foodItems': [],
          'mealData': {
            'Breakfast': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
            'Lunch': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
            'Dinner': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
            'Snack': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
          },
        };
      }

      // Update consumed values
      _logger.i('Updating consumed values');

      // Check for duplicate food items to avoid double-counting
      bool isDuplicate = false;
      List<dynamic> existingFoodItems = todayNutrition['foodItems'] as List<dynamic>? ?? [];

      for (final existingItem in existingFoodItems) {
        if (existingItem is Map<String, dynamic> &&
            existingItem['name'] == foodItem.name &&
            existingItem['calories'] == foodItem.calories &&
            existingItem['timestamp'] == foodItem.timestamp.toIso8601String()) {
          isDuplicate = true;
          _logger.i('Found duplicate food item in daily nutrition, skipping update');
          break;
        }
      }

      // Only update if not a duplicate
      if (!isDuplicate) {
        todayNutrition['consumedCalories'] = (todayNutrition['consumedCalories'] as num? ?? 0) + foodItem.calories;
        todayNutrition['consumedProtein'] = (todayNutrition['consumedProtein'] as num? ?? 0) + foodItem.protein;
        todayNutrition['consumedCarbs'] = (todayNutrition['consumedCarbs'] as num? ?? 0) + foodItem.carbs;
        todayNutrition['consumedFat'] = (todayNutrition['consumedFat'] as num? ?? 0) + foodItem.fat;
      }

      // Add food item to the list only if it's not a duplicate
      _logger.i('Adding food item to the list');
      List<dynamic> foodItems = todayNutrition['foodItems'] as List<dynamic>? ?? [];

      if (!isDuplicate) {
        try {
          foodItems.add(foodItem.toJson());
          _logger.i('Added food item to list: ${foodItem.name}');
        } catch (e) {
          _logger.e('Error adding food item to list: $e');
          // Continue without adding to the list
        }
      } else {
        _logger.i('Skipped adding duplicate food item to list: ${foodItem.name}');
      }

      todayNutrition['foodItems'] = foodItems;

      // Update meal-specific data
      if (!todayNutrition.containsKey('mealData') || todayNutrition['mealData'] == null) {
        _logger.i('Creating default meal data');
        todayNutrition['mealData'] = {
          'Breakfast': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
          'Lunch': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
          'Dinner': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
          'Snack': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
        };
      }

      // Get the meal data for the specific meal type
      final mealType = foodItem.mealType;
      _logger.i('Updating meal data for $mealType');

      // Ensure the meal type exists in the meal data
      if (!todayNutrition['mealData'].containsKey(mealType)) {
        _logger.i('Creating default meal data for $mealType');
        todayNutrition['mealData'][mealType] = {
          'calories': 0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'items': [],
        };
      }

      Map<String, dynamic> mealData;
      try {
        mealData = Map<String, dynamic>.from(todayNutrition['mealData'][mealType]);
      } catch (e) {
        _logger.e('Error getting meal data for $mealType: $e');
        mealData = {
          'calories': 0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'items': [],
        };
      }

      // Update the meal data only if it's not a duplicate
      if (!isDuplicate) {
        mealData['calories'] = (mealData['calories'] as num? ?? 0) + foodItem.calories;
        mealData['protein'] = (mealData['protein'] as num? ?? 0.0) + foodItem.protein;
        mealData['carbs'] = (mealData['carbs'] as num? ?? 0.0) + foodItem.carbs;
        mealData['fat'] = (mealData['fat'] as num? ?? 0.0) + foodItem.fat;
        _logger.i('Updated meal data for ${foodItem.mealType}');
      } else {
        _logger.i('Skipped updating meal data for duplicate food item');
      }

      // Add the food item to the meal's items only if it's not a duplicate
      List<dynamic> mealItems = mealData['items'] as List<dynamic>? ?? [];

      // Check for duplicates in meal items
      bool isDuplicateInMeal = false;
      for (final existingItem in mealItems) {
        if (existingItem is Map<String, dynamic> &&
            existingItem['name'] == foodItem.name &&
            existingItem['calories'] == foodItem.calories &&
            existingItem['timestamp'] == foodItem.timestamp.toIso8601String()) {
          isDuplicateInMeal = true;
          _logger.i('Found duplicate food item in meal items, skipping');
          break;
        }
      }

      if (!isDuplicate && !isDuplicateInMeal) {
        try {
          // Convert the food item to a Map<String, Object> to ensure compatibility
          Map<String, dynamic> foodItemJson = foodItem.toJson();
          Map<String, Object> foodItemMap = {};

          // Handle each field in the food item
          foodItemJson.forEach((key, value) {
            if (value is Map) {
              // Convert nested maps
              foodItemMap[key] = Map<String, Object>.from(value);
            } else if (value is List) {
              // Convert lists
              List<Object> list = [];
              for (var item in value) {
                if (item is Map) {
                  list.add(Map<String, Object>.from(item));
                } else {
                  list.add(item);
                }
              }
              foodItemMap[key] = list;
            } else {
              foodItemMap[key] = value;
            }
          });

          mealItems.add(foodItemMap);
          _logger.i('Added food item to meal items: ${foodItem.name}');
        } catch (e) {
          _logger.e('Error adding food item to meal items: $e');
          // Continue without adding to the list
        }
      } else {
        _logger.i('Skipped adding duplicate food item to meal items');
      }

      mealData['items'] = mealItems;

      // Update the meal data in today's nutrition
      // Use a safer approach to update the meal data
      try {
        // First, ensure we have a proper Map for mealData
        if (todayNutrition['mealData'] is! Map) {
          _logger.w('mealData is not a Map, creating a new one');
          todayNutrition['mealData'] = {};
        }

        // Then update the specific meal type
        todayNutrition['mealData'][mealType] = Map<String, dynamic>.from(mealData);

        // Ensure mealData is properly converted to the correct type
        Map<String, dynamic> cleanMealData = {};
        (todayNutrition['mealData'] as Map).forEach((mealKey, mealValue) {
          if (mealValue is Map) {
            try {
              cleanMealData[mealKey.toString()] = Map<String, dynamic>.from(mealValue);
            } catch (e) {
              _logger.e('Error converting meal data for $mealKey: $e');
              // Create a new map with the same data but correct type
              Map<String, dynamic> safeMap = {};
              (mealValue as Map).forEach((k, v) {
                safeMap[k.toString()] = v;
              });
              cleanMealData[mealKey.toString()] = safeMap;
            }
          } else {
            cleanMealData[mealKey.toString()] = mealValue;
          }
        });
        todayNutrition['mealData'] = cleanMealData;
      } catch (e) {
        _logger.e('Error updating meal data in today\'s nutrition: $e');
        // Create a new mealData map with just this meal
        todayNutrition['mealData'] = {
          mealType: Map<String, dynamic>.from(mealData)
        };
      }

      // Update nutrition data
      nutritionData[dateString] = Map<String, dynamic>.from(todayNutrition);

      // Convert all nested maps to ensure they're the correct type
      final Map<String, dynamic> cleanNutritionData = {};
      nutritionData.forEach((key, value) {
        if (value is Map) {
          try {
            Map<String, dynamic> cleanValue = {};
            (value as Map).forEach((subKey, subValue) {
              final String subKeyStr = subKey.toString();

              if (subKeyStr == 'mealData' && subValue is Map) {
                // Handle mealData specially
                Map<String, dynamic> cleanMealData = {};
                try {
                  (subValue as Map).forEach((mealKey, mealValue) {
                    final String mealKeyStr = mealKey.toString();

                    if (mealValue is Map) {
                      try {
                        cleanMealData[mealKeyStr] = Map<String, dynamic>.from(mealValue);
                      } catch (e) {
                        _logger.e('Error converting meal data for $mealKeyStr: $e');
                        // Create a new map with the same data but correct type
                        Map<String, dynamic> safeMap = {};
                        (mealValue as Map).forEach((k, v) {
                          safeMap[k.toString()] = v;
                        });
                        cleanMealData[mealKeyStr] = safeMap;
                      }
                    } else {
                      cleanMealData[mealKeyStr] = mealValue;
                    }
                  });
                } catch (e) {
                  _logger.e('Error processing mealData: $e');
                  // Create a default meal data
                  cleanMealData = {
                    'Breakfast': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
                    'Lunch': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
                    'Dinner': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
                    'Snack': {'calories': 0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'items': []},
                  };
                }
                cleanValue[subKeyStr] = cleanMealData;
              } else if (subValue is Map) {
                try {
                  cleanValue[subKeyStr] = Map<String, dynamic>.from(subValue);
                } catch (e) {
                  _logger.e('Error converting map for $subKeyStr: $e');
                  // Create a new map with the same data but correct type
                  Map<String, dynamic> safeMap = {};
                  (subValue as Map).forEach((k, v) {
                    safeMap[k.toString()] = v;
                  });
                  cleanValue[subKeyStr] = safeMap;
                }
              } else {
                cleanValue[subKeyStr] = subValue;
              }
            });
            cleanNutritionData[key] = cleanValue;
          } catch (e) {
            _logger.e('Error processing nutrition data for date $key: $e');
            // Skip this entry if it's causing problems
          }
        } else {
          cleanNutritionData[key] = value;
        }
      });

      // Save back to SharedPreferences
      _logger.i('Saving nutrition data to SharedPreferences');

      // Convert cleanNutritionData to a simple Map<String, Object> for SharedPreferences
      final Map<String, Object> simpleNutritionData = {};

      // Handle nested maps properly
      cleanNutritionData.forEach((key, value) {
        if (value is Map) {
          try {
            // For nested maps, convert to a simple Map<String, Object>
            final Map<String, Object> simpleNestedMap = {};
            (value as Map).forEach((nestedKey, nestedValue) {
              final String nestedKeyStr = nestedKey.toString();

              if (nestedValue is Map) {
                try {
                  // For doubly nested maps (like mealData), convert again
                  final Map<String, Object> simpleDoubleNestedMap = {};
                  (nestedValue as Map).forEach((doubleNestedKey, doubleNestedValue) {
                    final String doubleNestedKeyStr = doubleNestedKey.toString();

                    try {
                      if (doubleNestedValue is Map) {
                        // For triply nested maps, convert again
                        Map<String, Object> simpleTripleNestedMap = {};
                        (doubleNestedValue as Map).forEach((tripleNestedKey, tripleNestedValue) {
                          simpleTripleNestedMap[tripleNestedKey.toString()] = tripleNestedValue ?? "";
                        });
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleTripleNestedMap;
                      } else if (doubleNestedValue is List) {
                        // For lists, make sure all items are of the correct type
                        List<Object> simpleList = [];
                        for (var item in doubleNestedValue) {
                          if (item is Map) {
                            try {
                              simpleList.add(Map<String, Object>.from(item));
                            } catch (e) {
                              // Create a new map with the same data but correct type
                              Map<String, Object> safeMap = {};
                              (item as Map).forEach((k, v) {
                                safeMap[k.toString()] = v ?? "";
                              });
                              simpleList.add(safeMap);
                            }
                          } else {
                            simpleList.add(item ?? "");
                          }
                        }
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleList;
                      } else {
                        simpleDoubleNestedMap[doubleNestedKeyStr] = doubleNestedValue ?? "";
                      }
                    } catch (e) {
                      _logger.e('Error processing doubly nested value for $doubleNestedKeyStr: $e');
                      simpleDoubleNestedMap[doubleNestedKeyStr] = "";
                    }
                  });
                  simpleNestedMap[nestedKeyStr] = simpleDoubleNestedMap;
                } catch (e) {
                  _logger.e('Error converting doubly nested map for $nestedKeyStr: $e');
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  try {
                    (nestedValue as Map).forEach((k, v) {
                      safeMap[k.toString()] = v ?? "";
                    });
                  } catch (e2) {
                    _logger.e('Error creating safe map for $nestedKeyStr: $e2');
                  }
                  simpleNestedMap[nestedKeyStr] = safeMap;
                }
              } else if (nestedValue is List) {
                try {
                  // For lists, make sure all items are of the correct type
                  final List<Object> simpleList = [];
                  for (var item in nestedValue) {
                    if (item is Map) {
                      try {
                        simpleList.add(Map<String, Object>.from(item));
                      } catch (e) {
                        // Create a new map with the same data but correct type
                        Map<String, Object> safeMap = {};
                        (item as Map).forEach((k, v) {
                          safeMap[k.toString()] = v ?? "";
                        });
                        simpleList.add(safeMap);
                      }
                    } else {
                      simpleList.add(item ?? "");
                    }
                  }
                  simpleNestedMap[nestedKeyStr] = simpleList;
                } catch (e) {
                  _logger.e('Error processing list for $nestedKeyStr: $e');
                  simpleNestedMap[nestedKeyStr] = [];
                }
              } else {
                simpleNestedMap[nestedKeyStr] = nestedValue ?? "";
              }
            });
            simpleNutritionData[key] = simpleNestedMap;
          } catch (e) {
            _logger.e('Error converting nested map for $key: $e');
            // Create a simple empty map as fallback
            simpleNutritionData[key] = <String, Object>{};
          }
        } else if (value is List) {
          try {
            // For lists, make sure all items are of the correct type
            final List<Object> simpleList = [];
            for (var item in value) {
              if (item is Map) {
                try {
                  simpleList.add(Map<String, Object>.from(item));
                } catch (e) {
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  (item as Map).forEach((k, v) {
                    safeMap[k.toString()] = v ?? "";
                  });
                  simpleList.add(safeMap);
                }
              } else {
                simpleList.add(item ?? "");
              }
            }
            simpleNutritionData[key] = simpleList;
          } catch (e) {
            _logger.e('Error converting list for $key: $e');
            simpleNutritionData[key] = [];
          }
        } else {
          simpleNutritionData[key] = value ?? "";
        }
      });

      final String nutritionJson = jsonEncode(simpleNutritionData);
      final bool success1 = await prefs.setString(_dailyNutritionKey, nutritionJson);

      if (!success1) {
        _logger.e('Failed to save nutrition data to SharedPreferences');
        throw Exception('Failed to save nutrition data to SharedPreferences');
      }

      // Also update the current day's data in a separate key for faster access
      _logger.i('Updating current day nutrition for faster access');

      // Convert cleanTodayNutrition to a simple Map<String, Object> for SharedPreferences
      final Map<String, Object> simpleTodayNutrition = {};
      final Map<String, dynamic> cleanTodayNutrition = Map<String, dynamic>.from(todayNutrition);

      // Handle nested maps properly
      cleanTodayNutrition.forEach((key, value) {
        if (value is Map) {
          try {
            // For nested maps, convert to a simple Map<String, Object>
            final Map<String, Object> simpleNestedMap = {};
            (value as Map).forEach((nestedKey, nestedValue) {
              final String nestedKeyStr = nestedKey.toString();

              if (nestedValue is Map) {
                try {
                  // For doubly nested maps (like mealData), convert again
                  final Map<String, Object> simpleDoubleNestedMap = {};
                  (nestedValue as Map).forEach((doubleNestedKey, doubleNestedValue) {
                    final String doubleNestedKeyStr = doubleNestedKey.toString();

                    try {
                      if (doubleNestedValue is Map) {
                        // For triply nested maps, convert again
                        Map<String, Object> simpleTripleNestedMap = {};
                        (doubleNestedValue as Map).forEach((tripleNestedKey, tripleNestedValue) {
                          simpleTripleNestedMap[tripleNestedKey.toString()] = tripleNestedValue ?? "";
                        });
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleTripleNestedMap;
                      } else if (doubleNestedValue is List) {
                        // For lists, make sure all items are of the correct type
                        List<Object> simpleList = [];
                        for (var item in doubleNestedValue) {
                          if (item is Map) {
                            try {
                              simpleList.add(Map<String, Object>.from(item));
                            } catch (e) {
                              // Create a new map with the same data but correct type
                              Map<String, Object> safeMap = {};
                              (item as Map).forEach((k, v) {
                                safeMap[k.toString()] = v ?? "";
                              });
                              simpleList.add(safeMap);
                            }
                          } else {
                            simpleList.add(item ?? "");
                          }
                        }
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleList;
                      } else {
                        simpleDoubleNestedMap[doubleNestedKeyStr] = doubleNestedValue ?? "";
                      }
                    } catch (e) {
                      _logger.e('Error processing doubly nested value for $doubleNestedKeyStr: $e');
                      simpleDoubleNestedMap[doubleNestedKeyStr] = "";
                    }
                  });
                  simpleNestedMap[nestedKeyStr] = simpleDoubleNestedMap;
                } catch (e) {
                  _logger.e('Error converting doubly nested map for $nestedKeyStr: $e');
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  try {
                    (nestedValue as Map).forEach((k, v) {
                      safeMap[k.toString()] = v ?? "";
                    });
                  } catch (e2) {
                    _logger.e('Error creating safe map for $nestedKeyStr: $e2');
                  }
                  simpleNestedMap[nestedKeyStr] = safeMap;
                }
              } else if (nestedValue is List) {
                try {
                  // For lists, make sure all items are of the correct type
                  final List<Object> simpleList = [];
                  for (var item in nestedValue) {
                    if (item is Map) {
                      try {
                        simpleList.add(Map<String, Object>.from(item));
                      } catch (e) {
                        // Create a new map with the same data but correct type
                        Map<String, Object> safeMap = {};
                        (item as Map).forEach((k, v) {
                          safeMap[k.toString()] = v ?? "";
                        });
                        simpleList.add(safeMap);
                      }
                    } else {
                      simpleList.add(item ?? "");
                    }
                  }
                  simpleNestedMap[nestedKeyStr] = simpleList;
                } catch (e) {
                  _logger.e('Error processing list for $nestedKeyStr: $e');
                  simpleNestedMap[nestedKeyStr] = [];
                }
              } else {
                simpleNestedMap[nestedKeyStr] = nestedValue ?? "";
              }
            });
            simpleTodayNutrition[key] = simpleNestedMap;
          } catch (e) {
            _logger.e('Error converting nested map for $key: $e');
            // Create a simple empty map as fallback
            simpleTodayNutrition[key] = <String, Object>{};
          }
        } else if (value is List) {
          try {
            // For lists, make sure all items are of the correct type
            final List<Object> simpleList = [];
            for (var item in value) {
              if (item is Map) {
                try {
                  simpleList.add(Map<String, Object>.from(item));
                } catch (e) {
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  (item as Map).forEach((k, v) {
                    safeMap[k.toString()] = v ?? "";
                  });
                  simpleList.add(safeMap);
                }
              } else {
                simpleList.add(item ?? "");
              }
            }
            simpleTodayNutrition[key] = simpleList;
          } catch (e) {
            _logger.e('Error converting list for $key: $e');
            simpleTodayNutrition[key] = [];
          }
        } else {
          simpleTodayNutrition[key] = value ?? "";
        }
      });

      final String todayJson = jsonEncode(simpleTodayNutrition);
      final bool success2 = await prefs.setString(_currentDayNutritionKey, todayJson);

      if (!success2) {
        _logger.e('Failed to save current day nutrition to SharedPreferences');
        throw Exception('Failed to save current day nutrition to SharedPreferences');
      }

      _logger.i('Daily nutrition updated successfully for ${foodItem.name}');
    } catch (e) {
      _logger.e('Error updating daily nutrition: $e');
      throw Exception('Failed to update daily nutrition: $e');
    }
  }

  // Remove a food item from daily nutrition
  Future<void> _removeFoodItemFromDailyNutrition(FoodItem foodItem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = DateTime(
        foodItem.timestamp.year,
        foodItem.timestamp.month,
        foodItem.timestamp.day,
      );

      // Format date as string for map key
      final String dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Get existing nutrition data
      final String? existingData = prefs.getString(_dailyNutritionKey);
      if (existingData == null) {
        return; // No nutrition data to update
      }

      Map<String, dynamic> nutritionData = jsonDecode(existingData);

      // Check if we have data for this date
      if (!nutritionData.containsKey(dateString)) {
        return; // No data for this date
      }

      Map<String, dynamic> todayNutrition = nutritionData[dateString];

      // Update consumed values
      todayNutrition['consumedCalories'] = (todayNutrition['consumedCalories'] ?? 0) - foodItem.calories;
      todayNutrition['consumedProtein'] = (todayNutrition['consumedProtein'] ?? 0) - foodItem.protein;
      todayNutrition['consumedCarbs'] = (todayNutrition['consumedCarbs'] ?? 0) - foodItem.carbs;
      todayNutrition['consumedFat'] = (todayNutrition['consumedFat'] ?? 0) - foodItem.fat;

      // Make sure we don't have negative values
      if (todayNutrition['consumedCalories'] < 0) todayNutrition['consumedCalories'] = 0;
      if (todayNutrition['consumedProtein'] < 0) todayNutrition['consumedProtein'] = 0;
      if (todayNutrition['consumedCarbs'] < 0) todayNutrition['consumedCarbs'] = 0;
      if (todayNutrition['consumedFat'] < 0) todayNutrition['consumedFat'] = 0;

      // Remove food item from the list
      List<dynamic> foodItems = todayNutrition['foodItems'] ?? [];
      foodItems.removeWhere((item) {
        if (item is Map<String, dynamic>) {
          return item['name'] == foodItem.name &&
                 item['timestamp'] == foodItem.timestamp.toIso8601String();
        }
        return false;
      });
      todayNutrition['foodItems'] = foodItems;

      // Update meal-specific data
      if (todayNutrition.containsKey('mealData')) {
        final mealType = foodItem.mealType;
        if (todayNutrition['mealData'].containsKey(mealType)) {
          Map<String, dynamic> mealData = Map<String, dynamic>.from(todayNutrition['mealData'][mealType]);

          // Update the meal data
          mealData['calories'] = (mealData['calories'] ?? 0) - foodItem.calories;
          mealData['protein'] = (mealData['protein'] ?? 0.0) - foodItem.protein;
          mealData['carbs'] = (mealData['carbs'] ?? 0.0) - foodItem.carbs;
          mealData['fat'] = (mealData['fat'] ?? 0.0) - foodItem.fat;

          // Make sure we don't have negative values
          if (mealData['calories'] < 0) mealData['calories'] = 0;
          if (mealData['protein'] < 0) mealData['protein'] = 0;
          if (mealData['carbs'] < 0) mealData['carbs'] = 0;
          if (mealData['fat'] < 0) mealData['fat'] = 0;

          // Remove food item from the meal's items
          List<dynamic> mealItems = mealData['items'] ?? [];
          mealItems.removeWhere((item) {
            if (item is Map<String, dynamic>) {
              return item['name'] == foodItem.name &&
                     item['timestamp'] == foodItem.timestamp.toIso8601String();
            }
            return false;
          });
          mealData['items'] = mealItems;

          // Update the meal data in today's nutrition
          todayNutrition['mealData'][mealType] = Map<String, dynamic>.from(mealData);
        }
      }

      // Ensure mealData is properly converted to the correct type
      if (todayNutrition.containsKey('mealData') && todayNutrition['mealData'] is Map) {
        Map<String, dynamic> cleanMealData = {};
        (todayNutrition['mealData'] as Map).forEach((mealKey, mealValue) {
          if (mealValue is Map) {
            cleanMealData[mealKey.toString()] = Map<String, dynamic>.from(mealValue);
          } else {
            cleanMealData[mealKey.toString()] = mealValue;
          }
        });
        todayNutrition['mealData'] = cleanMealData;
      }

      // Update nutrition data
      nutritionData[dateString] = Map<String, dynamic>.from(todayNutrition);

      // Convert all nested maps to ensure they're the correct type
      final Map<String, dynamic> cleanNutritionData = {};
      nutritionData.forEach((key, value) {
        if (value is Map) {
          Map<String, dynamic> cleanValue = {};
          (value as Map).forEach((subKey, subValue) {
            if (subKey.toString() == 'mealData' && subValue is Map) {
              // Handle mealData specially
              Map<String, dynamic> cleanMealData = {};
              (subValue as Map).forEach((mealKey, mealValue) {
                if (mealValue is Map) {
                  cleanMealData[mealKey.toString()] = Map<String, dynamic>.from(mealValue);
                } else {
                  cleanMealData[mealKey.toString()] = mealValue;
                }
              });
              cleanValue[subKey.toString()] = cleanMealData;
            } else if (subValue is Map) {
              cleanValue[subKey.toString()] = Map<String, dynamic>.from(subValue);
            } else {
              cleanValue[subKey.toString()] = subValue;
            }
          });
          cleanNutritionData[key] = cleanValue;
        } else {
          cleanNutritionData[key] = value;
        }
      });

      // Save back to SharedPreferences
      // Convert cleanNutritionData to a simple Map<String, Object> for SharedPreferences
      final Map<String, Object> simpleNutritionData = {};

      // Handle nested maps properly
      cleanNutritionData.forEach((key, value) {
        if (value is Map) {
          try {
            // For nested maps, convert to a simple Map<String, Object>
            final Map<String, Object> simpleNestedMap = {};
            (value as Map).forEach((nestedKey, nestedValue) {
              final String nestedKeyStr = nestedKey.toString();

              if (nestedValue is Map) {
                try {
                  // For doubly nested maps (like mealData), convert again
                  final Map<String, Object> simpleDoubleNestedMap = {};
                  (nestedValue as Map).forEach((doubleNestedKey, doubleNestedValue) {
                    final String doubleNestedKeyStr = doubleNestedKey.toString();

                    try {
                      if (doubleNestedValue is Map) {
                        // For triply nested maps, convert again
                        Map<String, Object> simpleTripleNestedMap = {};
                        (doubleNestedValue as Map).forEach((tripleNestedKey, tripleNestedValue) {
                          simpleTripleNestedMap[tripleNestedKey.toString()] = tripleNestedValue ?? "";
                        });
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleTripleNestedMap;
                      } else if (doubleNestedValue is List) {
                        // For lists, make sure all items are of the correct type
                        List<Object> simpleList = [];
                        for (var item in doubleNestedValue) {
                          if (item is Map) {
                            try {
                              simpleList.add(Map<String, Object>.from(item));
                            } catch (e) {
                              // Create a new map with the same data but correct type
                              Map<String, Object> safeMap = {};
                              (item as Map).forEach((k, v) {
                                safeMap[k.toString()] = v ?? "";
                              });
                              simpleList.add(safeMap);
                            }
                          } else {
                            simpleList.add(item ?? "");
                          }
                        }
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleList;
                      } else {
                        simpleDoubleNestedMap[doubleNestedKeyStr] = doubleNestedValue ?? "";
                      }
                    } catch (e) {
                      _logger.e('Error processing doubly nested value for $doubleNestedKeyStr: $e');
                      simpleDoubleNestedMap[doubleNestedKeyStr] = "";
                    }
                  });
                  simpleNestedMap[nestedKeyStr] = simpleDoubleNestedMap;
                } catch (e) {
                  _logger.e('Error converting doubly nested map for $nestedKeyStr: $e');
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  try {
                    (nestedValue as Map).forEach((k, v) {
                      safeMap[k.toString()] = v ?? "";
                    });
                  } catch (e2) {
                    _logger.e('Error creating safe map for $nestedKeyStr: $e2');
                  }
                  simpleNestedMap[nestedKeyStr] = safeMap;
                }
              } else if (nestedValue is List) {
                try {
                  // For lists, make sure all items are of the correct type
                  final List<Object> simpleList = [];
                  for (var item in nestedValue) {
                    if (item is Map) {
                      try {
                        simpleList.add(Map<String, Object>.from(item));
                      } catch (e) {
                        // Create a new map with the same data but correct type
                        Map<String, Object> safeMap = {};
                        (item as Map).forEach((k, v) {
                          safeMap[k.toString()] = v ?? "";
                        });
                        simpleList.add(safeMap);
                      }
                    } else {
                      simpleList.add(item ?? "");
                    }
                  }
                  simpleNestedMap[nestedKeyStr] = simpleList;
                } catch (e) {
                  _logger.e('Error processing list for $nestedKeyStr: $e');
                  simpleNestedMap[nestedKeyStr] = [];
                }
              } else {
                simpleNestedMap[nestedKeyStr] = nestedValue ?? "";
              }
            });
            simpleNutritionData[key] = simpleNestedMap;
          } catch (e) {
            _logger.e('Error converting nested map for $key: $e');
            // Create a simple empty map as fallback
            simpleNutritionData[key] = <String, Object>{};
          }
        } else if (value is List) {
          try {
            // For lists, make sure all items are of the correct type
            final List<Object> simpleList = [];
            for (var item in value) {
              if (item is Map) {
                try {
                  simpleList.add(Map<String, Object>.from(item));
                } catch (e) {
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  (item as Map).forEach((k, v) {
                    safeMap[k.toString()] = v ?? "";
                  });
                  simpleList.add(safeMap);
                }
              } else {
                simpleList.add(item ?? "");
              }
            }
            simpleNutritionData[key] = simpleList;
          } catch (e) {
            _logger.e('Error converting list for $key: $e');
            simpleNutritionData[key] = [];
          }
        } else {
          simpleNutritionData[key] = value ?? "";
        }
      });

      await prefs.setString(_dailyNutritionKey, jsonEncode(simpleNutritionData));

      // Also update the current day's data in a separate key for faster access
      final Map<String, dynamic> cleanTodayNutrition = Map<String, dynamic>.from(todayNutrition);

      // Convert cleanTodayNutrition to a simple Map<String, Object> for SharedPreferences
      final Map<String, Object> simpleTodayNutrition = {};

      // Handle nested maps properly
      cleanTodayNutrition.forEach((key, value) {
        if (value is Map) {
          try {
            // For nested maps, convert to a simple Map<String, Object>
            final Map<String, Object> simpleNestedMap = {};
            (value as Map).forEach((nestedKey, nestedValue) {
              final String nestedKeyStr = nestedKey.toString();

              if (nestedValue is Map) {
                try {
                  // For doubly nested maps (like mealData), convert again
                  final Map<String, Object> simpleDoubleNestedMap = {};
                  (nestedValue as Map).forEach((doubleNestedKey, doubleNestedValue) {
                    final String doubleNestedKeyStr = doubleNestedKey.toString();

                    try {
                      if (doubleNestedValue is Map) {
                        // For triply nested maps, convert again
                        Map<String, Object> simpleTripleNestedMap = {};
                        (doubleNestedValue as Map).forEach((tripleNestedKey, tripleNestedValue) {
                          simpleTripleNestedMap[tripleNestedKey.toString()] = tripleNestedValue ?? "";
                        });
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleTripleNestedMap;
                      } else if (doubleNestedValue is List) {
                        // For lists, make sure all items are of the correct type
                        List<Object> simpleList = [];
                        for (var item in doubleNestedValue) {
                          if (item is Map) {
                            try {
                              simpleList.add(Map<String, Object>.from(item));
                            } catch (e) {
                              // Create a new map with the same data but correct type
                              Map<String, Object> safeMap = {};
                              (item as Map).forEach((k, v) {
                                safeMap[k.toString()] = v ?? "";
                              });
                              simpleList.add(safeMap);
                            }
                          } else {
                            simpleList.add(item ?? "");
                          }
                        }
                        simpleDoubleNestedMap[doubleNestedKeyStr] = simpleList;
                      } else {
                        simpleDoubleNestedMap[doubleNestedKeyStr] = doubleNestedValue ?? "";
                      }
                    } catch (e) {
                      _logger.e('Error processing doubly nested value for $doubleNestedKeyStr: $e');
                      simpleDoubleNestedMap[doubleNestedKeyStr] = "";
                    }
                  });
                  simpleNestedMap[nestedKeyStr] = simpleDoubleNestedMap;
                } catch (e) {
                  _logger.e('Error converting doubly nested map for $nestedKeyStr: $e');
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  try {
                    (nestedValue as Map).forEach((k, v) {
                      safeMap[k.toString()] = v ?? "";
                    });
                  } catch (e2) {
                    _logger.e('Error creating safe map for $nestedKeyStr: $e2');
                  }
                  simpleNestedMap[nestedKeyStr] = safeMap;
                }
              } else if (nestedValue is List) {
                try {
                  // For lists, make sure all items are of the correct type
                  final List<Object> simpleList = [];
                  for (var item in nestedValue) {
                    if (item is Map) {
                      try {
                        simpleList.add(Map<String, Object>.from(item));
                      } catch (e) {
                        // Create a new map with the same data but correct type
                        Map<String, Object> safeMap = {};
                        (item as Map).forEach((k, v) {
                          safeMap[k.toString()] = v ?? "";
                        });
                        simpleList.add(safeMap);
                      }
                    } else {
                      simpleList.add(item ?? "");
                    }
                  }
                  simpleNestedMap[nestedKeyStr] = simpleList;
                } catch (e) {
                  _logger.e('Error processing list for $nestedKeyStr: $e');
                  simpleNestedMap[nestedKeyStr] = [];
                }
              } else {
                simpleNestedMap[nestedKeyStr] = nestedValue ?? "";
              }
            });
            simpleTodayNutrition[key] = simpleNestedMap;
          } catch (e) {
            _logger.e('Error converting nested map for $key: $e');
            // Create a simple empty map as fallback
            simpleTodayNutrition[key] = <String, Object>{};
          }
        } else if (value is List) {
          try {
            // For lists, make sure all items are of the correct type
            final List<Object> simpleList = [];
            for (var item in value) {
              if (item is Map) {
                try {
                  simpleList.add(Map<String, Object>.from(item));
                } catch (e) {
                  // Create a new map with the same data but correct type
                  Map<String, Object> safeMap = {};
                  (item as Map).forEach((k, v) {
                    safeMap[k.toString()] = v ?? "";
                  });
                  simpleList.add(safeMap);
                }
              } else {
                simpleList.add(item ?? "");
              }
            }
            simpleTodayNutrition[key] = simpleList;
          } catch (e) {
            _logger.e('Error converting list for $key: $e');
            simpleTodayNutrition[key] = [];
          }
        } else {
          simpleTodayNutrition[key] = value ?? "";
        }
      });

      await prefs.setString(_currentDayNutritionKey, jsonEncode(simpleTodayNutrition));

      _logger.i('Food item removed from daily nutrition: ${foodItem.name}');
      _logger.i('Updated current_day_nutrition for faster access');
    } catch (e) {
      _logger.e('Error removing food item from daily nutrition: $e');
      throw Exception('Failed to remove food item from daily nutrition: $e');
    }
  }
}
