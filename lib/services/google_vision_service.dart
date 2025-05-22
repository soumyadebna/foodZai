import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:logger/logger.dart';

class GoogleVisionService {
  // Logger for better debugging
  final Logger _logger = Logger();

  // Google Cloud Vision API key (platform-specific)
  String get apiKey {
    if (Platform.isAndroid) {
      return AppConstants.googleVisionApiKeyAndroid;
    } else if (Platform.isIOS) {
      return AppConstants.googleVisionApiKeyIOS;
    } else {
      return AppConstants.googleVisionApiKeyWeb;
    }
  }

  // Raw API key (without Bearer prefix)
  String get apiKeyRaw => AppConstants.googleVisionApiKeyNoBearer;

  // Backup API key - use the opposite platform's key as backup
  String get backupApiKey {
    if (Platform.isAndroid) {
      return AppConstants.googleVisionApiKeyIOS;
    } else {
      return AppConstants.googleVisionApiKeyAndroid;
    }
  }

  // Google Cloud Vision API endpoint
  final String apiEndpoint = 'https://vision.googleapis.com/v1/images:annotate';

  // Alternative endpoint without API key in URL (more secure)
  final String apiEndpointNoKey = 'https://vision.googleapis.com/v1/images:annotate';

  // Debug flag to print detailed API information
  final bool debugMode = true;

  // Check if the API key is valid
  bool _isApiKeyValid(String key) {
    // Check if the key is empty or contains placeholder text
    if (key.isEmpty || key.contains('YOUR_')) {
      return false;
    }

    // Check if the key has the correct format (starts with 'AIza')
    if (!key.startsWith('AIza')) {
      return false;
    }

    // Check if the key has the correct length (typically around 39 characters)
    if (key.length < 30) {
      return false;
    }

    return true;
  }

  // Method to identify food from an image
  Future<Map<String, dynamic>> identifyFoodInImage(File imageFile) async {
    try {
      _logger.i('Starting Google Vision food identification for ${imageFile.path}');

      // Validate API key before proceeding
      if (!_isApiKeyValid(apiKey)) {
        _logger.e('Invalid API key format: ${apiKey.substring(0, 5)}...');
        return {
          'error': 'API authentication error',
          'details': 'The API key is not properly formatted or is invalid.',
          'fallback': true,
        };
      }

      // Read the image file as bytes
      final List<int> imageBytes = await imageFile.readAsBytes();

      // Convert image bytes to base64
      final String base64Image = base64Encode(imageBytes);

      // Log image details
      _logger.i('Image size: ${imageBytes.length} bytes');
      _logger.i('API key first 5 chars: ${apiKey.substring(0, 5)}...');

      // Create the request body for Google Cloud Vision API with enhanced features
      final Map<String, dynamic> requestBody = {
        "requests": [
          {
            "image": {
              "content": base64Image
            },
            "features": [
              {
                "type": "LABEL_DETECTION",
                "maxResults": 15
              },
              {
                "type": "OBJECT_LOCALIZATION",
                "maxResults": 10
              },
              {
                "type": "WEB_DETECTION",
                "maxResults": 10
              }
            ],
            "imageContext": {
              "languageHints": ["en"],
              "productSearchParams": {
                "productCategories": ["food-and-beverage"]
              }
            }
          }
        ]
      };

      if (debugMode) {
        _logger.i('Request body structure: ${jsonEncode(requestBody).substring(0, 100)}...');
      }

      // Validate API key
      if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
        _logger.e('Invalid API key: $apiKey');
        return {
          'error': 'API authentication error',
          'details': 'The API key is not properly configured.',
          'fallback': true,
        };
      }

      // Make the API request
      _logger.i('Sending request to Google Vision API with key starting with: ${apiKey.substring(0, 5)}...');

      // Add retry logic for network issues
      int retryCount = 0;
      const maxRetries = 2;
      http.Response? response;

      while (retryCount <= maxRetries) {
        try {
          // Try different approaches for API authentication
          if (retryCount == 0) {
            // First approach: API key in URL (traditional approach)
            _logger.i('Using API key in URL approach (attempt ${retryCount + 1})');
            final uri = Uri.parse('$apiEndpoint?key=$apiKey');
            _logger.i('Request URL: $uri');

            response = await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 30));
          } else if (retryCount == 1) {
            // Second approach: API key in Authorization header
            _logger.i('Using API key in Authorization header approach (attempt ${retryCount + 1})');
            response = await http.post(
              Uri.parse(apiEndpointNoKey),
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': apiKeyRaw,
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 30));
          } else {
            // Third approach: Try with backup API key
            _logger.i('Using backup API key approach (attempt ${retryCount + 1})');
            response = await http.post(
              Uri.parse('$apiEndpoint?key=$backupApiKey'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 30));
          }

