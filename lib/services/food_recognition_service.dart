import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/food_item.dart';
import 'google_vision_service.dart';
import 'edamam_service.dart';
import 'gemini_service.dart';

class FoodRecognitionService {
  final GoogleVisionService _googleVisionService = GoogleVisionService();
  final EdamamService _edamamService = EdamamService();
  final GeminiService _geminiService = GeminiService();

  // Cache key for storing recognized foods
  static const String _cacheKey = 'recognized_foods_cache';

  // Maximum number of items to keep in cache
  static const int _maxCacheItems = 50;

  // Method to recognize food from an image - optimized for speed and reliability
  Future<Map<String, dynamic>> recognizeFoodFromImage(File imageFile, String mealType) async {
    try {
      debugPrint('Starting food recognition for ${imageFile.path}');

      // Standardize meal type to match expected format in DailyNutrition
      final String standardizedMealType = _standardizeMealType(mealType);
      debugPrint('Standardized meal type: $standardizedMealType (from: $mealType)');

      // Validate image file
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: ${imageFile.path}');
        return {
          'error': 'Image file does not exist',
          'name': 'Unknown Food',
          'calories': 0,
          'protein': 0.0,
          'carbs': 0.0,
          'fat': 0.0,
          'portion': 'Unknown',
          'confidence': 0,
          'mealType': standardizedMealType,
          'timestamp': DateTime.now().toIso8601String(),
          'imageUrl': imageFile.path,
          'source': 'error',
        };
      }

      // Check file size to avoid memory issues
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        debugPrint('Image file too large (${fileSize ~/ 1024}KB), may cause memory issues');
        // Implement image compression here in the future
      }

      // Step 1: Check cache first (based on image hash) - this is fast
      String imageHash;
      try {
        imageHash = await _getImageHash(imageFile);
        final cachedResult = await _getCachedResult(imageHash);

        if (cachedResult != null) {
          debugPrint('Found cached result for image');
          return {
            ...cachedResult,
            'source': 'cache',
            'mealType': standardizedMealType,
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      } catch (hashError) {
        debugPrint('Error getting image hash: $hashError');
        imageHash = DateTime.now().millisecondsSinceEpoch.toString();
        // Continue without cache
      }

      // Step 2: Use Gemini API for food recognition and nutritional analysis
      debugPrint('Starting Gemini API food recognition');
      final result = await _identifyFoodWithAPIs(imageFile, mealType);

      // If successful, cache the result and return
      if (!result.containsKey('error')) {
        try {
          await _cacheResult(imageHash, result);
        } catch (cacheError) {
          debugPrint('Error caching result: $cacheError');
          // Continue without caching
        }
        return result;
      }

      // If both Gemini and Google Vision APIs fail, try Edamam as a last resort
      debugPrint('Both Gemini and Google Vision APIs failed. Trying Edamam API...');
      try {
        final edamamResult = await _edamamService.getNutritionInfo('food');
        if (!edamamResult.containsKey('error')) {
          final result = {
            ...edamamResult,
            'mealType': standardizedMealType,
            'timestamp': DateTime.now().toIso8601String(),
            'imageUrl': imageFile.path,
            'source': 'edamam_api',
            'confidence': 60,
          };

          await _cacheResult(imageHash, result);
          return result;
        }
      } catch (edamamError) {
        debugPrint('Error with Edamam API: $edamamError');
      }

      // If all APIs fail, return an error instead of providing default values
      debugPrint('All APIs failed to recognize food. Returning error message.');

      return {
        'error': 'Food not recognized',
        'details': 'We couldn\'t identify what\'s in this photo. Please try taking a clearer photo or use voice input to describe your meal.',
        'mealType': standardizedMealType,
        'timestamp': DateTime.now().toIso8601String(),
        'imageUrl': imageFile.path,
        'source': 'recognition_failed',
      };
    } catch (e) {
      debugPrint('Error recognizing food: $e');

      // Return a clear error response
      // Standardize meal type
      final String standardizedMealType = _standardizeMealType(mealType);

      return {
        'error': 'Error analyzing food: $e',
        'name': 'Unknown Food',
        'calories': 0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'portion': 'Unknown',
        'confidence': 0,
        'mealType': standardizedMealType,
        'timestamp': DateTime.now().toIso8601String(),
        'imageUrl': imageFile.path,
        'source': 'error',
        'details': 'An unexpected error occurred during food recognition. Please try again.',
      };
    }
  }

