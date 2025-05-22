import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/navigation_service.dart';
import '../services/user_service.dart';
import '../providers/nutrition_provider.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/standard_button.dart';

class NutritionPlanScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NutritionPlanScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<NutritionPlanScreen> createState() => _NutritionPlanScreenState();
}

class _NutritionPlanScreenState extends State<NutritionPlanScreen> {
  final UserService _userService = UserService();

  // Nutrition plan data
  late int _calories;
  late int _carbs;
  late int _protein;
  late int _fats;
  late int _healthScore;
  late String _goalText;
  late DateTime _targetDate;
  late double _targetWeight;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _calories = 2000;
    _carbs = 250;
    _protein = 150;
    _fats = 70;
    _healthScore = 7;
    _goalText = 'Maintain';
    _targetDate = DateTime.now().add(const Duration(days: 30));
    _targetWeight = 70.0;

    // Calculate nutrition plan asynchronously
    _calculateNutritionPlan().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _calculateNutritionPlan() async {
    // Get user data
    final gender = widget.userData['gender'] ?? 'other';
    final weight = (widget.userData['weight']?['value'] ?? 70.0) as double;
    final height = (widget.userData['height']?['value'] ?? 170.0) as double;
    final weightUnit = widget.userData['weight']?['unit'] ?? 'kg';
    final heightUnit = widget.userData['height']?['unit'] ?? 'cm';
    final dob = widget.userData['date_of_birth'] ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    final goalWeight = (widget.userData['goal_weight']?['value'] ?? weight) as double;
    final weightGoal = widget.userData['weightGoal'] ?? 'maintain';

    // Convert weight to kg if needed
    final weightKg = weightUnit == 'lbs' ? weight * 0.453592 : weight;
    final goalWeightKg = weightUnit == 'lbs' ? goalWeight * 0.453592 : goalWeight;

    // Convert height to cm if needed
    final heightCm = heightUnit == 'ft' ? height * 30.48 : height;

    // Calculate age
    final age = DateTime.now().year - (dob as DateTime).year;

    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (gender == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }

    // Apply activity level multiplier
    final activityLevel = widget.userData['activity_level'] ?? 'moderate';
    double activityMultiplier;
    switch (activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'very_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    // Calculate TDEE (Total Daily Energy Expenditure)
    final tdee = bmr * activityMultiplier;

    // Adjust calories based on weight goal
    double calorieAdjustment;
    switch (weightGoal) {
      case 'lose':
        calorieAdjustment = -500; // Calorie deficit for weight loss
        break;
      case 'gain':
        calorieAdjustment = 500; // Calorie surplus for weight gain
        break;
      default:
        calorieAdjustment = 0; // Maintain weight
    }

    // Calculate target calories
    _calories = (tdee + calorieAdjustment).round();

    // Calculate macronutrients
    // Protein: 30% of calories, 4 calories per gram
    _protein = ((_calories * 0.3) / 4).round();

    // Fats: 25% of calories, 9 calories per gram
    _fats = ((_calories * 0.25) / 9).round();

    // Carbs: 45% of calories, 4 calories per gram
    _carbs = ((_calories * 0.45) / 4).round();

    // Calculate health score (simplified version)
    _healthScore = 7; // Default score

    // Set goal text and target date
    final weightDiff = (goalWeightKg - weightKg).abs();

    // Calculate target date (assuming 0.5 kg per week for weight loss/gain)
    int weeksToGoal = (weightDiff / 0.5).ceil();
    if (weightGoal == 'maintain') {
      weeksToGoal = 0;
    }

    _targetDate = DateTime.now().add(Duration(days: weeksToGoal * 7));
    _targetWeight = goalWeight;

    // Set goal text
    if (weightGoal == 'lose') {
      _goalText = 'Lose';
    } else if (weightGoal == 'gain') {
      _goalText = 'Gain';
    } else {
      _goalText = 'Maintain';
    }

    // Save nutrition plan to user service
    _userService.saveUserData({
      'calories': _calories,
      'carbs': _carbs,
      'protein': _protein,
      'fats': _fats,
      'health_score': _healthScore,
    });

    // Save the calculated values to SharedPreferences for consistency
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calorie_goal', _calories);
    await prefs.setDouble('protein_goal', _protein.toDouble());
    await prefs.setDouble('carbs_goal', _carbs.toDouble());
    await prefs.setDouble('fat_goal', _fats.toDouble());

    // Update nutrition provider
    final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
    await nutritionProvider.updateNutritionGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildGoalSection(),
                const SizedBox(height: 30),
                _buildDailyRecommendationSection(),
                const SizedBox(height: 30),
                _buildHealthScoreSection(),
                const SizedBox(height: 30),
                _buildTipsSection(),
                const SizedBox(height: 40),
                _buildGetStartedButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Congratulations!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your personalized nutrition plan is ready',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSection() {
    // Format the target date
    final formattedDate = DateFormat('MMM d').format(_targetDate);

    // Format the weight with the correct unit
    final weightUnit = widget.userData['weight']?['unit'] ?? 'kg';
    final weightDiff = (_targetWeight - (widget.userData['weight']?['value'] ?? 70.0)).abs();
    final formattedWeight = weightDiff.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _goalText == 'Gain'
                    ? Icons.trending_up_rounded
                    : _goalText == 'Lose'
                        ? Icons.trending_down_rounded
                        : Icons.trending_flat_rounded,
                color: _goalText == 'Gain'
                    ? Colors.green
                    : _goalText == 'Lose'
                        ? Colors.orange
                        : AppColors.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Goal',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You should $_goalText:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$formattedWeight $weightUnit by $formattedDate',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecommendationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Recommendation',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'You can edit this any time',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.onSurfaceDisabled,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildNutrientCircle(
                  'Calories',
                  _calories.toString(),
                  AppColors.primaryColor,
                  Icons.local_fire_department_rounded,
                ),
              ),
              Expanded(
                child: _buildNutrientCircle(
                  'Carbs',
                  '${_carbs}g',
                  Colors.orange,
                  Icons.grain_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildNutrientCircle(
                  'Protein',
                  '${_protein}g',
                  Colors.redAccent,
                  Icons.fitness_center_rounded,
                ),
              ),
              Expanded(
                child: _buildNutrientCircle(
                  'Fats',
                  '${_fats}g',
                  Colors.blueAccent,
                  Icons.opacity_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCircle(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
            ),
            // Progress indicator
            SizedBox(
              width: 110,
              height: 110,
              child: CircularProgressIndicator(
                value: 0.75,
                strokeWidth: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            // Inner content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoreSection() {
    // Calculate color based on health score
    Color healthColor;
    if (_healthScore >= 8) {
      healthColor = Colors.green;
    } else if (_healthScore >= 6) {
      healthColor = Colors.orange;
    } else {
      healthColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  healthColor.withOpacity(0.7),
                  healthColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: healthColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health score',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Progress
                    Container(
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.5 * (_healthScore / 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            healthColor.withOpacity(0.7),
                            healthColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: healthColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_healthScore/10',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: healthColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to reach your goals:',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _buildTipItem(
            icon: Icons.favorite_outlined,
            color: Colors.redAccent,
            text: 'Use health scores to improve your routine',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            icon: Icons.restaurant_outlined,
            color: Colors.orangeAccent,
            text: 'Track your meals consistently',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            icon: Icons.local_drink_outlined,
            color: Colors.blueAccent,
            text: 'Stay hydrated throughout the day',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            icon: Icons.fitness_center_outlined,
            color: Colors.greenAccent,
            text: 'Combine nutrition with regular exercise',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Mark onboarding as completed
            _userService.setOnboardingCompleted(true);

            // Navigate to home screen
            NavigationService.navigateToAndRemoveUntil(Routes.home);
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Let's get started!",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
