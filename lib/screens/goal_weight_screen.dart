import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../services/navigation_service.dart';
import '../services/user_service.dart';
import 'meal_timing_screen.dart';
import '../widgets/standard_button.dart';

class GoalWeightScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onNext;

  const GoalWeightScreen({
    Key? key,
    required this.userData,
    this.onNext,
  }) : super(key: key);

  @override
  State<GoalWeightScreen> createState() => _GoalWeightScreenState();
}

class _GoalWeightScreenState extends State<GoalWeightScreen> {
  // Weight values for scrolling picker
  int _selectedWeightIndex = 54;
  // Expanded range for kg (30-300 kg)
  final List<int> _kgValues = List.generate(271, (index) => index + 30); // 30-300 kg
  // Expanded range for lbs (66-660 lbs)
  final List<int> _lbsValues = List.generate(595, (index) => index + 66); // 66-660 lbs
  // Current values based on selected unit
  List<int> get _weightValues => _selectedUnit == 'kg' ? _kgValues : _lbsValues;

  // Controllers for the scroll views
  final FixedExtentScrollController _weightController = FixedExtentScrollController(initialItem: 24);

  // Selected unit
  String _selectedUnit = 'kg'; // Default unit
  final List<String> _units = ['lbs', 'kg'];

  bool _isMetric = true; // Default to metric

  // Current page in the onboarding flow
  final int _currentPage = Constants.goalWeightScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;

