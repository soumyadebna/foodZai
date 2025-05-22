import 'package:intl/intl.dart';
import 'food_item.dart';

class MealData {
  double calories = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  List<FoodItem> items = [];

  MealData({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    List<FoodItem>? initialItems,
  }) {
    if (initialItems != null) {
      items = initialItems;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory MealData.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double values
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is List && value.isNotEmpty) {
        var firstValue = value.first;
        if (firstValue is double) return firstValue;
        if (firstValue is int) return firstValue.toDouble();
        if (firstValue is String) return double.tryParse(firstValue) ?? 0.0;
      }
      return 0.0;
    }

    final mealData = MealData(
      calories: safeDouble(json['calories']),
      protein: safeDouble(json['protein']),
      carbs: safeDouble(json['carbs']),
      fat: safeDouble(json['fat']),
    );

    if (json['items'] != null) {
      try {
        final items = json['items'] as List;
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            mealData.items.add(FoodItem.fromJson(item));
          }
        }
      } catch (e) {
        print('Error parsing meal items: $e');
      }
    }

    return mealData;
  }
}

class DailyNutrition {
  final int targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final DateTime date;

  double consumedCalories = 0;
  double consumedProtein = 0;
  double consumedCarbs = 0;
  double consumedFat = 0;

  List<FoodItem> foodItems = [];

  // Meal-specific data
  Map<String, MealData> mealData = {
    'Breakfast': MealData(),
    'Lunch': MealData(),
    'Dinner': MealData(),
    'Snack': MealData(),
  };

  DailyNutrition({
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.date,
    double? consumedCalories,
    double? consumedProtein,
    double? consumedCarbs,
    double? consumedFat,
    List<FoodItem>? initialFoodItems,
    Map<String, MealData>? initialMealData,
  }) {
    this.consumedCalories = consumedCalories ?? 0;
    this.consumedProtein = consumedProtein ?? 0;
    this.consumedCarbs = consumedCarbs ?? 0;
    this.consumedFat = consumedFat ?? 0;

    if (initialFoodItems != null) {
      foodItems = initialFoodItems;
    }

    if (initialMealData != null) {
      mealData = initialMealData;
    }
  }

  void addFoodItem(FoodItem foodItem) {
    foodItems.add(foodItem);
    consumedCalories += foodItem.calories;
    consumedProtein += foodItem.protein;
    consumedCarbs += foodItem.carbs;
    consumedFat += foodItem.fat;

    // Update meal-specific data
    final mealType = foodItem.mealType;
    if (mealData.containsKey(mealType)) {
      final meal = mealData[mealType]!;
      meal.calories += foodItem.calories;
      meal.protein += foodItem.protein;
      meal.carbs += foodItem.carbs;
      meal.fat += foodItem.fat;
      meal.items.add(foodItem);
    }
  }

  void removeFoodItem(FoodItem foodItem) {
    foodItems.remove(foodItem);
    consumedCalories -= foodItem.calories;
    consumedProtein -= foodItem.protein;
    consumedCarbs -= foodItem.carbs;
    consumedFat -= foodItem.fat;

    // Update meal-specific data
    final mealType = foodItem.mealType;
    if (mealData.containsKey(mealType)) {
      final meal = mealData[mealType]!;
      meal.calories -= foodItem.calories;
      meal.protein -= foodItem.protein;
      meal.carbs -= foodItem.carbs;
      meal.fat -= foodItem.fat;

      // Make sure we don't have negative values
      if (meal.calories < 0) meal.calories = 0;
      if (meal.protein < 0) meal.protein = 0;
      if (meal.carbs < 0) meal.carbs = 0;
      if (meal.fat < 0) meal.fat = 0;

      // Remove the food item from the meal's items
      meal.items.removeWhere((item) =>
        item.name == foodItem.name &&
        item.timestamp.millisecondsSinceEpoch == foodItem.timestamp.millisecondsSinceEpoch
      );
    }
  }

  /// Recalculate nutrition totals based on the current food items
  void recalculateNutrition() {
    // Reset all nutrition values
    consumedCalories = 0;
    consumedProtein = 0;
    consumedCarbs = 0;
    consumedFat = 0;

    // Reset meal data
    for (final mealType in mealData.keys) {
      mealData[mealType] = MealData();
    }

    // Recalculate based on food items
    for (final foodItem in foodItems) {
      // Update total nutrition
      consumedCalories += foodItem.calories;
      consumedProtein += foodItem.protein;
      consumedCarbs += foodItem.carbs;
      consumedFat += foodItem.fat;

      // Update meal-specific data
      final mealType = foodItem.mealType;
      if (mealData.containsKey(mealType)) {
        final meal = mealData[mealType]!;
        meal.calories += foodItem.calories;
        meal.protein += foodItem.protein;
        meal.carbs += foodItem.carbs;
        meal.fat += foodItem.fat;
        meal.items.add(foodItem);
      }
    }
  }

  double get caloriesProgress => consumedCalories / targetCalories;
  double get proteinProgress => consumedProtein / targetProtein;
  double get carbsProgress => consumedCarbs / targetCarbs;
  double get fatProgress => consumedFat / targetFat;

