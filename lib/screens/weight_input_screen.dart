import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'height_input_screen.dart';
import '../widgets/standard_button.dart';
import '../services/user_service.dart';

class WeightInputScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onNext;

  const WeightInputScreen({Key? key, required this.userData, this.onNext}) : super(key: key);

  @override
  State<WeightInputScreen> createState() => _WeightInputScreenState();
}

class _WeightInputScreenState extends State<WeightInputScreen> {
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

  // Current page in the onboarding flow
  final int _currentPage = Constants.weightInputScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;

  @override
  void initState() {
    super.initState();

    // Initialize with existing user data if available
    if (widget.userData.containsKey('weight') && widget.userData['weight'] != null) {
      final weightData = widget.userData['weight'] as Map<String, dynamic>;
      final weightValue = weightData['value'] as double;
      final weightUnit = weightData['unit'] as String;

      _selectedUnit = weightUnit;
      _selectedWeightIndex = weightValue.round();

      if (weightUnit == 'kg') {
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
    double weightValue;
    if (_selectedUnit == 'kg') {
      weightValue = selectedWeight.toDouble();
    } else {
      // Convert kg to lbs
      weightValue = (selectedWeight * 2.20462).round().toDouble();
    }

    // Add weight data to user data
    final Map<String, dynamic> updatedUserData = {
      ...widget.userData ?? {},
      'weight': {
        'value': weightValue,
        'unit': _selectedUnit,
      },
    };

    // Save weight data to UserService
    final userService = UserService();
    userService.saveUserData({
      'weight': weightValue,
      'weight_unit': _selectedUnit,
    });

    print('Weight saved: $weightValue $_selectedUnit');

    // Navigate to the next screen using push
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HeightInputScreen(
          userData: updatedUserData,
          onNext: widget.onNext, // Pass the callback
        ),
      ),
    );

    // Log for debugging
    debugPrint('Weight selected: $weightValue $_selectedUnit');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 20),
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
                      'Got it!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "What's your current weight?",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "We'll use this to personalize your plan.",
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
                  color: Colors.black54,
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
                color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_weightValues[index]} ${_selectedUnit}',
                style: GoogleFonts.poppins(
                  fontSize: isSelected ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
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
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          unit,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