  @override
  void initState() {
    super.initState();

    // Initialize with existing user data if available
    if (widget.userData.containsKey('weight') && widget.userData['weight'] != null) {
      final weightData = widget.userData['weight'] as Map<String, dynamic>;
      final weightValue = weightData['value'] as double;
      final weightUnit = weightData['unit'] as String;

      if (weightUnit == 'kg') {
        _isMetric = true;
        _selectedUnit = 'kg';
        // Set initial weight to be slightly higher than current weight for goal
        _selectedWeightIndex = (weightValue + 2).round();

        // Find the closest value in our kg list
        int closestIndex = 0;
        int minDifference = 1000;

        for (int i = 0; i < _kgValues.length; i++) {
          final diff = (_kgValues[i] - _selectedWeightIndex).abs();
          if (diff < minDifference) {
            minDifference = diff;
            closestIndex = i;
          }
        }

        if (closestIndex >= 0) {
          _weightController.jumpToItem(closestIndex);
        }
      } else if (weightUnit == 'lbs') {
        _isMetric = false;
        _selectedUnit = 'lbs';

        // Convert lbs to kg for display, then add 5lbs for goal
        final goalWeightLbs = (weightValue + 5).round();
        _selectedWeightIndex = goalWeightLbs;

        // Find the closest value in our lbs list
        int closestIndex = 0;
        int minDifference = 1000;

        for (int i = 0; i < _lbsValues.length; i++) {
          final diff = (_lbsValues[i] - _selectedWeightIndex).abs();
          if (diff < minDifference) {
            minDifference = diff;
            closestIndex = i;
          }
        }

        if (closestIndex >= 0) {
          _weightController.jumpToItem(closestIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
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

  void _navigateToNextScreen() {
    // Get the selected weight value
    final selectedWeight = _weightValues[_weightController.selectedItem];

    // Convert to the selected unit if needed
    double goalWeightValue;
    if (_selectedUnit == 'kg') {
      goalWeightValue = selectedWeight.toDouble();
    } else {
      // Convert kg to lbs
      goalWeightValue = (selectedWeight * 2.20462).round().toDouble();
    }

    // Get current weight from user data
    final currentWeight = widget.userData['weight'] != null
        ? (widget.userData['weight'] as Map<String, dynamic>)['value'] is int
            ? ((widget.userData['weight'] as Map<String, dynamic>)['value'] as int).toDouble()
            : (widget.userData['weight'] as Map<String, dynamic>)['value'] as double
        : 52.0; // Default to 52kg as specified

    // Determine weight goal (gain, lose, maintain)
    String weightGoal;
    if (goalWeightValue > currentWeight) {
      weightGoal = 'gain';
    } else if (goalWeightValue < currentWeight) {
      weightGoal = 'lose';
    } else {
      weightGoal = 'maintain';
    }

    final updatedUserData = {
      ...widget.userData,
      'goal_weight': {
        'value': goalWeightValue,
        'unit': _selectedUnit,
      },
      'weightGoal': weightGoal,
    };

    // Save goal weight data to UserService
    final userService = UserService();

    // First, get the current user data to ensure we don't lose any information
    userService.getUserData().then((currentUser) async {
      if (currentUser != null) {
        // Create goal weight map
        final goalWeightMap = {
          'value': goalWeightValue,
          'unit': _selectedUnit,
        };

        // Update with new goal weight data
        final updatedUser = currentUser.copyWith(
          weightGoal: weightGoal,
          goalWeight: goalWeightMap,
        );

        // Save the complete updated user model
        await userService.saveUserData(updatedUser);

        // Also save with alternative key format to ensure compatibility
        await userService.saveUserData({
          'goal_weight': goalWeightValue,
          'goal_weight_unit': _selectedUnit,
          'weight_goal': weightGoal,
          'weightGoal': weightGoal,
        });

        // Force a direct update to shared preferences to ensure data is saved
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('weight_goal', weightGoal);
        await prefs.setString('weightGoal', weightGoal);

        // Verify the data was saved correctly
        final verifyUser = await userService.getUserData();
        debugPrint('Verified user data after saving:');
        debugPrint('Weight goal: ${verifyUser?.weightGoal}');
        debugPrint('Goal weight: ${verifyUser?.goalWeight}');
      } else {
        // If no current user exists, save just the goal weight data
        await userService.saveUserData({
          'goal_weight': goalWeightValue,
          'goal_weight_unit': _selectedUnit,
          'weight_goal': weightGoal,
          'weightGoal': weightGoal,
        });
      }
    });

    print('Goal weight saved: $goalWeightValue $_selectedUnit, Weight goal: $weightGoal');

    // Navigate to meal timing screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealTimingScreen(
          userData: updatedUserData,
          onNext: widget.onNext,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button and progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        size: 20
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),

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

            // Title and subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Almost there!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "What's your goal weight?",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "You can change your goal at anytime.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Weight picker
            Expanded(
              child: _buildWeightPicker(),
            ),

            // Unit selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitButton('lbs'),
                  const SizedBox(width: 16),
                  _buildUnitButton('kg'),
                ],
              ),
            ),

            const Spacer(),

            // Info text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'We use this information to calculate and provide you with daily personalized recommendations.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: StandardButton(
                text: 'Next',
                onPressed: _navigateToNextScreen,
                backgroundColor: Theme.of(context).colorScheme.primary,
                textColor: Colors.white,
                height: 56,
                animationDelay: null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightPicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: _weightController,
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedWeightIndex = _weightValues[index];
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _weightValues.length,
          builder: (context, index) {
            final isSelected = _weightController.selectedItem == index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDarkMode ? Colors.grey[700] : Colors.grey[300])
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_weightValues[index]} ${_selectedUnit}',
                style: GoogleFonts.poppins(
                  fontSize: isSelected ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDarkMode ? Colors.white : Colors.black)
                      : (isDarkMode ? Colors.grey[400] : Colors.grey),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnitButton(String unit) {
    final isSelected = _selectedUnit == unit;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        if (_selectedUnit != unit) {
          setState(() {
            _selectedUnit = unit;

            // Convert the current weight to the new unit
            if (unit == 'kg') {
              // Convert from lbs to kg
              final int currentLbs = _lbsValues[_weightController.selectedItem];
              final int kgEquivalent = (currentLbs * 0.453592).round();

              // Find the closest kg value in our list
              int closestIndex = 0;
              int minDifference = 1000;

              for (int i = 0; i < _kgValues.length; i++) {
                final diff = (_kgValues[i] - kgEquivalent).abs();
                if (diff < minDifference) {
                  minDifference = diff;
                  closestIndex = i;
                }
              }

              // Jump to the closest kg value
              _weightController.jumpToItem(closestIndex);
            } else {
              // Convert from kg to lbs
              final int currentKg = _kgValues[_weightController.selectedItem];
              final int lbsEquivalent = (currentKg * 2.20462).round();

              // Find the closest lbs value in our list
              int closestIndex = 0;
              int minDifference = 1000;

              for (int i = 0; i < _lbsValues.length; i++) {
                final diff = (_lbsValues[i] - lbsEquivalent).abs();
                if (diff < minDifference) {
                  minDifference = diff;
                  closestIndex = i;
                }
              }

              // Jump to the closest lbs value
              _weightController.jumpToItem(closestIndex);
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : isDarkMode ? Colors.grey[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
        ),
        child: Text(
          unit,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