  int get caloriesRemaining => targetCalories - consumedCalories.round();

  // Getters for percentage values
  double get caloriesPercentage => consumedCalories / targetCalories;
  double get proteinPercentage => consumedProtein / targetProtein;
  double get carbsPercentage => consumedCarbs / targetCarbs;
  double get fatPercentage => consumedFat / targetFat;

  // Getters for meal-specific data
  MealData getMealData(String mealType) {
    return mealData[mealType] ?? MealData();
  }

  double getMealCalories(String mealType) {
    return mealData[mealType]?.calories ?? 0;
  }

  double getMealProtein(String mealType) {
    return mealData[mealType]?.protein ?? 0;
  }

  double getMealCarbs(String mealType) {
    return mealData[mealType]?.carbs ?? 0;
  }

  double getMealFat(String mealType) {
    return mealData[mealType]?.fat ?? 0;
  }

  List<FoodItem> getMealItems(String mealType) {
    return mealData[mealType]?.items ?? [];
  }

  Map<String, dynamic> toJson() {
    // Convert meal data to JSON
    final Map<String, dynamic> mealDataJson = {};
    mealData.forEach((mealType, data) {
      mealDataJson[mealType] = data.toJson();
    });

    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'consumedCalories': consumedCalories,
      'consumedProtein': consumedProtein,
      'consumedCarbs': consumedCarbs,
      'consumedFat': consumedFat,
      'foodItems': foodItems.map((item) => item.toJson()).toList(),
      'mealData': mealDataJson,
    };
  }

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse date
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is String) {
        try {
          return DateFormat('yyyy-MM-dd').parse(dateValue);
        } catch (e) {
          print('Error parsing date string: $e');
        }
      } else if (dateValue is List && dateValue.isNotEmpty) {
        try {
          return DateFormat('yyyy-MM-dd').parse(dateValue.first.toString());
        } catch (e) {
          print('Error parsing date from list: $e');
        }
      }
      // Default to today if parsing fails
      return DateTime.now();
    }

    // Helper function to safely parse numeric values
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is List && value.isNotEmpty) {
        var firstValue = value.first;
        if (firstValue is int) return firstValue;
        if (firstValue is double) return firstValue.round();
        if (firstValue is String) return int.tryParse(firstValue) ?? 0;
      }
      return 0;
    }

    // Helper function to safely parse double values
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is List && value.isNotEmpty) {
        var firstValue = value.first;
        if (firstValue is double) return firstValue;
        if (firstValue is int) return firstValue.toDouble();
        if (firstValue is String) return double.tryParse(firstValue) ?? 0.0;
      }
      return 0.0;
    }

    final dailyNutrition = DailyNutrition(
      date: parseDate(json['date']),
      targetCalories: safeInt(json['targetCalories']),
      targetProtein: safeDouble(json['targetProtein']),
      targetCarbs: safeDouble(json['targetCarbs']),
      targetFat: safeDouble(json['targetFat']),
    );

    dailyNutrition.consumedCalories = safeDouble(json['consumedCalories']);
    dailyNutrition.consumedProtein = safeDouble(json['consumedProtein']);
    dailyNutrition.consumedCarbs = safeDouble(json['consumedCarbs']);
    dailyNutrition.consumedFat = safeDouble(json['consumedFat']);

    if (json['foodItems'] != null) {
      try {
        final foodItems = json['foodItems'];
        if (foodItems is List) {
          for (final item in foodItems) {
            if (item is Map<String, dynamic>) {
              try {
                dailyNutrition.foodItems.add(FoodItem.fromJson(item));
              } catch (e) {
                print('Error parsing food item: $e');
              }
            }
          }
        } else {
          print('Warning: foodItems is not a list: ${foodItems.runtimeType}');
        }
      } catch (e) {
        print('Error parsing food items: $e');
      }
    }

    // Parse meal-specific data
    if (json['mealData'] != null) {
      try {
        final mealDataJson = json['mealData'];
        Map<String, dynamic> mealDataMap;

        if (mealDataJson is Map) {
          mealDataMap = Map<String, dynamic>.from(mealDataJson);
        } else {
          // If mealData is not a map, create an empty map
          print('Warning: mealData is not a map: ${mealDataJson.runtimeType}');
          mealDataMap = {};
        }

        // Process each meal type
        for (final mealType in ['Breakfast', 'Lunch', 'Dinner', 'Snack']) {
          if (mealDataMap.containsKey(mealType)) {
            try {
              if (mealDataMap[mealType] is Map) {
                dailyNutrition.mealData[mealType] = MealData.fromJson(Map<String, dynamic>.from(mealDataMap[mealType]));
              } else {
                print('Warning: mealData[$mealType] is not a map: ${mealDataMap[mealType].runtimeType}');
              }
            } catch (e) {
              print('Error parsing meal data for $mealType: $e');
            }
          }
        }
      } catch (e) {
        print('Error parsing meal data: $e');
      }
    }

    return dailyNutrition;
  }
}
