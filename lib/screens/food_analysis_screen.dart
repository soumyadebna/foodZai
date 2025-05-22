import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../services/food_recognition_service.dart';
import '../services/food_database_service.dart';
import '../providers/nutrition_provider.dart';
import '../utils/constants.dart';
import '../screens/voice_input_screen.dart';

class FoodAnalysisScreen extends StatefulWidget {
  final String? mealType;
  final File? imageFile;
  final VoidCallback? onFoodAdded;

  const FoodAnalysisScreen({Key? key, this.mealType, this.imageFile, this.onFoodAdded}) : super(key: key);

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  final ImagePicker _picker = ImagePicker();
  final FoodRecognitionService _foodRecognitionService = FoodRecognitionService();
  final FoodDatabaseService _foodDatabaseService = FoodDatabaseService();
  final Logger _logger = Logger();

  File? _imageFile;
  bool _isAnalyzing = false;
  bool _analysisError = false;
  FoodItem? _recognizedFood;
  String _selectedMealType = 'Breakfast';
  String _analysisMessage = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.mealType != null && widget.mealType!.isNotEmpty) {
      // Standardize meal type to match expected format
      String standardizedMealType = _standardizeMealType(widget.mealType!);
      debugPrint('Setting meal type to: $standardizedMealType (from: ${widget.mealType})');

      _selectedMealType = standardizedMealType;
    } else {
      // Determine meal type based on current time
      final currentMealType = _getMealTypeBasedOnTime();
      debugPrint('Setting meal type based on time: $currentMealType');

      _selectedMealType = currentMealType;
    }

    // If image file is provided, use it
    if (widget.imageFile != null) {
      _imageFile = widget.imageFile;
      // Automatically analyze the image
      Future.delayed(Duration.zero, () {
        _analyzeImage();
      });
    } else {
      // If no image file is provided, open camera
      Future.delayed(Duration.zero, () {
        _takePicture();
      });
    }
  }

  /// Determine meal type based on current time
  String _getMealTypeBasedOnTime() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 11) {
      return 'Breakfast';
    } else if (hour >= 11 && hour < 16) {
      return 'Lunch';
    } else if (hour >= 16 && hour < 22) {
      return 'Dinner';
    } else {
      return 'Snack';
    }
  }

  // Helper method to standardize meal type
  String _standardizeMealType(String mealType) {
    // Ensure meal type matches the expected format
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
        return 'Breakfast'; // Default to Breakfast if unknown
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Food Analysis',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal type selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select meal type:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(
                    Icons.restaurant_menu,
                    color: AppColors.primaryColor,
                    size: 18,
                  ),
                  label: Text(
                    'Meal Types',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  onPressed: _showMealTypeSelector,
                ),
              ],
            ),
          ),

          // Meal type chips - improved layout
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildMealTypeChip('Breakfast')),
                const SizedBox(width: 8),
                Expanded(child: _buildMealTypeChip('Lunch')),
                const SizedBox(width: 8),
                Expanded(child: _buildMealTypeChip('Dinner')),
              ],
            ),
          ),

          // Image preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildImagePreview(),
            ),
          ),

          // Camera controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.photo_camera,
                  label: 'Take Photo',
                  onTap: _takePicture,
                  primary: true,
                ),
                _buildControlButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: _pickImage,
                  primary: false,
                ),
              ],
            ),
          ),

          // Error message
          if (_analysisError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage.contains('API authentication') ? 'API Error' : 'Food not recognized',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage.isNotEmpty
                        ? _errorMessage
                        : 'We couldn\'t identify what\'s in this photo. Please try taking a clearer photo or use voice input to describe your meal.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (_errorMessage.contains('API authentication error'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We\'re experiencing issues with our image recognition service. '
                            'Please try again later or contact support.',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to voice input screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VoiceInputScreen(
                                mealType: _selectedMealType,
                                onFoodAdded: widget.onFoodAdded,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.orange.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.mic, size: 18),
                        label: Text(
                          'VOICE INPUT',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          // Take a new picture
                          _takePicture();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: Text(
                          'RETAKE PHOTO',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMealTypeChip(String mealType) {
    final isSelected = _selectedMealType == mealType;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get icon based on meal type
    IconData icon;
    switch (mealType) {
      case 'Breakfast':
        icon = Icons.breakfast_dining;
        break;
      case 'Lunch':
        icon = Icons.lunch_dining;
        break;
      case 'Dinner':
        icon = Icons.dinner_dining;
        break;
      default:
        icon = Icons.cookie;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMealType = mealType;
          });
          // Add haptic feedback
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryColor
                : isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? null
                : Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                if (isSelected)
                  const SizedBox(width: 4),
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
                const SizedBox(width: 6),
                Text(
                  mealType,
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? Colors.white
                        : isDarkMode ? Colors.grey[300] : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              _analysisMessage.isNotEmpty ? _analysisMessage : 'Analyzing food...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (_recognizedFood != null) {
      // Show recognized food details
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Food image
              Image.file(
                _imageFile!,
                fit: BoxFit.cover,
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Food details
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name
                      Text(
                        _recognizedFood!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 8),

                      // Nutrition info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutritionItem(
                            'Calories',
                            '${_recognizedFood!.calories}',
                            'kcal',
                            Colors.orange,
                          ),
                          _buildNutritionItem(
                            'Protein',
                            '${_recognizedFood!.protein.toStringAsFixed(1)}',
                            'g',
                            Colors.green,
                          ),
                          _buildNutritionItem(
                            'Carbs',
                            '${_recognizedFood!.carbs.toStringAsFixed(1)}',
                            'g',
                            Colors.blue,
                          ),
                          _buildNutritionItem(
                            'Fat',
                            '${_recognizedFood!.fat.toStringAsFixed(1)}',
                            'g',
                            Colors.red,
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.3, end: 0),

                      // Disclaimer text
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Estimated values based on image analysis',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: 200.ms),

                      const SizedBox(height: 16),

                      // Add to diary button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveFoodItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Add to Diary',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _imageFile!,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'camera_button',
                    onPressed: _takePicture,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    foregroundColor: Colors.black,
                    child: const Icon(Icons.camera_alt),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'analyze_button',
                    onPressed: _analyzeImage,
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Take a photo of your food',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNutritionItem(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary ? AppColors.primaryColor : Colors.grey[200],
            foregroundColor: primary ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showMealTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Meal Type',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView(
                shrinkWrap: true,
                children: AppConstants.mealTypes.map((mealType) {
                  return ListTile(
                    title: Text(mealType),
                    leading: Icon(
                      mealType == 'Breakfast' ? Icons.breakfast_dining :
                      mealType == 'Lunch' ? Icons.lunch_dining :
                      mealType == 'Dinner' ? Icons.dinner_dining :
                      Icons.cookie,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedMealType = mealType;
                      });
                      Navigator.pop(context);
                    },
                    trailing: _selectedMealType == mealType
                        ? const Icon(Icons.check, color: AppColors.primaryColor)
                        : null,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Take a picture with the camera
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _recognizedFood = null;
          _analysisError = false;
        });

        // Automatically analyze the image
        await _analyzeImage();
      }
    } catch (e) {
      _logger.e('Error taking picture: $e');
      _showErrorSnackBar('Error taking picture. Please try again.');
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _recognizedFood = null;
          _analysisError = false;
        });

        // Automatically analyze the image
        await _analyzeImage();
      }
    } catch (e) {
      _logger.e('Error picking image: $e');
      _showErrorSnackBar('Error picking image. Please try again.');
    }
  }

  // Analyze the selected image
  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisError = false;
      _analysisMessage = 'Analyzing your food...';
    });

    try {
      // Check if the image file exists
      if (!await _imageFile!.exists()) {
        _showErrorSnackBar('Image file not found. Please try again.');
        setState(() {
          _isAnalyzing = false;
          _analysisError = true;
        });
        return;
      }

      // Log the image path for debugging
      _logger.i('Analyzing image at path: ${_imageFile!.path}');

      // Show a more detailed analysis message
      setState(() {
        _analysisMessage = 'Identifying food using Google Vision...';
      });

      // Standardize meal type before sending to the food recognition service
      final standardizedMealType = _standardizeMealType(_selectedMealType);
      debugPrint('Analyzing image with meal type: $standardizedMealType');

      // Analyze the image with our food recognition service
      final result = await _foodRecognitionService.recognizeFoodFromImage(
        _imageFile!,
        standardizedMealType,
      );

      // Log the result for debugging
      _logger.i('Food recognition result: $result');

      if (!mounted) return;

      // Check if there's an error message
      if (result.containsKey('error')) {
        final errorMessage = result['error'] as String;
        _logger.e('Error from food recognition service: $errorMessage');

        // Get additional details if available
        final String details = result.containsKey('details') ? result['details'] as String : '';
        _logger.e('Error details: $details');

        setState(() {
          _isAnalyzing = false;
          _analysisError = true;
          _errorMessage = details.isNotEmpty ? details : errorMessage;
        });

        // Show specific error message based on the error
        if (errorMessage.contains('Image clarity') || errorMessage.contains('unclear') || errorMessage.contains('Low confidence')) {
          setState(() {
            _errorMessage = details.isNotEmpty ? details : 'We couldn\'t identify what\'s in this photo. Please try taking a clearer photo or use voice input to describe your meal.';
          });
          _showClearErrorMessage('Image clarity issue: Please take a clearer photo with good lighting and the food centered in the frame, or use voice input instead.');
        } else if (errorMessage.contains('No internet connection')) {
          _showErrorSnackBar('No internet connection. Please check your network and try again.');
        } else if (errorMessage.contains('rate limit') || errorMessage.contains('quota')) {
          _showErrorSnackBar('API rate limit exceeded. Please try again later.');
        } else if (errorMessage.contains('Food not recognized') || errorMessage.contains('No nutrition information found')) {
          _showErrorSnackBar('We couldn\'t identify what\'s in this photo. Please try taking a clearer photo or use voice input to describe your meal.');
        } else if (errorMessage.contains('Network error') || errorMessage.contains('Failed to connect')) {
          setState(() {
            _errorMessage = 'Network error: Failed to connect to Google Vision API. Check your internet connection.';
          });
          _showErrorSnackBar('Network error. Please check your internet connection and try again.');
        } else if (errorMessage.contains('403') || errorMessage.contains('Forbidden')) {
          setState(() {
            _errorMessage = 'API authentication error (403 Forbidden). The API key may be invalid or have insufficient permissions.';
          });
          _showErrorSnackBar('API authentication error. Please check your API key configuration.');

          // Log more detailed information about the error
          _logger.e('API authentication error details:');
          _logger.e('- Error message: $errorMessage');
          _logger.e('- Details: ${result['details'] ?? 'No additional details'}');
          _logger.e('- API key in use: ${AppConstants.googleVisionApiKey.substring(0, 5)}...');
        } else if (errorMessage.contains('authentication')) {
          setState(() {
            _errorMessage = 'API authentication error. The API key may be invalid or have insufficient permissions.';
          });
          _showErrorSnackBar('API authentication error. Please check your API key configuration.');
        } else {
          _showErrorSnackBar('Error analyzing image: $errorMessage');
        }
        return;
      }

      // Create a food item from the result
      final foodItem = FoodItem(
        name: result['name'] as String,
        imageUrl: _imageFile!.path,
        calories: result['calories'] as int,
        protein: (result['protein'] as num).toDouble(),
        carbs: (result['carbs'] as num).toDouble(),
        fat: (result['fat'] as num).toDouble(),
        mealType: _selectedMealType,
        timestamp: DateTime.now(),
        portion: result['portion'] as String? ?? 'Standard serving',
        confidence: result['confidence'] as int? ?? 80,
        description: '',
      );

      setState(() {
        _isAnalyzing = false;
        _recognizedFood = foodItem;
        _analysisError = false;
        _analysisMessage = '';
      });

      // Check if we're using a fallback method and show a message
      final String source = result['source'] as String? ?? '';
      if (source.contains('fallback') || source.contains('direct_edamam')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Using estimated nutrition values for ${foodItem.name}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Check if the food is unknown
      if (foodItem.name.toLowerCase() == 'unknown food') {
        _showErrorSnackBar('We couldn\'t identify what\'s in this photo. Please try taking a clearer photo or use voice input to describe your meal.');
        setState(() {
          _analysisError = true;
          _errorMessage = 'We couldn\'t identify what\'s in this photo. Please try taking a clearer photo or use voice input to describe your meal.';
        });
        return;
      }

      // Log successful recognition
      _logger.i('Successfully recognized food: ${foodItem.name}');
      _logger.i('Nutritional values - Calories: ${foodItem.calories}, Protein: ${foodItem.protein}, Carbs: ${foodItem.carbs}, Fat: ${foodItem.fat}');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully recognized ${foodItem.name}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _logger.e('Error analyzing image: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisError = true;
          _analysisMessage = '';
        });
        _showErrorSnackBar('Error analyzing image. Please try again.');
      }
    }
  }

  // Save the recognized food item to the database
  Future<void> _saveFoodItem() async {
    if (_recognizedFood == null) return;

    try {
      // Show loading indicator
      setState(() {
        _isAnalyzing = true;
        _analysisMessage = 'Saving to your diary...';
      });

      // Standardize meal type before creating the food item
      final standardizedMealType = _standardizeMealType(_selectedMealType);
      debugPrint('Saving food item with meal type: $standardizedMealType');

      // Create a new food item with the current timestamp and standardized meal type
      final foodItem = FoodItem(
        name: _recognizedFood!.name,
        imageUrl: _recognizedFood!.imageUrl,
        calories: _recognizedFood!.calories,
        protein: _recognizedFood!.protein,
        carbs: _recognizedFood!.carbs,
        fat: _recognizedFood!.fat,
        mealType: standardizedMealType, // Use the standardized meal type
        timestamp: DateTime.now(), // Use current time
        portion: _recognizedFood!.portion,
        confidence: _recognizedFood!.confidence,
        description: _recognizedFood!.description,
      );

      // Log the food item being saved
      _logger.i('Saving food item to database: ${foodItem.name} (${foodItem.mealType})');
      _logger.i('Nutritional values - Calories: ${foodItem.calories}, Protein: ${foodItem.protein}, Carbs: ${foodItem.carbs}, Fat: ${foodItem.fat}');

      // Save the food item to the database
      await _foodDatabaseService.saveFoodItem(foodItem);

      // Get the nutrition provider and add the food item
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
      await nutritionProvider.addFoodItem(foodItem);

      if (!mounted) return;

      // Hide loading indicator
      setState(() {
        _isAnalyzing = false;
      });

      // Show success message with standardized meal type
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_recognizedFood!.name} added to your ${standardizedMealType.toLowerCase()} diary',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Notify any listeners that data has changed (this updates the home page)
      if (widget.onFoodAdded != null) {
        _logger.i('Notifying listeners that food was added');
        widget.onFoodAdded!();
      }

      // Force refresh of the nutrition provider
      nutritionProvider.refresh();

      // Navigate back to previous screen after a short delay
      // This ensures the snackbar is visible before navigating
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _logger.i('Navigating back to previous screen');
          Navigator.pop(context, true); // Return true to indicate food was added
        }
      });
    } catch (e) {
      _logger.e('Error saving food item: $e');

      if (mounted) {
        // Hide loading indicator
        setState(() {
          _isAnalyzing = false;
        });

        // Show error message
        _showErrorSnackBar('Error saving food item. Please try again.');
      }
    }
  }



  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show a clear error message to the user
  void _showClearErrorMessage(String message) {
    if (!mounted) return;

    _logger.i('Showing clear error message to user');

    // Show a message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
