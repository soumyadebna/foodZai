import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../utils/constants.dart';

class TextToFoodService {
  // Gemini API endpoint for text-only requests
  static const String apiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent';
  
  // Get API key from constants
  String get apiKey => AppConstants.geminiApiKey;

  // Method to extract food items and nutritional information from text
  Future<Map<String, dynamic>> extractFoodFromText(String text, String mealType) async {
    try {
      debugPrint('Extracting food information from text: $text');
      
      // Validate input
      if (text.isEmpty) {
        return {
          'error': 'Empty text',
          'details': 'No text was provided for analysis.',
        };
      }

      // Create the request body with a prompt designed to extract food items and quantities
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": """You are a nutrition expert AI for a calorie tracking app. Your job is to extract food items and their quantities from user input, then provide nutritional information.

CRITICAL INSTRUCTIONS:
1. Extract all food items and their quantities from the text
2. For each food item, provide its name, portion size, and nutritional information (calories, protein, carbs, fat)
3. If quantities are not specified, use standard portions
4. If the text doesn't contain any food items, respond with: {"error": "No food items found", "details": "Could not identify any food items in the text. Please try again with specific food items and quantities."}
5. If you're uncertain about a food item, make a reasonable estimate based on similar foods

USER INPUT:
$text

RESPONSE FORMAT:
Respond ONLY with valid JSON in this exact format:
{
  "items": [
    {
      "name": "Food Name",
      "portion": "Specified portion (e.g., 100g, 1 cup)",
      "calories": 123,
      "protein": 12,
      "carbs": 12,
      "fat": 12
    },
    // Additional items if present
  ],
  "total": {
    "calories": 123,
    "protein": 12,
    "carbs": 12,
    "fat": 12
  }
}"""
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.1, // Low temperature for more accurate responses
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
                'details': foodData.containsKey('details') ? foodData['details'] : 'Could not identify any food items in the text.',
              };
            }

            // Validate the response has all required fields
            if (foodData.containsKey('items') && foodData.containsKey('total')) {
              // Add meal type and timestamp to the result
              final result = {
                ...foodData,
                'mealType': mealType,
                'timestamp': DateTime.now().toIso8601String(),
                'source': 'voice_input',
              };

              debugPrint('Successfully extracted food information: ${result['items'].length} items');
              return result;
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
        debugPrint('Failed to analyze text: ${response.statusCode} ${response.body}');
        throw Exception('Failed to analyze text: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error extracting food from text: $e');
      return {
        'error': 'Error analyzing text',
        'details': 'An error occurred while analyzing the text. Please try again.',
      };
    }
  }

  // Convert the API response to a list of FoodItem objects
  List<FoodItem> convertToFoodItems(Map<String, dynamic> apiResponse, String mealType) {
    if (apiResponse.containsKey('error') || !apiResponse.containsKey('items')) {
      return [];
    }

    final List<dynamic> items = apiResponse['items'];
    final List<FoodItem> foodItems = [];

    for (final item in items) {
      try {
        final foodItem = FoodItem(
          name: item['name'] ?? 'Unknown Food',
          imageUrl: '', // No image for voice input
          calories: _ensureNumeric(item['calories']).toInt(),
          protein: _ensureNumeric(item['protein']),
          carbs: _ensureNumeric(item['carbs']),
          fat: _ensureNumeric(item['fat']),
          mealType: mealType,
          timestamp: DateTime.now(),
          portion: item['portion'] ?? 'Standard serving',
          confidence: 80, // Default confidence for voice input
          description: '',
        );
        foodItems.add(foodItem);
      } catch (e) {
        debugPrint('Error converting item to FoodItem: $e');
        // Continue to next item
      }
    }

    return foodItems;
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