          // Log response status and partial body for debugging
          _logger.i('Response status code: ${response.statusCode}');
          if (response.body.isNotEmpty) {
            final bodyPreview = response.body.length > 200
                ? '${response.body.substring(0, 200)}...'
                : response.body;
            _logger.i('Response body preview: $bodyPreview');
          }

          // If successful, break out of retry loop
          if (response.statusCode == 200) {
            _logger.i('API request successful');
            break;
          } else {
            // If not successful, log the error and try again
            _logger.w('API request failed with status code: ${response.statusCode}');

            // Log more details about the error
            if (response.statusCode == 400) {
              _logger.w('Bad Request: Check the request format');
            } else if (response.statusCode == 401 || response.statusCode == 403) {
              _logger.w('Authentication error: API key may be invalid or missing required permissions');
            } else if (response.statusCode == 429) {
              _logger.w('Rate limit exceeded: Too many requests');
            } else if (response.statusCode >= 500) {
              _logger.w('Server error: Google Vision API service issue');
            }

            retryCount++;

            // If we've reached max retries, break out of the loop
            if (retryCount > maxRetries) {
              break;
            }

            // Wait before retrying
            await Future.delayed(Duration(seconds: 1 * retryCount));
          }
        } catch (e) {
          retryCount++;
          _logger.w('API request attempt $retryCount failed: $e');

          if (retryCount > maxRetries) {
            _logger.e('All retry attempts failed: $e');
            return {
              'error': 'Network error: Failed to connect to Google Vision API',
              'details': e.toString(),
              'fallback': true,
            };
          }

          // Wait before retrying
          await Future.delayed(Duration(seconds: 1 * retryCount));
        }
      }

      // Log the response status
      _logger.i('Google Vision API response status: ${response?.statusCode}');

      // Check if the request was successful
      if (response?.statusCode == 200) {
        try {
          // Parse the response
          final Map<String, dynamic> responseData = jsonDecode(response!.body);

          // Log the full response for debugging
          if (debugMode) {
            _logger.i('Full response: ${jsonEncode(responseData)}');
          }

          // Check if responses array exists and is not empty
          if (!responseData.containsKey('responses') ||
              responseData['responses'] == null ||
              (responseData['responses'] as List).isEmpty) {
            _logger.w('Invalid response format: missing or empty responses array');
            return {
              'error': 'Invalid API response format',
              'details': 'Missing or empty responses array',
              'fallback': true,
            };
          }

          // Extract the annotations
          final annotations = responseData['responses'][0];

          // Check for error in response
          if (annotations.containsKey('error')) {
            final error = annotations['error'];
            _logger.e('Error in Google Vision response: ${error['message']}');
            return {
              'error': 'API error: ${error['message']}',
              'code': error['code'],
              'details': error['status'] ?? 'Unknown status',
              'fallback': true,
            };
          }

          // First try web detection (often more accurate for food)
          if (annotations.containsKey('webDetection')) {
            final webDetection = annotations['webDetection'];
            _logger.i('Web detection data found in response');

            // Check for best guess labels
            if (webDetection.containsKey('bestGuessLabels') &&
                (webDetection['bestGuessLabels'] as List).isNotEmpty) {
              final bestGuess = webDetection['bestGuessLabels'][0]['label'];
              _logger.i('Best guess from web detection: $bestGuess');

              // Check if it's a food item
              if (_isFoodItem(bestGuess)) {
                _logger.i('Google Vision identified food via web detection: $bestGuess');

                // Get all labels for additional context
                List<String> allLabels = [];
                if (annotations.containsKey('labelAnnotations')) {
                  allLabels = (annotations['labelAnnotations'] as List)
                      .map<String>((label) => label['description'] as String)
                      .toList();
                  _logger.i('All labels: ${allLabels.join(", ")}');
                }

                return {
                  'name': bestGuess,
                  'confidence': 90, // Web detection is usually high confidence
                  'source': 'web_detection',
                  'allLabels': allLabels,
                };
              } else {
                _logger.i('Best guess is not a food item: $bestGuess');
              }
            } else {
              _logger.i('No best guess labels found in web detection');
            }

            // Check for web entities as fallback
            if (webDetection.containsKey('webEntities') &&
                (webDetection['webEntities'] as List).isNotEmpty) {
              _logger.i('Checking web entities for food items');

              // Filter entities for food items
              final foodEntities = (webDetection['webEntities'] as List).where((entity) {
                if (entity.containsKey('description')) {
                  final description = entity['description'] as String;
                  return _isFoodItem(description);
                }
                return false;
              }).toList();

              if (foodEntities.isNotEmpty) {
                final topEntity = foodEntities[0];
                final String foodName = topEntity['description'];
                final double score = topEntity.containsKey('score') ?
                    (topEntity['score'] as num).toDouble() : 0.7;
                final int confidence = (score * 100).toInt();

                _logger.i('Found food entity: $foodName with confidence: $confidence%');

                return {
                  'name': foodName,
                  'confidence': confidence,
                  'source': 'web_entity',
                  'allLabels': foodEntities
                      .map<String>((entity) => entity['description'] as String)
                      .toList(),
                };
              }
            }
          } else {
            _logger.i('No web detection data in response');
          }

          // Check for label annotations
          if (annotations.containsKey('labelAnnotations')) {
            final labels = annotations['labelAnnotations'] as List;
            _logger.i('Found ${labels.length} label annotations');

            // Filter food-related labels
            final foodLabels = _filterFoodLabels(labels);
            _logger.i('Found ${foodLabels.length} food-related labels');

            if (foodLabels.isNotEmpty) {
              // Get the top food label
              final topFoodLabel = foodLabels[0];
              final String foodName = topFoodLabel['description'];
              final double confidence = topFoodLabel['score'] * 100;

              _logger.i('Google Vision identified food via label: $foodName with confidence: $confidence%');

              return {
                'name': foodName,
                'confidence': confidence.toInt(),
                'source': 'label_detection',
                'allLabels': foodLabels.map((label) => label['description']).toList(),
              };
            } else {
              _logger.w('No food-related labels found among ${labels.length} labels');
            }
          } else {
            _logger.w('No label annotations found in response');
          }

          // Check for object localization as last resort
          if (annotations.containsKey('localizedObjectAnnotations')) {
            final objects = annotations['localizedObjectAnnotations'] as List;
            _logger.i('Found ${objects.length} localized objects');

            // Filter food-related objects
            final foodObjects = _filterFoodObjects(objects);
            _logger.i('Found ${foodObjects.length} food-related objects');

            if (foodObjects.isNotEmpty) {
              final topObject = foodObjects[0];
              final String foodName = topObject['name'];
              final double confidence = topObject['score'] * 100;

              _logger.i('Google Vision identified food via object: $foodName with confidence: $confidence%');

              return {
                'name': foodName,
                'confidence': confidence.toInt(),
                'source': 'object_detection',
                'allLabels': foodObjects.map((obj) => obj['name']).toList(),
              };
            }
          }

          // No food identified
          _logger.w('Google Vision could not identify any food in the image');

          // Return all labels for potential fallback processing
          List<String> allLabels = [];
          if (annotations.containsKey('labelAnnotations')) {
            allLabels = (annotations['labelAnnotations'] as List)
                .map<String>((label) => label['description'] as String)
                .toList();
          }

          return {
            'error': 'No food identified in the image',
            'allLabels': allLabels,
          };
        } catch (e) {
          _logger.e('Error parsing Google Vision response: $e');
          return {
            'error': 'Error parsing API response',
            'details': e.toString(),
            'fallback': true,
          };
        }
      } else {
        // API request failed
        _logger.e('Google Vision API request failed: ${response?.statusCode} ${response?.body}');

        // Check for billing error
        if (response?.body != null && response!.body.contains("billing to be enabled")) {
          _logger.e('Google Vision API billing error: Billing needs to be enabled on the Google Cloud project');
          return {
            'error': 'API billing error',
            'details': 'The Google Cloud Vision API requires billing to be enabled on your Google Cloud project. Please visit the Google Cloud Console to enable billing.',
            'fallback': true,
          };
        }

        // Try with backup API key if we have a 403 error (authentication issue)
        if (response?.statusCode == 403) {
          _logger.w('Google Vision API authentication error (403 Forbidden). Trying backup API key...');

          // Only try if backup key is different from the primary key
          if (backupApiKey != apiKey && backupApiKey.isNotEmpty && !backupApiKey.contains('YOUR_')) {
            _logger.i('Using backup API key starting with: ${backupApiKey.substring(0, 5)}...');

            try {
              _logger.i('Trying backup API key with both authentication methods');

              // First try with API key in URL
              http.Response backupResponse = await http.post(
                Uri.parse('$apiEndpoint?key=$backupApiKey'),
                headers: {
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(requestBody),
              ).timeout(const Duration(seconds: 30));

              // If that fails, try with API key in header
              if (backupResponse.statusCode != 200) {
                _logger.i('Backup API key in URL failed, trying with header approach');
                backupResponse = await http.post(
                  Uri.parse(apiEndpointNoKey),
                  headers: {
                    'Content-Type': 'application/json',
                    'X-Goog-Api-Key': backupApiKey,
                  },
                  body: jsonEncode(requestBody),
                ).timeout(const Duration(seconds: 30));
              }

              // If backup API key works, process the response
              if (backupResponse.statusCode == 200) {
                _logger.i('Backup API key worked! Processing response...');

                // Parse the response
                final Map<String, dynamic> responseData = jsonDecode(backupResponse.body);

                // Extract the annotations
                final annotations = responseData['responses'][0];

                // Process the response the same way as the primary key
                if (annotations.containsKey('labelAnnotations')) {
                  final labels = annotations['labelAnnotations'] as List;

                  // Filter food-related labels
                  final foodLabels = _filterFoodLabels(labels);

                  if (foodLabels.isNotEmpty) {
                    // Get the top food label
                    final topFoodLabel = foodLabels[0];
                    final String foodName = topFoodLabel['description'];
                    final double confidence = topFoodLabel['score'] * 100;

                    _logger.i('Backup API identified food: $foodName with confidence: $confidence%');

                    return {
                      'name': foodName,
                      'confidence': confidence.toInt(),
                      'source': 'backup_api_key',
                      'allLabels': foodLabels.map((label) => label['description']).toList(),
                    };
                  }
                }

                // If no food labels found with backup key
                _logger.w('Backup API key worked but no food was identified');
              } else {
                _logger.w('Backup API key also failed with status: ${backupResponse.statusCode}');
              }
            } catch (e) {
              _logger.e('Error with backup API key: $e');
            }
          } else {
            _logger.w('No valid backup API key available or same as primary key');
          }

          // If backup key failed or wasn't used, return the original error
          return {
            'error': 'API authentication error (403 Forbidden)',
            'details': 'The API key may be invalid, expired, or have insufficient permissions.',
            'fallback': true,
          };
        } else if (response?.statusCode == 429) {
          _logger.w('Google Vision API rate limit exceeded (429 Too Many Requests)');
          return {
            'error': 'API rate limit exceeded',
            'details': 'Too many requests. Please try again later.',
            'fallback': true,
          };
        } else {
          return {
            'error': 'API request failed: ${response?.statusCode}',
            'details': response?.body ?? 'Unknown error',
            'fallback': true,
          };
        }
      }
    } catch (e) {
      // Exception occurred
      _logger.e('Error in Google Vision service: $e');
      return {
        'error': 'Error processing image: $e',
        'fallback': true,
      };
    }
  }

  // Filter labels to find food-related ones
  List<dynamic> _filterFoodLabels(List<dynamic> labels) {
    // Filter labels that are food-related using the _isFoodItem method
    return labels.where((label) {
      final description = label['description'].toString();
      return _isFoodItem(description);
    }).toList();
  }

  // Filter objects to find food-related ones
  List<dynamic> _filterFoodObjects(List<dynamic> objects) {
    // Filter objects that are food-related
    return objects.where((object) {
      final name = object['name'].toString().toLowerCase();
      return _isFoodItem(name);
    }).toList();
  }

  // Check if a string represents a food item
  bool _isFoodItem(String text) {
    // Comprehensive list of food-related keywords
    final foodKeywords = [
      // General food categories
      'food', 'dish', 'meal', 'cuisine', 'breakfast', 'lunch', 'dinner',
      'snack', 'appetizer', 'dessert', 'ingredient', 'produce',

      // Food types
      'fruit', 'vegetable', 'meat', 'fish', 'seafood', 'poultry', 'grain',
      'dairy', 'protein', 'carb', 'carbohydrate', 'fat', 'oil',

      // Specific foods
      'egg', 'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck',
      'rice', 'pasta', 'noodle', 'bread', 'toast', 'sandwich', 'wrap',
      'salad', 'soup', 'stew', 'curry', 'sauce', 'dip', 'spread',
      'pizza', 'burger', 'hotdog', 'taco', 'burrito', 'enchilada',
      'cake', 'cookie', 'pie', 'pastry', 'donut', 'muffin', 'cupcake',
      'chocolate', 'candy', 'sweet', 'ice cream', 'yogurt', 'cheese',
      'milk', 'cream', 'butter', 'margarine',

      // Cooking methods
      'fried', 'baked', 'grilled', 'roasted', 'boiled', 'steamed',
      'stir-fried', 'deep-fried', 'sautéed', 'braised', 'poached',

      // Indian foods
      'samosa', 'pakora', 'curry', 'masala', 'naan', 'roti', 'chapati',
      'dosa', 'idli', 'vada', 'biryani', 'tandoori', 'paneer', 'dal',

      // Beverages
      'drink', 'beverage', 'juice', 'smoothie', 'coffee', 'tea',
      'water', 'soda', 'beer', 'wine', 'cocktail', 'alcohol'
    ];

    // Convert to lowercase for case-insensitive matching
    final lowerText = text.toLowerCase();

    // Check if any food keyword is in the text
    return foodKeywords.any((keyword) => lowerText.contains(keyword));
  }
}