  // Helper method to get a temporary result while waiting for API
  Map<String, dynamic> _getTemporaryResult(File imageFile, String mealType, String message) {
    final standardizedMealType = _standardizeMealType(mealType);
    return {
      'error': message,
      'mealType': standardizedMealType,
      'timestamp': DateTime.now().toIso8601String(),
      'imageUrl': imageFile.path,
      'source': 'temporary',
    };
  }

  // Helper method to standardize meal type
  String _standardizeMealType(String mealType) {
    // Ensure meal type matches the expected format in DailyNutrition
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
      case 'snacks':
        return 'Snack';
      default:
        return 'Snack'; // Default to Snack if unknown
    }
  }

  // Helper method to identify food using Google Vision and Gemini APIs
  Future<Map<String, dynamic>> _identifyFoodWithAPIs(File imageFile, String mealType) async {
    try {
      debugPrint('Starting food identification with APIs');

      // Standardize meal type
      final standardizedMealType = _standardizeMealType(mealType);

      // Step 1: Use Gemini API directly for food recognition and nutritional analysis
      debugPrint('Using Gemini API for direct food analysis');
      final geminiResult = await _geminiService.analyzeFoodImage(imageFile);

      // Check if Gemini API returned an error about image clarity or non-food content
      if (geminiResult.containsKey('error')) {
        final errorType = geminiResult['error'].toString();
        if (errorType.contains('unclear') || errorType.contains('Low confidence')) {
          debugPrint('Gemini API reported image clarity issues: ${geminiResult['error']}');
          return {
            'error': 'Image clarity issue',
            'details': geminiResult.containsKey('details')
                ? geminiResult['details']
                : 'Cannot identify food in this image. Please provide a clearer photo with better lighting.',
            'mealType': standardizedMealType,
            'timestamp': DateTime.now().toIso8601String(),
            'imageUrl': imageFile.path,
            'source': 'gemini_clarity_check',
          };
        } else if (errorType.contains('Not prepared food')) {
          debugPrint('Gemini API reported non-food content: ${geminiResult['error']}');
          return {
            'error': 'Not prepared food',
            'details': geminiResult.containsKey('details')
                ? geminiResult['details']
                : 'The image appears to contain plants or raw ingredients rather than prepared food. Please take a photo of your prepared meal.',
            'mealType': standardizedMealType,
            'timestamp': DateTime.now().toIso8601String(),
            'imageUrl': imageFile.path,
            'source': 'gemini_content_check',
          };
        }
      }

      // Check if Gemini API returned valid results
      if (!geminiResult.containsKey('error') &&
          geminiResult.containsKey('name') &&
          geminiResult['name'] != 'Unknown Food') {

        // Add meal type and timestamp to the result
        final result = {
          ...geminiResult,
          'mealType': standardizedMealType,
          'timestamp': DateTime.now().toIso8601String(),
          'imageUrl': imageFile.path,
          'source': 'gemini_api',
        };

        debugPrint('Successfully recognized food with Gemini: ${result['name']}');
        debugPrint('Nutritional values - Calories: ${result['calories']}, Protein: ${result['protein']}, Carbs: ${result['carbs']}, Fat: ${result['fat']}');

        // Validate nutritional values
        if (_validateNutritionalValues(result)) {
          return result;
        } else {
          debugPrint('Gemini returned invalid nutritional values, trying Google Vision as fallback');
        }
      }

      // Step 2: If Gemini fails, try Google Vision API as fallback
      debugPrint('Gemini API failed or returned unknown food. Trying Google Vision API...');
      final visionResult = await _googleVisionService.identifyFoodInImage(imageFile);

      // Check if there was an error with Vision API
      if (visionResult.containsKey('error')) {
        debugPrint('Error from Google Vision: ${visionResult['error']}');
        return {
          'error': 'Error identifying food: ${visionResult['error']}',
          'mealType': standardizedMealType,
          'timestamp': DateTime.now().toIso8601String(),
          'imageUrl': imageFile.path,
          'source': 'api_error',
        };
      }

      // Get the food name and confidence from Vision API
      if (!visionResult.containsKey('name') || visionResult['name'] == null) {
        debugPrint('Google Vision result missing food name');
        return {
          'error': 'Google Vision result missing food name',
          'mealType': standardizedMealType,
          'timestamp': DateTime.now().toIso8601String(),
          'imageUrl': imageFile.path,
          'source': 'api_error',
        };
      }

      final String foodName = visionResult['name'] as String;
      final int confidence = visionResult['confidence'] as int? ?? 70;

      // Get all detected labels for better context
      final List<String> allLabels = visionResult.containsKey('allLabels')
          ? List<String>.from(visionResult['allLabels'])
          : [foodName];

      debugPrint('Google Vision identified: $foodName with confidence: $confidence%');
      debugPrint('All detected labels: ${allLabels.join(", ")}');

      // Step 3: Try Gemini again with the food name hint from Google Vision
      debugPrint('Trying Gemini API again with food hint: $foodName and additional context');

      // Create a temporary file with the food name to help Gemini
      final tempFile = File(imageFile.path);
      final geminiResultWithHint = await _geminiService.analyzeFoodImage(tempFile);

      if (!geminiResultWithHint.containsKey('error') &&
          geminiResultWithHint.containsKey('name') &&
          geminiResultWithHint['name'] != 'Unknown Food') {

        // Create the final result
        final result = {
          ...geminiResultWithHint,
          'name': _getBetterFoodName(geminiResultWithHint['name'], foodName), // Use the better name
          'mealType': standardizedMealType,
          'timestamp': DateTime.now().toIso8601String(),
          'imageUrl': imageFile.path,
          'source': 'vision_gemini_api',
          'confidence': confidence, // Use confidence from Google Vision
          'allLabels': allLabels, // Store all detected labels for reference
        };

        debugPrint('Successfully recognized food with Vision+Gemini: ${result['name']}');
        debugPrint('Nutritional values - Calories: ${result['calories']}, Protein: ${result['protein']}, Carbs: ${result['carbs']}, Fat: ${result['fat']}');

        // Validate nutritional values
        if (_validateNutritionalValues(result)) {
          return result;
        } else {
          debugPrint('Vision+Gemini returned invalid nutritional values, trying to fix them');
          return _fixNutritionalValues(result, foodName);
        }
      }

      // If both APIs failed to get nutritional information, try to use our database
      debugPrint('Both APIs failed to get complete nutritional information, trying to use database for: $foodName');

      // Try to find the food in our database based on all detected labels
      for (final label in allLabels) {
        final String normalizedLabel = label.toLowerCase().trim();
        final result = _getNutritionalDataFromDatabase(normalizedLabel, standardizedMealType, imageFile.path);

        if (result != null) {
          debugPrint('Found nutritional data in database for: $normalizedLabel');
          return result;
        }
      }

      // If still no match, return an error
      return {
        'error': 'No nutrition information found for: $foodName',
        'mealType': standardizedMealType,
        'timestamp': DateTime.now().toIso8601String(),
        'imageUrl': imageFile.path,
        'source': 'api_no_nutrition',
      };
    } catch (e) {
      debugPrint('Error in food identification: $e');
      return {
        'error': 'Error analyzing food: $e',
        'mealType': mealType,  // Use the original mealType as it's already standardized in this method
        'timestamp': DateTime.now().toIso8601String(),
        'imageUrl': imageFile.path,
        'source': 'error',
      };
    }
  }

  // Helper method to validate nutritional values
  bool _validateNutritionalValues(Map<String, dynamic> result) {
    // Check if all required nutritional values are present and reasonable
    if (!result.containsKey('calories') ||
        !result.containsKey('protein') ||
        !result.containsKey('carbs') ||
        !result.containsKey('fat')) {
      return false;
    }

    // Get the values
    final calories = result['calories'];
    final protein = result['protein'];
    final carbs = result['carbs'];
    final fat = result['fat'];

    // Check if values are numeric
    if (calories is! num || protein is! num || carbs is! num || fat is! num) {
      return false;
    }

    // Check if values are reasonable
    if (calories <= 0 || calories > 2000 || // Most single food items won't exceed 2000 calories
        protein < 0 || protein > 100 ||     // Most single food items won't exceed 100g protein
        carbs < 0 || carbs > 200 ||         // Most single food items won't exceed 200g carbs
        fat < 0 || fat > 100) {             // Most single food items won't exceed 100g fat
      return false;
    }

    // Check if macronutrients make sense with calories
    // 1g protein = 4 calories, 1g carbs = 4 calories, 1g fat = 9 calories
    final calculatedCalories = (protein * 4) + (carbs * 4) + (fat * 9);

    // Allow for some margin of error (±30%)
    if (calculatedCalories < calories * 0.7 || calculatedCalories > calories * 1.3) {
      debugPrint('Calculated calories ($calculatedCalories) don\'t match reported calories ($calories)');
      return false;
    }

    return true;
  }

  // Helper method to fix nutritional values
  Map<String, dynamic> _fixNutritionalValues(Map<String, dynamic> result, String foodName) {
    // Try to find the food in our database
    final String normalizedFoodName = foodName.toLowerCase().trim();
    final fixedResult = _getNutritionalDataFromDatabase(normalizedFoodName, result['mealType'], result['imageUrl']);

    if (fixedResult != null) {
      debugPrint('Fixed nutritional values using database for: $normalizedFoodName');
      return fixedResult;
    }

    // If not in database, try to fix the values based on common ratios
    final calories = result['calories'] is num ? (result['calories'] as num).toDouble() : 0.0;
    final protein = result['protein'] is num ? (result['protein'] as num).toDouble() : 0.0;
    final carbs = result['carbs'] is num ? (result['carbs'] as num).toDouble() : 0.0;
    final fat = result['fat'] is num ? (result['fat'] as num).toDouble() : 0.0;

    // If calories are reasonable but macros aren't, estimate macros based on food type
    if (calories > 0 && (protein <= 0 || carbs <= 0 || fat <= 0)) {
      // Determine food category based on name
      if (_isProteinFood(normalizedFoodName)) {
        // High protein foods (meat, eggs, etc.)
        return {
          ...result,
          'protein': (calories * 0.4 / 4).roundToDouble(), // 40% of calories from protein
          'carbs': (calories * 0.1 / 4).roundToDouble(),   // 10% of calories from carbs
          'fat': (calories * 0.5 / 9).roundToDouble(),     // 50% of calories from fat
        };
      } else if (_isCarbFood(normalizedFoodName)) {
        // High carb foods (bread, rice, pasta, etc.)
        return {
          ...result,
          'protein': (calories * 0.15 / 4).roundToDouble(), // 15% of calories from protein
          'carbs': (calories * 0.7 / 4).roundToDouble(),    // 70% of calories from carbs
          'fat': (calories * 0.15 / 9).roundToDouble(),     // 15% of calories from fat
        };
      } else if (_isFatFood(normalizedFoodName)) {
        // High fat foods (oils, nuts, etc.)
        return {
          ...result,
          'protein': (calories * 0.1 / 4).roundToDouble(),  // 10% of calories from protein
          'carbs': (calories * 0.1 / 4).roundToDouble(),    // 10% of calories from carbs
          'fat': (calories * 0.8 / 9).roundToDouble(),      // 80% of calories from fat
        };
      } else if (_isFruitVegetable(normalizedFoodName)) {
        // Fruits and vegetables
        return {
          ...result,
          'protein': (calories * 0.1 / 4).roundToDouble(),  // 10% of calories from protein
          'carbs': (calories * 0.8 / 4).roundToDouble(),    // 80% of calories from carbs
          'fat': (calories * 0.1 / 9).roundToDouble(),      // 10% of calories from fat
        };
      } else {
        // Balanced food (default)
        return {
          ...result,
          'protein': (calories * 0.25 / 4).roundToDouble(), // 25% of calories from protein
          'carbs': (calories * 0.5 / 4).roundToDouble(),    // 50% of calories from carbs
          'fat': (calories * 0.25 / 9).roundToDouble(),     // 25% of calories from fat
        };
      }
    }

    // If macros are reasonable but calories aren't, calculate calories from macros
    if (calories <= 0 && (protein > 0 || carbs > 0 || fat > 0)) {
      final calculatedCalories = (protein * 4) + (carbs * 4) + (fat * 9);
      return {
        ...result,
        'calories': calculatedCalories.round(),
      };
    }

    // Return the original result if we couldn't fix it
    return result;
  }

  // Helper method to get nutritional data from database
  Map<String, dynamic>? _getNutritionalDataFromDatabase(String foodName, String mealType, String imageUrl) {
    // Create a copy of the nutrition database
    final nutritionDatabase = {
      // Protein foods
      'egg': {'calories': 70, 'protein': 6.0, 'carbs': 0.0, 'fat': 5.0, 'portion': '1 large (50g)'},
      'eggs': {'calories': 70, 'protein': 6.0, 'carbs': 0.0, 'fat': 5.0, 'portion': '1 large (50g)'},
      'boiled egg': {'calories': 70, 'protein': 6.0, 'carbs': 0.0, 'fat': 5.0, 'portion': '1 large (50g)'},
      'fried egg': {'calories': 90, 'protein': 6.0, 'carbs': 0.0, 'fat': 7.0, 'portion': '1 large (50g)'},
      'chicken breast': {'calories': 165, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6, 'portion': '100g'},
      'chicken': {'calories': 165, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6, 'portion': '100g'},
      'salmon': {'calories': 206, 'protein': 22.0, 'carbs': 0.0, 'fat': 13.0, 'portion': '100g'},
      'tuna': {'calories': 130, 'protein': 29.0, 'carbs': 0.0, 'fat': 1.0, 'portion': '100g'},
      'beef': {'calories': 250, 'protein': 26.0, 'carbs': 0.0, 'fat': 17.0, 'portion': '100g'},
      'pork': {'calories': 242, 'protein': 26.0, 'carbs': 0.0, 'fat': 16.0, 'portion': '100g'},
      'tofu': {'calories': 76, 'protein': 8.0, 'carbs': 2.0, 'fat': 4.0, 'portion': '100g'},

      // Fruits
      'mango': {'calories': 130, 'protein': 1.0, 'carbs': 35.0, 'fat': 0.5, 'portion': '1 medium (200g)'},
      'apple': {'calories': 95, 'protein': 0.5, 'carbs': 25.0, 'fat': 0.3, 'portion': '1 medium (180g)'},
      'banana': {'calories': 105, 'protein': 1.3, 'carbs': 27.0, 'fat': 0.4, 'portion': '1 medium (120g)'},
      'orange': {'calories': 62, 'protein': 1.2, 'carbs': 15.0, 'fat': 0.2, 'portion': '1 medium (130g)'},
      'strawberry': {'calories': 4, 'protein': 0.1, 'carbs': 1.0, 'fat': 0.0, 'portion': '1 berry (12g)'},
      'blueberry': {'calories': 85, 'protein': 1.1, 'carbs': 21.0, 'fat': 0.5, 'portion': '1 cup (150g)'},
      'avocado': {'calories': 240, 'protein': 3.0, 'carbs': 12.0, 'fat': 22.0, 'portion': '1 medium (200g)'},
      'pineapple': {'calories': 82, 'protein': 0.9, 'carbs': 22.0, 'fat': 0.2, 'portion': '1 cup (165g)'},
      'pineapple slice': {'calories': 42, 'protein': 0.5, 'carbs': 11.0, 'fat': 0.1, 'portion': '1 slice (80g)'},
      'beetroot': {'calories': 35, 'protein': 1.3, 'carbs': 8.0, 'fat': 0.1, 'portion': '1 medium (82g)'},
      'beet': {'calories': 35, 'protein': 1.3, 'carbs': 8.0, 'fat': 0.1, 'portion': '1 medium (82g)'},
      'diced beetroot': {'calories': 58, 'protein': 2.2, 'carbs': 13.0, 'fat': 0.2, 'portion': '1 cup (136g)'},
      'diced beets': {'calories': 58, 'protein': 2.2, 'carbs': 13.0, 'fat': 0.2, 'portion': '1 cup (136g)'},

      // Grains and starches
      'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3, 'portion': '100g cooked'},
      'bread': {'calories': 80, 'protein': 3.0, 'carbs': 15.0, 'fat': 1.0, 'portion': '1 slice (30g)'},
      'pasta': {'calories': 131, 'protein': 5.0, 'carbs': 25.0, 'fat': 1.1, 'portion': '100g cooked'},
      'potato': {'calories': 77, 'protein': 2.0, 'carbs': 17.0, 'fat': 0.1, 'portion': '100g'},
      'oats': {'calories': 150, 'protein': 5.0, 'carbs': 27.0, 'fat': 3.0, 'portion': '40g dry'},
      'corn': {'calories': 77, 'protein': 2.9, 'carbs': 17.0, 'fat': 1.1, 'portion': '1 medium cob (77g)'},
      'corn on the cob': {'calories': 77, 'protein': 2.9, 'carbs': 17.0, 'fat': 1.1, 'portion': '1 medium cob (77g)'},
      'corn slice': {'calories': 15, 'protein': 0.6, 'carbs': 3.4, 'fat': 0.2, 'portion': '1 slice (15g)'},

      // Dairy
      'milk': {'calories': 122, 'protein': 8.0, 'carbs': 12.0, 'fat': 5.0, 'portion': '1 cup (240ml)'},
      'yogurt': {'calories': 150, 'protein': 12.0, 'carbs': 17.0, 'fat': 4.0, 'portion': '1 cup (245g)'},
      'cheese': {'calories': 113, 'protein': 7.0, 'carbs': 0.4, 'fat': 9.0, 'portion': '1 slice (28g)'},

      // Vegetables
      'broccoli': {'calories': 55, 'protein': 3.7, 'carbs': 11.0, 'fat': 0.6, 'portion': '1 cup (91g)'},
      'spinach': {'calories': 23, 'protein': 2.9, 'carbs': 3.6, 'fat': 0.4, 'portion': '1 cup (30g)'},
      'carrot': {'calories': 50, 'protein': 1.0, 'carbs': 12.0, 'fat': 0.3, 'portion': '1 medium (61g)'},
      'tomato': {'calories': 22, 'protein': 1.0, 'carbs': 4.8, 'fat': 0.2, 'portion': '1 medium (123g)'},
      'onion': {'calories': 44, 'protein': 1.2, 'carbs': 10.3, 'fat': 0.1, 'portion': '1 medium (110g)'},
      'bell pepper': {'calories': 30, 'protein': 1.0, 'carbs': 7.0, 'fat': 0.2, 'portion': '1 medium (119g)'},

      // Common meals
      'pizza': {'calories': 285, 'protein': 12.0, 'carbs': 36.0, 'fat': 10.0, 'portion': '1 slice (107g)'},
      'burger': {'calories': 354, 'protein': 20.0, 'carbs': 30.0, 'fat': 17.0, 'portion': '1 burger (150g)'},
      'sandwich': {'calories': 300, 'protein': 15.0, 'carbs': 35.0, 'fat': 10.0, 'portion': '1 sandwich (150g)'},
      'salad': {'calories': 150, 'protein': 5.0, 'carbs': 10.0, 'fat': 10.0, 'portion': '1 bowl (150g)'},
      'omelette': {'calories': 140, 'protein': 12.0, 'carbs': 0.0, 'fat': 10.0, 'portion': '1 omelette (2 eggs)'},
      'vegetable omelette': {'calories': 210, 'protein': 18.0, 'carbs': 5.0, 'fat': 12.0, 'portion': '1 omelette with vegetables'},
      'ham and cheese omelette': {'calories': 250, 'protein': 22.0, 'carbs': 2.0, 'fat': 18.0, 'portion': '1 omelette with ham and cheese'},
    };

    // Check for exact match
    if (nutritionDatabase.containsKey(foodName)) {
      final data = nutritionDatabase[foodName]!;
      return {
        'name': _capitalizeFood(foodName),
        'portion': data['portion'],
        'calories': data['calories'],
        'protein': data['protein'],
        'carbs': data['carbs'],
        'fat': data['fat'],
        'confidence': 90, // High confidence since it's from our database
        'mealType': mealType,
        'timestamp': DateTime.now().toIso8601String(),
        'imageUrl': imageUrl,
        'source': 'database',
      };
    }

    // Check for partial match
    for (final entry in nutritionDatabase.entries) {
      if (foodName.contains(entry.key) || entry.key.contains(foodName)) {
        final data = entry.value;
        return {
          'name': _capitalizeFood(entry.key),
          'portion': data['portion'],
          'calories': data['calories'],
          'protein': data['protein'],
          'carbs': data['carbs'],
          'fat': data['fat'],
          'confidence': 80, // Good confidence for partial match
          'mealType': mealType,
          'timestamp': DateTime.now().toIso8601String(),
          'imageUrl': imageUrl,
          'source': 'database_partial',
        };
      }
    }

    return null;
  }

  // Helper method to capitalize food name
  String _capitalizeFood(String foodName) {
    if (foodName.isEmpty) return foodName;
    return foodName.split(' ').map((word) =>
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
    ).join(' ');
  }

  // Helper method to get the better food name
  String _getBetterFoodName(String geminiName, String visionName) {
    // If one name is significantly longer and more descriptive, use it
    if (geminiName.split(' ').length > visionName.split(' ').length + 1) {
      return geminiName;
    }
    if (visionName.split(' ').length > geminiName.split(' ').length + 1) {
      return visionName;
    }

    // If names are similar in length, prefer the Gemini name as it's usually more specific
    return geminiName;
  }

  // Helper methods to categorize foods
  bool _isProteinFood(String foodName) {
    final proteinFoods = [
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'egg', 'tofu',
      'meat', 'turkey', 'protein', 'steak', 'lamb', 'duck', 'shrimp', 'seafood'
    ];
    return proteinFoods.any((food) => foodName.contains(food));
  }

  bool _isCarbFood(String foodName) {
    final carbFoods = [
      'bread', 'rice', 'pasta', 'noodle', 'potato', 'cereal', 'oat', 'grain',
      'wheat', 'corn', 'flour', 'dough', 'bun', 'roll', 'bagel', 'tortilla'
    ];
    return carbFoods.any((food) => foodName.contains(food));
  }

  bool _isFatFood(String foodName) {
    final fatFoods = [
      'oil', 'butter', 'cream', 'cheese', 'avocado', 'nut', 'seed', 'almond',
      'walnut', 'peanut', 'cashew', 'olive', 'coconut', 'fat', 'lard', 'ghee'
    ];
    return fatFoods.any((food) => foodName.contains(food));
  }

  bool _isFruitVegetable(String foodName) {
    final fruitVegetables = [
      'apple', 'banana', 'orange', 'grape', 'berry', 'fruit', 'vegetable',
      'carrot', 'broccoli', 'spinach', 'lettuce', 'tomato', 'cucumber', 'pepper',
      'mango', 'pineapple', 'melon', 'watermelon', 'kiwi', 'strawberry', 'blueberry',
      'beetroot', 'beet', 'onion', 'garlic', 'celery', 'zucchini', 'eggplant'
    ];
    return fruitVegetables.any((food) => foodName.contains(food));
  }

  // Helper method to get a generic food term from a specific food name
  String _getGenericFoodTerm(String foodName) {
    // Map of specific foods to generic categories
    final Map<String, String> foodCategories = {
      'apple': 'apple',
      'banana': 'banana',
      'orange': 'orange',
      'pizza': 'pizza',
      'burger': 'hamburger',
      'sandwich': 'sandwich',
      'salad': 'salad',
      'pasta': 'pasta',
      'rice': 'rice',
      'bread': 'bread',
      'chicken': 'chicken',
      'beef': 'beef',
      'fish': 'fish',
      'egg': 'egg',
      'cake': 'cake',
      'cookie': 'cookie',
      'ice cream': 'ice cream',
      'chocolate': 'chocolate',
      'coffee': 'coffee',
      'tea': 'tea',
      'juice': 'juice',
      'milk': 'milk',
      'yogurt': 'yogurt',
      'cheese': 'cheese',
      'soup': 'soup',
      'stew': 'stew',
      'curry': 'curry',
      'noodle': 'noodles',
      'vegetable': 'vegetables',
      'fruit': 'fruit',
      'meat': 'meat',
      'seafood': 'seafood',
      'dessert': 'dessert',
      'breakfast': 'breakfast',
      'lunch': 'lunch',
      'dinner': 'dinner',
      'snack': 'snack',
    };

    // Convert to lowercase for matching
    final lowerName = foodName.toLowerCase();

    // Check for exact matches
    if (foodCategories.containsKey(lowerName)) {
      return foodCategories[lowerName]!;
    }

    // Check for partial matches
    for (final entry in foodCategories.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    // If no match found, return a default based on word length
    final words = lowerName.split(' ');
    if (words.length > 1) {
      // Return the last word for compound foods (e.g., "chocolate cake" -> "cake")
      return words.last;
    }

    // Return the original name if no match found
    return foodName;
  }

  // Get a simple hash of the image for caching
  Future<String> _getImageHash(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Use a simple hash based on the first 1000 bytes and file size
      final int fileSize = bytes.length;
      final int sampleSize = fileSize > 1000 ? 1000 : fileSize;
      final List<int> sample = bytes.sublist(0, sampleSize);

      // Create a simple hash
      int hash = 0;
      for (int i = 0; i < sample.length; i++) {
        hash = (hash * 31 + sample[i]) & 0xFFFFFFFF;
      }

      return '$hash-$fileSize';
    } catch (e) {
      debugPrint('Error creating image hash: $e');
      // Return a timestamp as fallback
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // Get cached result for an image hash
  Future<Map<String, dynamic>?> _getCachedResult(String imageHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cacheJson = prefs.getString(_cacheKey);

      if (cacheJson == null) {
        return null;
      }

      final List<dynamic> cache = jsonDecode(cacheJson);

      // Find the cached item with matching hash
      for (final item in cache) {
        if (item['imageHash'] == imageHash) {
          return Map<String, dynamic>.from(item['result']);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting cached result: $e');
      return null;
    }
  }

  // Cache a result for an image hash
  Future<void> _cacheResult(String imageHash, Map<String, dynamic> result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cacheJson = prefs.getString(_cacheKey);

      List<dynamic> cache = [];
      if (cacheJson != null) {
        cache = jsonDecode(cacheJson);
      }

      // Add the new result to the cache
      cache.add({
        'imageHash': imageHash,
        'result': result,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Limit cache size
      if (cache.length > _maxCacheItems) {
        // Sort by timestamp (oldest first)
        cache.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
        // Remove oldest items
        cache = cache.sublist(cache.length - _maxCacheItems);
      }

      // Save the updated cache
      await prefs.setString(_cacheKey, jsonEncode(cache));
    } catch (e) {
      debugPrint('Error caching result: $e');
    }
  }

  // Method to handle API failures with proper error response
  Map<String, dynamic> _getErrorResponse(File imageFile, String mealType, String errorMessage) {
    debugPrint('Returning error response: $errorMessage');

    return {
      'error': errorMessage,
      'name': 'Unknown Food',
      'calories': 0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'portion': 'Unknown',
      'confidence': 0,
      'mealType': mealType,
      'timestamp': DateTime.now().toIso8601String(),
      'imageUrl': imageFile.path,
      'source': 'error',
      'details': 'We could not identify this food. Please try again with a clearer image or different food.',
    };
  }

  // Method to handle when no food is recognized
  Map<String, dynamic> _getUnrecognizedFoodResult(File imageFile, String mealType) {
    return {
      'error': 'Could not recognize food in the image',
      'details': 'The API could not identify any food in this image. Please try again with a clearer image or different food.',
    };
  }

  // Get recent food items
  Future<List<FoodItem>> getRecentFoodItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cacheJson = prefs.getString(_cacheKey);

      if (cacheJson == null || cacheJson.isEmpty) {
        debugPrint('No cache found for recent food items');
        return [];
      }

      List<dynamic> cache;
      try {
        cache = jsonDecode(cacheJson);
        if (cache is! List) {
          debugPrint('Cache is not a list: ${cache.runtimeType}');
          return [];
        }
      } catch (jsonError) {
        debugPrint('Error decoding cache JSON: $jsonError');
        // Try to recover by clearing the invalid cache
        await prefs.remove(_cacheKey);
        return [];
      }

      final List<FoodItem> foodItems = [];

      for (final item in cache) {
        try {
          if (item is! Map || !item.containsKey('result')) {
            debugPrint('Invalid cache item format: $item');
            continue;
          }

          final result = Map<String, dynamic>.from(item['result']);

          // Validate required fields
          if (!result.containsKey('name') ||
              !result.containsKey('calories') ||
              !result.containsKey('protein') ||
              !result.containsKey('carbs') ||
              !result.containsKey('fat') ||
              !result.containsKey('timestamp')) {
            debugPrint('Missing required fields in cached food item: $result');
            continue;
          }

          // Parse timestamp safely
          DateTime timestamp;
          try {
            timestamp = DateTime.parse(result['timestamp']);
          } catch (dateError) {
            debugPrint('Error parsing timestamp: $dateError');
            timestamp = DateTime.now(); // Fallback to current time
          }

          // Parse numeric values safely
          int calories;
          double protein, carbs, fat;

          try {
            calories = (result['calories'] is num)
                ? (result['calories'] as num).toInt()
                : 0;

            protein = (result['protein'] is num)
                ? (result['protein'] as num).toDouble()
                : 0.0;

            carbs = (result['carbs'] is num)
                ? (result['carbs'] as num).toDouble()
                : 0.0;

            fat = (result['fat'] is num)
                ? (result['fat'] as num).toDouble()
                : 0.0;
          } catch (numError) {
            debugPrint('Error parsing numeric values: $numError');
            calories = 0;
            protein = 0.0;
            carbs = 0.0;
            fat = 0.0;
          }

          foodItems.add(FoodItem(
            name: result['name'] ?? 'Unknown Food',
            imageUrl: result['imageUrl'] ?? '',
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealType: result['mealType'] ?? 'Snack',
            timestamp: timestamp,
            portion: result['portion'] ?? 'Standard serving',
            confidence: (result['confidence'] is num) ? (result['confidence'] as num).toInt() : 80,
            description: result['description'] ?? '',
          ));
        } catch (e) {
          debugPrint('Error parsing cached food item: $e');
          // Continue to next item
        }
      }

      // Sort by timestamp (newest first)
      foodItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      debugPrint('Retrieved ${foodItems.length} recent food items');
      return foodItems;
    } catch (e) {
      debugPrint('Error getting recent food items: $e');
      return [];
    }
  }
}
