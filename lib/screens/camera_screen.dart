import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_item.dart';
import '../services/food_recognition_service.dart';
import '../services/user_service.dart';
import '../widgets/standard_button.dart';
import '../utils/string_extensions.dart';
import 'food_analysis_screen.dart';

class CameraScreen extends StatefulWidget {
  final String? mealType;

  const CameraScreen({Key? key, this.mealType}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isAnalyzing = false;
  FoodItem? _recognizedFood;
  String _selectedMealType = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  final FoodRecognitionService _foodRecognitionService = FoodRecognitionService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Set meal type if provided, otherwise determine based on time
    if (widget.mealType != null && widget.mealType!.isNotEmpty) {
      // Standardize meal type to match expected format
      String standardizedMealType = _standardizeMealType(widget.mealType!);
      debugPrint('Setting meal type to: $standardizedMealType (from: ${widget.mealType})');

      setState(() {
        _selectedMealType = standardizedMealType;
      });
    } else {
      // Determine meal type based on current time
      final currentMealType = _getMealTypeBasedOnTime();
      debugPrint('Setting meal type based on time: $currentMealType');

      setState(() {
        _selectedMealType = currentMealType;
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

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final imageFile = File(image.path);

      // Navigate to the food analysis screen with the image
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodAnalysisScreen(
            imageFile: imageFile,
            mealType: _selectedMealType,
            onFoodAdded: () {
              // Refresh data on the home screen
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true); // Return true to indicate food was added
              }
            },
          ),
        ),
      );

      // If food was added, return to home screen
      if (result == true) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true); // Return to home screen with refresh flag
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageFile = File(image.path);

      // Navigate to the food analysis screen with the image
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodAnalysisScreen(
            imageFile: imageFile,
            mealType: _selectedMealType,
            onFoodAdded: () {
              // Refresh data on the home screen
              if (Navigator.canPop(context)) {
                Navigator.pop(context, true); // Return true to indicate food was added
              }
            },
          ),
        ),
      );

      // If food was added, return to home screen
      if (result == true) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true); // Return to home screen with refresh flag
        }
      }
    }
  }

  Future<void> _saveFoodItem() async {
    if (_recognizedFood != null) {
      await _userService.addFoodItem(_recognizedFood!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_recognizedFood!.name} added to your diary',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Food Analysis',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal type selector
              Row(
                children: [
                  Text(
                    'Select meal type:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Meal Types',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mealTypes.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemBuilder: (context, index) {
                    final mealType = _mealTypes[index];
                    final isSelected = mealType == _selectedMealType;

                    // Get icon for meal type
                    IconData mealIcon = Icons.breakfast_dining;
                    if (mealType == 'Lunch') {
                      mealIcon = Icons.lunch_dining;
                    } else if (mealType == 'Dinner') {
                      mealIcon = Icons.dinner_dining;
                    } else if (mealType == 'Snack') {
                      mealIcon = Icons.cookie;
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMealType = mealType;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              mealIcon,
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mealType,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ).animate(target: isSelected ? 1 : 0)
                        .elevation(begin: 0, end: 5),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Image preview or placeholder
              Container(
                width: double.infinity,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Image or placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _imageFile != null
                          ? Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Container(
                              color: Colors.grey[100],
                              width: double.infinity,
                              height: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Take a picture of your food',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'For best results, ensure good lighting',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // Overlay gradient at the bottom
                    if (_imageFile != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Camera controls overlay
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Camera and gallery buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: StandardButton(
                      text: 'Take Photo',
                      onPressed: _takePicture,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      height: 54,
                      icon: Icons.camera_alt,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StandardButton(
                      text: 'Gallery',
                      onPressed: _pickImage,
                      backgroundColor: Colors.grey[800],
                      height: 54,
                      icon: Icons.photo_library,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Analysis results
              if (_isAnalyzing)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator()
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 300)),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing your food with Gemini AI...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 300))
                          .then(delay: const Duration(milliseconds: 500))
                          .shimmer(duration: const Duration(milliseconds: 1500), curve: Curves.easeInOut),
                    ],
                  ),
                ),

              if (_recognizedFood != null)
                _buildFoodAnalysisResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodAnalysisResult() {
    // Calculate confidence color
    Color confidenceColor = Colors.green;
    if (_recognizedFood!.confidence < 70) {
      confidenceColor = Colors.red;
    } else if (_recognizedFood!.confidence < 90) {
      confidenceColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with confidence indicator
          Row(
            children: [
              Expanded(
                child: Text(
                  'Analysis Result',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: confidenceColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_recognizedFood!.confidence}% Match',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: confidenceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: const Duration(milliseconds: 300)),

          const SizedBox(height: 20),

          // Food name and portion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recognizedFood!.name.capitalize(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _recognizedFood!.portion,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 400)),

          const SizedBox(height: 24),

          // Nutrition info title
          Text(
            'Nutritional Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 500)),

          const SizedBox(height: 16),

          // Nutrition info cards
          Row(
            children: [
              _buildNutritionItem(
                'Calories',
                '${_recognizedFood!.calories}',
                'kcal',
                Colors.orange,
              ).animate().fadeIn(duration: const Duration(milliseconds: 600)).slideY(begin: 0.2, end: 0),
              _buildNutritionItem(
                'Protein',
                '${_recognizedFood!.protein.toStringAsFixed(1)}',
                'g',
                Colors.red,
              ).animate().fadeIn(duration: const Duration(milliseconds: 700)).slideY(begin: 0.2, end: 0),
              _buildNutritionItem(
                'Carbs',
                '${_recognizedFood!.carbs.toStringAsFixed(1)}',
                'g',
                Colors.green,
              ).animate().fadeIn(duration: const Duration(milliseconds: 800)).slideY(begin: 0.2, end: 0),
              _buildNutritionItem(
                'Fat',
                '${_recognizedFood!.fat.toStringAsFixed(1)}',
                'g',
                Colors.blue,
              ).animate().fadeIn(duration: const Duration(milliseconds: 900)).slideY(begin: 0.2, end: 0),
            ],
          ),

          // Disclaimer text
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated values based on image analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 950)),

          const SizedBox(height: 30),

          // Add to diary button
          StandardButton(
            text: 'Add to Diary',
            onPressed: _saveFoodItem,
            backgroundColor: Theme.of(context).colorScheme.primary,
            height: 54,
            icon: Icons.add_circle_outline,
          ).animate().fadeIn(duration: const Duration(milliseconds: 1000)).slideY(begin: 0.2, end: 0),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildNutritionItem(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                label == 'Calories'
                    ? Icons.local_fire_department
                    : label == 'Protein'
                        ? Icons.fitness_center
                        : label == 'Carbs'
                            ? Icons.grain
                            : Icons.opacity,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
