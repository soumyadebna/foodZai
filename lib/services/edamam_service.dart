import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class EdamamService {
  // Edamam API credentials
  final String appId = AppConstants.edamamAppId;
  final String appKey = AppConstants.edamamAppKey;

  // Edamam API endpoint for food database
  final String apiEndpoint = 'https://api.edamam.com/api/food-database/v2/parser';

  // Method to get nutritional information for a food
  Future<Map<String, dynamic>> getNutritionInfo(String foodName) async {
    try {
      debugPrint('Getting nutrition info for: $foodName');

      // Create the URL with query parameters
      final uri = Uri.parse(apiEndpoint).replace(queryParameters: {
        'app_id': appId,
        'app_key': appKey,
        'ingr': foodName,
        'nutrition-type': 'logging',
      });

      // Generate a consistent user ID based on device
      final String userId = 'foodai_user_fixed_id_123456';

      // Make the API request with required headers
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Edamam-Account-User': userId,
        },
      );

      debugPrint('Edamam API request sent with user ID: $userId');

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check if we have any hints
        if (responseData.containsKey('hints') &&
            responseData['hints'] is List &&
            (responseData['hints'] as List).isNotEmpty) {

          // Get the first hint (most relevant match)
          final firstHint = responseData['hints'][0];

          // Get the food item
          final food = firstHint['food'];

          // Get the nutrients
          final nutrients = food['nutrients'];

          // Extract the nutritional values
          final String foodLabel = food['label'];
          final double calories = nutrients['ENERC_KCAL']?.toDouble() ?? 0.0;
          final double protein = nutrients['PROCNT']?.toDouble() ?? 0.0;
          final double fat = nutrients['FAT']?.toDouble() ?? 0.0;
          final double carbs = nutrients['CHOCDF']?.toDouble() ?? 0.0;
          final String category = food['category'] ?? 'generic food';

          // Get the measures
          final measures = firstHint['measures'] as List;
          String portion = 'Standard serving';

          // Try to find a reasonable portion size
          if (measures.isNotEmpty) {
            // Look for common measures like "serving", "piece", "whole", etc.
            final commonMeasures = measures.where((measure) {
              final label = measure['label'].toString().toLowerCase();
              return label.contains('serving') ||
                     label.contains('piece') ||
                     label.contains('whole') ||
                     label.contains('cup') ||
                     label.contains('tablespoon') ||
                     label.contains('teaspoon');
            }).toList();

            if (commonMeasures.isNotEmpty) {
              portion = commonMeasures[0]['label'];
            } else {
              portion = measures[0]['label'];
            }
          }

          debugPrint('Edamam found nutrition for: $foodLabel');
          debugPrint('Calories: $calories, Protein: $protein, Carbs: $carbs, Fat: $fat');

          return {
            'name': foodLabel,
            'calories': calories.round(),
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'portion': portion,
            'category': category,
            'foodId': food['foodId'],
          };
        } else if (responseData.containsKey('parsed') &&
                  responseData['parsed'] is List &&
                  (responseData['parsed'] as List).isNotEmpty) {

          // Get the first parsed item
          final firstParsed = responseData['parsed'][0];

          // Get the food item
          final food = firstParsed['food'];

          // Get the nutrients
          final nutrients = food['nutrients'];

          // Extract the nutritional values
          final String foodLabel = food['label'];
          final double calories = nutrients['ENERC_KCAL']?.toDouble() ?? 0.0;
          final double protein = nutrients['PROCNT']?.toDouble() ?? 0.0;
          final double fat = nutrients['FAT']?.toDouble() ?? 0.0;
          final double carbs = nutrients['CHOCDF']?.toDouble() ?? 0.0;
          final String category = food['category'] ?? 'generic food';

          debugPrint('Edamam found nutrition for: $foodLabel');
          debugPrint('Calories: $calories, Protein: $protein, Carbs: $carbs, Fat: $fat');

          return {
            'name': foodLabel,
            'calories': calories.round(),
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'portion': 'Standard serving',
            'category': category,
            'foodId': food['foodId'],
          };
        }

        // No nutrition information found
        debugPrint('Edamam could not find nutrition info for: $foodName');
        return {
          'error': 'No nutrition information found for: $foodName',
          'details': responseData,
        };
      } else {
        // API request failed
        debugPrint('Edamam API request failed: ${response.statusCode} ${response.body}');
        return {
          'error': 'API request failed: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      // Exception occurred
      debugPrint('Error in Edamam service: $e');
      return {
        'error': 'Error getting nutrition info: $e',
      };
    }
  }

  // Method to get nutrition info for multiple food candidates
  Future<List<Map<String, dynamic>>> getNutritionInfoForCandidates(List<String> foodCandidates) async {
    final results = <Map<String, dynamic>>[];

    // Try each candidate
    for (final candidate in foodCandidates) {
      try {
        final result = await getNutritionInfo(candidate);

        // If successful, add to results
        if (!result.containsKey('error')) {
          results.add(result);
        }
      } catch (e) {
        debugPrint('Error getting nutrition for candidate $candidate: $e');
      }
    }

    return results;
  }
}
