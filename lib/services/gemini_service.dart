import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  // Gemini API key
  static const String apiKey = 'AIzaSyBzL0LJ7EsQbGxr--cFGKbsEd1xgG9VSS0'; // Updated key

  // Gemini API endpoint for multimodal (text + image) requests
  static const String apiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent';

  // Nutritional reference database for common foods with standard portion sizes
  // Values are per standard portion (not per 100g)
  static final Map<String, Map<String, dynamic>> _nutritionDatabase = {
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

  // Reasonable ranges for nutritional values (per 100g)
  static final Map<String, List<num>> _nutritionRanges = {
    'calories': [20, 900],   // kcal per 100g
    'protein': [0, 80],      // g per 100g
    'carbs': [0, 100],       // g per 100g
    'fat': [0, 100],         // g per 100g
  };

  // Method to analyze food from an image with improved accuracy
  Future<Map<String, dynamic>> analyzeFoodImage(File imageFile) async {
    try {
      // Read the image file as bytes
      final List<int> imageBytes = await imageFile.readAsBytes();

      // Check if image is too small or too large
      if (imageBytes.length < 10 * 1024) { // Less than 10KB
        debugPrint('Image is too small, may not contain enough detail');
        return {
          'error': 'Image too small',
          'details': 'The image is too small to analyze accurately. Please take a clearer photo.',
        };
      }

      // Convert image bytes to base64
      final String base64Image = base64Encode(imageBytes);

      // Create the request body with a simplified prompt for more accurate nutritional analysis
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "You are a food recognition AI for a calorie tracking app. Your job is to identify food in this image and provide nutritional information.\n\n"
                    "CRITICAL INSTRUCTIONS:\n"
                    "1. If you can clearly identify the food, provide its name and nutritional information\n"
                    "2. If the image is too blurry, too dark, or doesn't contain recognizable food, respond with: {\"error\": \"Image unclear\", \"details\": \"Cannot identify food in this image. Please provide a clearer photo.\"}\n"
                    "3. Only identify food items - not plates, utensils, or other objects\n"
                    "4. Be honest about confidence levels - don't guess if you're not at least 60% confident\n"
                    "5. If you're uncertain but can see it's food, respond with: {\"error\": \"Low confidence\", \"details\": \"The image contains food but I cannot identify it clearly. Please take a photo with better lighting and focus.\"}\n"
                    "6. If the image contains plants, leaves, or vegetables that are not prepared as food, respond with: {\"error\": \"Not prepared food\", \"details\": \"The image appears to contain plants or raw ingredients rather than prepared food. Please take a photo of your prepared meal.\"}\n\n"

                    "COMMON FOODS AND CALORIES:\n"
                    "- Egg: 70 calories\n"
                    "- Apple: 95 calories\n"
                    "- Banana: 105 calories\n"
                    "- Chicken: 165 calories/100g\n"
                    "- Rice: 130 calories/100g\n"
                    "- Bread: 80 calories/slice\n"
                    "- Pizza: 285 calories/slice\n"
                    "- Burger: 354 calories\n"
                    "- Salad: 100 calories\n"
                    "- Pasta: 131 calories/100g\n"
                    "- Sandwich: 300 calories\n"
                    "- Soup: 150 calories/bowl\n"
                    "- Steak: 250 calories/100g\n"
                    "- Fish: 200 calories/100g\n"
                    "- Yogurt: 150 calories/cup\n"
                    "- Cereal: 200 calories/bowl\n"
                    "- Fruit plate: 120 calories\n"
                    "- Vegetable dish: 100 calories\n"
                    "- Dessert: 300 calories\n"
                    "- Snack: 150 calories\n"
                    "- Mixed meal: 350 calories\n\n"

                    "RESPONSE FORMAT:\n"
                    "Respond ONLY with valid JSON in this exact format:\n"
                    "{ \"name\": \"Food Name\", \"portion\": \"Estimated portion\", \"calories\": 123, \"protein\": 12, \"carbs\": 12, \"fat\": 12, \"confidence\": 60 }"
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2, // Lower temperature for more accurate responses
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 4096,
          "stopSequences": ["```"]
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_NONE"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_NONE"
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_NONE"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_NONE"
          }
        ]
      };

      debugPrint('Sending request to Gemini API...');

      // Make the API request
      final response = await http.post(
        Uri.parse('$apiEndpoint?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        try {
          // Parse the response
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Extract the generated text
          final String generatedText = responseData['candidates'][0]['content']['parts'][0]['text'];

          // Print the raw response for debugging
          debugPrint('Gemini API raw response: $generatedText');

          // Extract the JSON from the text
          final jsonStart = generatedText.indexOf('{');
          final jsonEnd = generatedText.lastIndexOf('}') + 1;

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = generatedText.substring(jsonStart, jsonEnd);

            // Parse the JSON
            final Map<String, dynamic> foodData = jsonDecode(jsonString);

            // Check if the response contains an error message
            if (foodData.containsKey('error')) {
              debugPrint('Gemini API returned an error: ${foodData['error']}');
              return {
                'error': foodData['error'],
                'details': foodData.containsKey('details') ? foodData['details'] : 'Cannot identify food in this image. Please provide a clearer photo.',
              };
            }

            // Validate the response has all required fields
            if (foodData.containsKey('name') &&
                foodData.containsKey('calories') &&
                foodData.containsKey('protein') &&
                foodData.containsKey('carbs') &&
                foodData.containsKey('fat')) {

              // Get the food name and confidence
              final String foodName = foodData['name'].toString().toLowerCase();
              final int confidence = foodData.containsKey('confidence')
                  ? _ensureNumeric(foodData['confidence']).toInt()
                  : 80; // Default confidence if not provided

              // Get portion information
              final String portion = foodData.containsKey('portion')
                  ? foodData['portion'].toString()
                  : 'Standard serving';

              // Check if this is a known food in our database
              for (final entry in _nutritionDatabase.entries) {
                if (foodName.contains(entry.key)) {
                  // Use our verified nutrition data instead of Gemini's response
                  debugPrint('Using verified nutrition data for ${entry.key}');
                  return {
                    'name': foodData['name'], // Keep the original food name
                    'portion': entry.value['portion'],
                    'calories': entry.value['calories'],
                    'protein': entry.value['protein'],
                    'carbs': entry.value['carbs'],
                    'fat': entry.value['fat'],
                    'confidence': confidence,
                  };
                }
              }

              // If not a known food, validate the nutritional values
              final calories = _ensureNumeric(foodData['calories']);
              final protein = _ensureNumeric(foodData['protein']);
              final carbs = _ensureNumeric(foodData['carbs']);
              final fat = _ensureNumeric(foodData['fat']);

              // Check if values are within reasonable ranges
              final bool isCaloriesReasonable = _isValueInRange(calories, _nutritionRanges['calories']!);
              final bool isProteinReasonable = _isValueInRange(protein, _nutritionRanges['protein']!);
              final bool isCarbsReasonable = _isValueInRange(carbs, _nutritionRanges['carbs']!);
              final bool isFatReasonable = _isValueInRange(fat, _nutritionRanges['fat']!);

              // If any value is unreasonable, adjust it
              final validatedData = {
                'name': foodData['name'],
                'portion': portion,
                'calories': isCaloriesReasonable ? calories : _adjustValue(calories, _nutritionRanges['calories']!),
                'protein': isProteinReasonable ? protein : _adjustValue(protein, _nutritionRanges['protein']!),
                'carbs': isCarbsReasonable ? carbs : _adjustValue(carbs, _nutritionRanges['carbs']!),
                'fat': isFatReasonable ? fat : _adjustValue(fat, _nutritionRanges['fat']!),
                'confidence': confidence,
              };

              debugPrint('Validated food data: $validatedData');
              return validatedData;
            } else {
              debugPrint('Missing required fields in Gemini response: $foodData');
              throw Exception('Missing required fields in Gemini response');
            }
          } else {
            debugPrint('Failed to extract JSON from Gemini response: $generatedText');
            throw Exception('Failed to extract JSON from Gemini response');
          }
        } catch (parseError) {
          debugPrint('Error parsing Gemini response: $parseError');
          throw Exception('Error parsing Gemini response: $parseError');
        }
      } else {
        debugPrint('Failed to analyze image: ${response.statusCode} ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error analyzing food image: $e');

      // Return detailed error information to help troubleshoot
      String errorMessage = 'Error analyzing food image';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'API permission error. Please check your API key configuration.';
      } else if (e.toString().contains('format')) {
        errorMessage = 'Image format error. Please try a different image.';
      }

      debugPrint('Detailed error: $e');

      return {
        'error': errorMessage,
        'name': 'Unknown Food',
        'portion': 'Unknown',
        'calories': 0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'confidence': 0,
        'details': 'Please try taking a clearer photo with good lighting and the food centered in the frame.',
      };
    }
  }

  // Check if a value is within a reasonable range
  bool _isValueInRange(num value, List<num> range) {
    return value >= range[0] && value <= range[1];
  }

  // Adjust a value to be within a reasonable range
  num _adjustValue(num value, List<num> range) {
    if (value < range[0]) return range[0];
    if (value > range[1]) return range[1];
    return value;
  }

  // Helper method to ensure values are numeric
  dynamic _ensureNumeric(dynamic value) {
    if (value is num) {
      return value;
    } else if (value is String) {
      // Try to parse the string as a number
      try {
        // Remove any non-numeric characters except decimal point
        final cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');

        if (cleanValue.isEmpty) {
          return 0;
        }

        if (cleanValue.contains('.')) {
          return double.parse(cleanValue);
        } else {
          return int.parse(cleanValue);
        }
      } catch (e) {
        debugPrint('Error parsing numeric value: $e');
        // Default fallback values based on the field
        return 0;
      }
    } else {
      return 0;
    }
  }
}
