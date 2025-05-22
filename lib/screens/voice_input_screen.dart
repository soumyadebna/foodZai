import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/nutrition_provider.dart';
import '../services/voice_recognition_service.dart';
import '../services/text_to_food_service.dart';
import '../utils/constants.dart';
import '../utils/enhanced_animations.dart';

class VoiceInputScreen extends StatefulWidget {
  final String? mealType;
  final Function? onFoodAdded;

  const VoiceInputScreen({
    Key? key,
    this.mealType,
    this.onFoodAdded,
  }) : super(key: key);

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> with SingleTickerProviderStateMixin {
  final VoiceRecognitionService _voiceRecognitionService = VoiceRecognitionService();
  final TextToFoodService _textToFoodService = TextToFoodService();

  String _recognizedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isError = false;
  String _errorMessage = '';

  List<FoodItem> _extractedFoodItems = [];
  Map<String, dynamic>? _nutritionData;

  late AnimationController _animationController;

  String get _selectedMealType => widget.mealType ?? _getCurrentMealType();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _initializeVoiceRecognition();

    // Listen for text updates
    _voiceRecognitionService.textStream.listen((text) {
      setState(() {
        _recognizedText = text;
      });
    });

    // Listen for status updates
    _voiceRecognitionService.listeningStatusStream.listen((isListening) {
      setState(() {
        _isListening = isListening;
      });

      if (isListening) {
        _animationController.repeat(reverse: true);

        // Add haptic feedback when recording starts
        HapticFeedback.mediumImpact();
      } else {
        _animationController.stop();
        _animationController.reset();

        // Add haptic feedback when recording stops
        HapticFeedback.mediumImpact();

        // If we have text and we're no longer listening, process it
        if (_recognizedText.isNotEmpty) {
          _processRecognizedText();
        }
      }
    });

    // Start listening automatically after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _startListening();
    });
  }

  @override
  void dispose() {
    _voiceRecognitionService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoiceRecognition() async {
    final isInitialized = await _voiceRecognitionService.initialize();
    if (!isInitialized) {
      setState(() {
        _isError = true;
        _errorMessage = 'Could not initialize speech recognition. Please check your microphone permissions.';
      });
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isError = false;
      _errorMessage = '';
      _extractedFoodItems = [];
      _nutritionData = null;
    });

    try {
      // Check if speech recognition is available
      final isAvailable = await _voiceRecognitionService.isAvailable();
      if (!isAvailable) {
        setState(() {
          _isError = true;
          _errorMessage = 'Speech recognition is not available on this device. Please check your microphone permissions.';
        });
        return;
      }

      final success = await _voiceRecognitionService.startListening();
      if (!success) {
        setState(() {
          _isError = true;
          _errorMessage = 'Could not start speech recognition. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('Error in _startListening: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _stopListening() async {
    await _voiceRecognitionService.stopListening();
  }

  Future<void> _processRecognizedText() async {
    if (_recognizedText.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _textToFoodService.extractFoodFromText(
        _recognizedText,
        _selectedMealType,
      );

      if (result.containsKey('error')) {
        setState(() {
          _isError = true;
          _errorMessage = result['details'] ?? 'Could not extract food information from the text.';
          _isProcessing = false;
        });
        return;
      }

      final foodItems = _textToFoodService.convertToFoodItems(result, _selectedMealType);

      setState(() {
        _extractedFoodItems = foodItems;
        _nutritionData = result['total'];
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'An error occurred while processing the text: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _addFoodToMeal() async {
    if (_extractedFoodItems.isEmpty) return;

    try {
      final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);

      // Add each food item to the daily nutrition
      for (final foodItem in _extractedFoodItems) {
        await nutritionProvider.addFoodItem(foodItem);
      }

      // Call the onFoodAdded callback if provided
      if (widget.onFoodAdded != null) {
        widget.onFoodAdded!();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_extractedFoodItems.length} food item(s) to your ${_selectedMealType.toLowerCase()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error adding food items: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getCurrentMealType() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice Input',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Meal type indicator
            _buildMealTypeIndicator(),

            // Main content
            Expanded(
              child: _isProcessing
                  ? _buildLoadingState()
                  : _extractedFoodItems.isNotEmpty
                      ? _buildResultsView()
                      : _buildVoiceInputView(),
            ),
          ],
        ),
      ),
      floatingActionButton: _extractedFoodItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addFoodToMeal,
              label: Text(
                'Add to Meal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              icon: const Icon(Icons.check),
              backgroundColor: AppColors.primaryColor,
            )
          : _isListening
              ? FloatingActionButton(
                  onPressed: _stopListening,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.stop),
                )
              : FloatingActionButton(
                  onPressed: _startListening,
                  backgroundColor: AppColors.primaryColor,
                  child: const Icon(Icons.mic),
                ),
    );
  }

  Widget _buildMealTypeIndicator() {
    IconData icon;
    Color color;

    switch (_selectedMealType) {
      case 'Breakfast':
        icon = Icons.wb_sunny_rounded;
        color = Colors.orange;
        break;
      case 'Lunch':
        icon = Icons.lunch_dining_rounded;
        color = Colors.green;
        break;
      case 'Dinner':
        icon = Icons.dinner_dining_rounded;
        color = Colors.purple;
        break;
      default: // Snack
        icon = Icons.icecream_rounded;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Adding to $_selectedMealType',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInputView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Microphone animation with sound wave effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple effect
              if (_isListening)
                ...List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final value = (_animationController.value - delay).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: (1.0 - value).clamp(0.0, 0.7),
                        child: Container(
                          width: 120 + (value * 100),
                          height: 120 + (value * 100),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),

              // Main microphone circle
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (_isListening ? (_animationController.value * 20) : 0),
                    height: 120 + (_isListening ? (_animationController.value * 20) : 0),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? AppColors.primaryColor.withOpacity(0.2)
                          : AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isListening
                            ? AppColors.primaryColor
                            : AppColors.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mic,
                        size: 60 + (_isListening ? (_animationController.value * 10) : 0),
                        color: _isListening
                            ? AppColors.primaryColor
                            : AppColors.primaryColor.withOpacity(0.7),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isListening ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  color: _isListening ? Colors.green : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isListening ? 'Listening...' : 'Not listening',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isListening ? Colors.green : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Text(
            _isListening
                ? 'Speak clearly and describe your food'
                : 'Tap the microphone button to start',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Example: "I had 200ml of skimmed milk with 50g of oats"',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recognized text:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error message
          if (_isError) ...[
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[800], size: 24),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  strokeWidth: 4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Processing status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sync,
                  color: Colors.blue,
                  size: 18,
                ).animate(
                  onPlay: (controller) => controller.repeat(),
                ).rotate(
                  duration: const Duration(seconds: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Processing message
          Text(
            'Analyzing your food description',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Using AI to calculate nutrition information',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          // Show the recognized text
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processing text:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analysis Complete',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Original text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You said:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _recognizedText,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Total nutrition
          if (_nutritionData != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.pie_chart,
                  size: 20,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Nutrition',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientColumn('Calories', '${_nutritionData!['calories']}', Icons.local_fire_department, Colors.orange),
                  _buildNutrientColumn('Protein', '${_nutritionData!['protein']}g', Icons.fitness_center, Colors.red),
                  _buildNutrientColumn('Carbs', '${_nutritionData!['carbs']}g', Icons.grain, Colors.green),
                  _buildNutrientColumn('Fat', '${_nutritionData!['fat']}g', Icons.opacity, Colors.blue),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Food items list
          Row(
            children: [
              const Icon(
                Icons.restaurant,
                size: 20,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Identified Food Items',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              itemCount: _extractedFoodItems.length,
              itemBuilder: (context, index) {
                final foodItem = _extractedFoodItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _getFoodIcon(foodItem.name),
                                  color: AppColors.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    foodItem.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    foodItem.portion,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${foodItem.calories} kcal',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNutrientBadge('P', foodItem.protein.toInt(), Colors.red[400]!),
                            _buildNutrientBadge('C', foodItem.carbs.toInt(), Colors.green[400]!),
                            _buildNutrientBadge('F', foodItem.fat.toInt(), Colors.blue[400]!),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get an appropriate icon for a food item based on its name
  IconData _getFoodIcon(String foodName) {
    final name = foodName.toLowerCase();

    if (name.contains('milk') || name.contains('yogurt') || name.contains('dairy')) {
      return Icons.opacity;
    } else if (name.contains('bread') || name.contains('toast') || name.contains('sandwich')) {
      return Icons.breakfast_dining;
    } else if (name.contains('egg')) {
      return Icons.egg;
    } else if (name.contains('meat') || name.contains('chicken') || name.contains('beef') || name.contains('pork')) {
      return Icons.restaurant;
    } else if (name.contains('fruit') || name.contains('apple') || name.contains('banana') || name.contains('orange')) {
      return Icons.apple;
    } else if (name.contains('vegetable') || name.contains('salad') || name.contains('broccoli')) {
      return Icons.eco;
    } else if (name.contains('rice') || name.contains('pasta') || name.contains('noodle')) {
      return Icons.rice_bowl;
    } else if (name.contains('coffee') || name.contains('tea')) {
      return Icons.coffee;
    } else if (name.contains('water') || name.contains('juice') || name.contains('drink')) {
      return Icons.local_drink;
    } else if (name.contains('cake') || name.contains('dessert') || name.contains('sweet') || name.contains('chocolate')) {
      return Icons.cake;
    } else if (name.contains('oats') || name.contains('cereal') || name.contains('granola')) {
      return Icons.breakfast_dining;
    } else {
      return Icons.restaurant_menu;
    }
  }

  Widget _buildNutrientColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value g',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
