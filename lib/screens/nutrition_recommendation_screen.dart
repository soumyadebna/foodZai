import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/standard_button.dart';
import '../services/navigation_service.dart';
import '../services/user_service.dart';
import '../utils/routes.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class NutritionRecommendationScreen extends StatefulWidget {
  final VoidCallback? onNext;
  final Map<String, dynamic> userData;

  const NutritionRecommendationScreen({
    Key? key,
    this.onNext,
    required this.userData,
  }) : super(key: key);

  @override
  State<NutritionRecommendationScreen> createState() => _NutritionRecommendationScreenState();
}

class _NutritionRecommendationScreenState extends State<NutritionRecommendationScreen> {
  // Current page in the onboarding flow
  final int _currentPage = Constants.nutritionRecommendationScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;

  // User service for saving data
  final UserService _userService = UserService();

  // Loading state
  bool _isLoading = false;

  // Nutrition data
  late int _calories;
  late int _carbs;
  late int _protein;
  late int _fats;
  late String _goalType;
  late double _targetWeight;
  late String _targetDate;
  late int _healthScore;

  @override
  void initState() {
    super.initState();

    // Determine goal type and calculate nutrition values
    _calculateNutritionValues();

    // Add a post-frame callback to ensure the context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Save the user data to shared preferences or other storage
      // This is important to have the data available when we navigate to the home screen
      _saveUserData();
    });
  }

  // Save user data to be used in the home screen
  Future<void> _saveUserData() async {
    try {
      // Get current weight from userData
      double currentWeight = 0.0;
      if (widget.userData['weight'] != null) {
        if (widget.userData['weight'] is Map) {
          currentWeight = (widget.userData['weight']['value'] is int)
              ? (widget.userData['weight']['value'] as int).toDouble()
              : widget.userData['weight']['value'] as double;
        } else if (widget.userData['weight'] is num) {
          currentWeight = (widget.userData['weight'] as num).toDouble();
        }
      } else {
        currentWeight = 52.0; // Default to 52kg as specified
      }

      // Calculate goal weight based on weight goal
      double goalWeight = 54.0; // Default to 54kg as specified
      if (_goalType == 'lose') {
        goalWeight = currentWeight - 5.0;
      } else if (_goalType == 'gain') {
        goalWeight = currentWeight + 5.0;
      } else if (_goalType == 'maintain') {
        goalWeight = currentWeight;
      }

      // Create weight and goal weight maps
      final String weightUnit = widget.userData['weight_unit'] as String? ?? 'kg';
      final weightMap = {
        'value': currentWeight,
        'unit': weightUnit,
        'initial_value': currentWeight, // Store initial value for progress tracking
      };

      final goalWeightMap = {
        'value': goalWeight,
        'unit': weightUnit,
      };

      // Create a complete user model with all the data
      final Map<String, dynamic> userData = {
        ...widget.userData,
        'calories': _calories,
        'protein': _protein,
        'carbs': _carbs,
        'fat': _fats,
        'healthScore': _healthScore,
        'targetDate': _targetDate,
        'weightGoal': _goalType,
        'weight_goal': _goalType, // Add both formats for compatibility
        'weight': weightMap,
        'goalWeight': goalWeightMap,
        'goal_weight': goalWeight,
        'goal_weight_unit': weightUnit,
        'nutritionTargets': {
          'calories': _calories,
          'protein': _protein,
          'carbs': _carbs,
          'fat': _fats,
        },
        'onboardingCompleted': true,
      };

      // Save the user data using UserService
      await _userService.saveUserData(userData);

      // Mark onboarding as completed
      await _userService.setOnboardingCompleted(true);

      debugPrint('User data saved successfully: $userData');
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Navigate directly to home screen
  Future<void> _navigateToHomeScreen() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Save user data before navigation
      await _saveUserData();

      // Double-check that onboarding is marked as completed
      await _userService.setOnboardingCompleted(true);

      debugPrint('Navigation to home screen initiated');

      // Use Navigator.pushAndRemoveUntil for more reliable navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // Remove all previous routes
      );

      // If the callback exists, call it
      if (widget.onNext != null) {
        widget.onNext!();
      }
    } catch (e) {
      debugPrint('Error navigating to home screen: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving data. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateNutritionValues() {
    // Get weight data from user data
    final weightData = widget.userData['weight'] as Map<String, dynamic>?;
    final goalWeightData = widget.userData['goal_weight'] as Map<String, dynamic>?;
    final heightData = widget.userData['height'] as Map<String, dynamic>?;
    final gender = widget.userData['gender'] as String? ?? 'male';
    final activityLevel = widget.userData['activity_level'] as String? ?? 'moderate';
    final weightGoal = widget.userData['weightGoal'] as String? ?? 'maintain';

    final currentWeight = weightData != null ? (weightData['value'] as double?) ?? 70.0 : 70.0;
    final height = heightData != null ? (heightData['value'] as double?) ?? 170.0 : 170.0;
    _targetWeight = goalWeightData != null ? (goalWeightData['value'] as double?) ?? currentWeight : currentWeight;

    // Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * currentWeight + 6.25 * height - 5 * 25 + 5; // Assuming age 25
    } else {
      bmr = 10 * currentWeight + 6.25 * height - 5 * 25 - 161; // Assuming age 25
    }

    // Apply activity multiplier
    double activityMultiplier;
    switch (activityLevel) {
      case 'beginner':
        activityMultiplier = 1.2; // Sedentary
        break;
      case 'intermediate':
        activityMultiplier = 1.55; // Moderate activity
        break;
      case 'advanced':
        activityMultiplier = 1.725; // Very active
        break;
      default:
        activityMultiplier = 1.375; // Light activity
    }

    double tdee = bmr * activityMultiplier; // Total Daily Energy Expenditure

    // Use the weightGoal field to determine goal type and adjust calories
    _goalType = weightGoal;

    if (_goalType == 'gain') {
      // For weight gain, add 500 calories to TDEE
      _calories = (tdee + 500).round();
      // Macronutrient distribution for muscle gain: 40% carbs, 30% protein, 30% fat
      _carbs = ((_calories * 0.4) / 4).round(); // 4 calories per gram of carbs
      _protein = ((_calories * 0.3) / 4).round(); // 4 calories per gram of protein
      _fats = ((_calories * 0.3) / 9).round(); // 9 calories per gram of fat
    } else if (_goalType == 'lose') {
      // For weight loss, subtract 500 calories from TDEE
      _calories = (tdee - 500).round();
      // Macronutrient distribution for fat loss: 35% carbs, 40% protein, 25% fat
      _carbs = ((_calories * 0.35) / 4).round();
      _protein = ((_calories * 0.4) / 4).round();
      _fats = ((_calories * 0.25) / 9).round();
    } else {
      // For maintenance, use TDEE
      _calories = tdee.round();
      // Balanced macronutrient distribution: 40% carbs, 30% protein, 30% fat
      _carbs = ((_calories * 0.4) / 4).round();
      _protein = ((_calories * 0.3) / 4).round();
      _fats = ((_calories * 0.3) / 9).round();
    }

    // Calculate target date based on safe weight change rate
    // Safe rate: 0.5-1 kg per week for weight loss, 0.25-0.5 kg per week for weight gain
    double weeklyChangeRate = _goalType == 'gain' ? 0.25 : 0.5; // kg per week
    double totalChange = (_targetWeight - currentWeight).abs();
    int weeksNeeded = (totalChange / weeklyChangeRate).ceil();

    final now = DateTime.now();
    final targetDate = now.add(Duration(days: weeksNeeded * 7));
    _targetDate = '${targetDate.month}/${targetDate.day}/${targetDate.year}';

    // Calculate health score based on balanced nutrition and realistic goals
    if (weeksNeeded > 52) {
      // Long-term goals (over a year) get a lower health score
      _healthScore = 6;
    } else if (weeksNeeded > 26) {
      // Medium-term goals (6 months to a year)
      _healthScore = 7;
    } else {
      // Short-term, achievable goals
      _healthScore = 8;
    }
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.primary : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button and progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Progress dots
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildPageIndicator(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Success icon
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Center(
                child: Text(
                  'Congratulations\nyour custom plan is ready!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Goal text
              Center(
                child: Text(
                  'You should ${_goalType.capitalize()}:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Target weight and weekly progress
              Column(
                children: [
                  Center(
                    child: Text(
                      '${(_targetWeight - (widget.userData['weight'] != null ? (widget.userData['weight'] as Map<String, dynamic>)['value'] as double : 70.0)).abs().toStringAsFixed(1)} ${widget.userData['weight'] != null ? (widget.userData['weight'] as Map<String, dynamic>)['unit'] as String : 'kg'} by $_targetDate',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Weekly progress: ${(_goalType == 'gain' ? '+' : '-')}${(_goalType == 'gain' ? 0.25 : 0.5)} kg per week',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _goalType == 'gain' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Daily recommendation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          Text(
                            'Daily Recommendation',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'You can edit this any time',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildNutrientCircle('Calories', _calories.toString(), Colors.black87)),
                          Expanded(child: _buildNutrientCircle('Carbs', '${_carbs}g', Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildNutrientCircle('Protein', '${_protein}g', Colors.redAccent)),
                          Expanded(child: _buildNutrientCircle('Fats', '${_fats}g', Colors.blueAccent)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.pinkAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Health score',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$_healthScore/10',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _healthScore / 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // How to reach goals
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to reach your goals:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_goalType == 'gain') ...[
                      _buildTipItem('Eat ${_calories} calories daily to gain weight steadily'),
                      const SizedBox(height: 8),
                      _buildTipItem('Focus on protein-rich foods to build muscle'),
                      const SizedBox(height: 8),
                      _buildTipItem('Include strength training 3-4 times per week'),
                    ] else if (_goalType == 'lose') ...[
                      _buildTipItem('Maintain a calorie deficit of 500 calories daily'),
                      const SizedBox(height: 8),
                      _buildTipItem('Increase protein intake to preserve muscle mass'),
                      const SizedBox(height: 8),
                      _buildTipItem('Combine cardio and strength training for best results'),
                    ] else ...[
                      _buildTipItem('Balance your macronutrients for optimal health'),
                      const SizedBox(height: 8),
                      _buildTipItem('Stay consistent with your daily calorie intake'),
                      const SizedBox(height: 8),
                      _buildTipItem('Exercise regularly to maintain fitness levels'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Get started button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    StandardButton(
                      text: 'Let\'s get started!',
                      onPressed: () async {
                        await _navigateToHomeScreen();
                      },
                      backgroundColor: Colors.black87,
                      animationDelay: 700.ms,
                    ),

                    const SizedBox(height: 16),

                    // Hidden for production
                  ],
                ),
              ),

              // Bottom indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNutrientCircle(String label, String value, Color color) {
    // Calculate progress values based on goal type
    double progressValue;
    switch (label) {
      case 'Calories':
        progressValue = _goalType == 'gain' ? 0.75 : (_goalType == 'lose' ? 0.65 : 0.7);
        break;
      case 'Carbs':
        progressValue = _goalType == 'gain' ? 0.8 : (_goalType == 'lose' ? 0.6 : 0.7);
        break;
      case 'Protein':
        progressValue = _goalType == 'gain' ? 0.7 : (_goalType == 'lose' ? 0.85 : 0.75);
        break;
      case 'Fats':
        progressValue = _goalType == 'gain' ? 0.65 : (_goalType == 'lose' ? 0.55 : 0.6);
        break;
      default:
        progressValue = 0.7;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progressValue,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String tip) {
    // Generate a random icon for each tip
    final List<IconData> tipIcons = [
      Icons.favorite,
      Icons.restaurant,
      Icons.fitness_center,
      Icons.directions_run,
      Icons.local_fire_department,
      Icons.water_drop,
    ];

    final List<List<Color>> tipGradients = [
      [const Color(0xFFFF5252), const Color(0xFFD32F2F)], // Red
      [const Color(0xFF4CAF50), const Color(0xFF388E3C)], // Green
      [const Color(0xFF448AFF), const Color(0xFF1976D2)], // Blue
      [const Color(0xFFAB47BC), const Color(0xFF7B1FA2)], // Purple
      [const Color(0xFFFFB74D), const Color(0xFFFF9800)], // Orange
    ];

    // Use a hash of the tip string to get consistent icons and colors for the same tips
    final int tipHash = tip.hashCode.abs();
    final IconData tipIcon = tipIcons[tipHash % tipIcons.length];
    final List<Color> gradientColors = tipGradients[tipHash % tipGradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Could add functionality to show more details
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Tip icon with gradient background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    tipIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}