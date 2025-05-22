import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'dob_input_screen.dart';
import '../widgets/standard_button.dart';
import '../services/user_service.dart';

class HeightInputScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onNext;

  const HeightInputScreen({Key? key, required this.userData, this.onNext}) : super(key: key);

  @override
  State<HeightInputScreen> createState() => _HeightInputScreenState();
}

class _HeightInputScreenState extends State<HeightInputScreen> {
  // Height values for scrolling picker
  int _selectedHeightIndex = 165;
  final List<int> _heightValues = List.generate(121, (index) => index + 120); // 120-240 cm

  // Controllers for the scroll views
  final FixedExtentScrollController _heightController = FixedExtentScrollController(initialItem: 45);

  // Selected unit
  String _selectedUnit = 'cm'; // Default unit
  final List<String> _units = ['ft/in', 'cm'];

  // For imperial units (feet and inches)
  int _selectedFtIndex = 5;
  int _selectedInIndex = 5;
  final List<int> _ftValues = List.generate(8, (index) => index + 3); // 3-10 ft
  final List<int> _inValues = List.generate(12, (index) => index); // 0-11 in
  final FixedExtentScrollController _ftController = FixedExtentScrollController(initialItem: 2);
  final FixedExtentScrollController _inController = FixedExtentScrollController(initialItem: 5);

  bool _isMetric = true; // Default to metric

  // Current page in the onboarding flow
  final int _currentPage = Constants.heightInputScreenIndex;
  final int _numPages = Constants.totalOnboardingScreens;

  @override
  void initState() {
    super.initState();

    // Initialize with existing user data if available
    if (widget.userData.containsKey('height') && widget.userData['height'] != null) {
      final heightData = widget.userData['height'] as Map<String, dynamic>;
      final heightValue = heightData['value'] as double;
      final heightUnit = heightData['unit'] as String;

      _selectedUnit = heightUnit;

      if (heightUnit == 'cm') {
        _isMetric = true;
        _selectedHeightIndex = heightValue.round();
        // Find the closest value in our list
        final closestIndex = _heightValues.indexOf(_selectedHeightIndex);
        if (closestIndex >= 0) {
          _heightController.jumpToItem(closestIndex);
        }
      } else if (heightUnit == 'ft/in') {
        _isMetric = false;
        // Convert total inches to feet and inches
        final totalInches = heightValue.round();
        final feet = totalInches ~/ 12;
        final inches = totalInches % 12;

        _selectedFtIndex = feet;
        _selectedInIndex = inches;

        final ftIndex = _ftValues.indexOf(_selectedFtIndex);
        if (ftIndex >= 0) {
          _ftController.jumpToItem(ftIndex);
        }

        final inIndex = _inValues.indexOf(_selectedInIndex);
        if (inIndex >= 0) {
          _inController.jumpToItem(inIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _ftController.dispose();
    _inController.dispose();
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
    // Calculate height based on selected unit
    double heightValue;
    String displayValue = '';

    if (_isMetric) {
      // Get the selected height value in cm
      heightValue = _heightValues[_heightController.selectedItem].toDouble();
      displayValue = '${heightValue.toInt()} cm';
    } else {
      // Calculate height in inches from feet and inches
      final feet = _ftValues[_ftController.selectedItem];
      final inches = _inValues[_inController.selectedItem];
      heightValue = ((feet * 12) + inches).toDouble();
      displayValue = '$feet\'${inches}"'; // Format as 5'11" for display
    }

    // Add height data to user data
    final Map<String, dynamic> updatedUserData = {
      ...widget.userData,
      'height': {
        'value': heightValue,
        'unit': _isMetric ? 'cm' : 'ft/in',
        'display': displayValue, // Add display format
      },
    };

    // Save height data to UserService
    final userService = UserService();
    userService.saveUserData({
      'height': heightValue,
      'height_unit': _isMetric ? 'cm' : 'ft/in',
      'height_display': displayValue,
    });

    print('Height saved: $displayValue');

    // Navigate to the date of birth screen using push
    debugPrint('User data collected: $updatedUserData');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DobInputScreen(
          userData: updatedUserData,
          onNext: widget.onNext, // Pass the callback
        ),
      ),
    );
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
                      'Great!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "What's your height?",
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

            const SizedBox(height: 40),

            // Unit toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Text(
                    'Imperial',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: !_isMetric ? Colors.black : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isMetric,
                    onChanged: (value) {
                      setState(() {
                        _isMetric = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Metric',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isMetric ? Colors.black : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Height label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Height',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Height picker
            Expanded(
              child: _isMetric ? _buildMetricHeightPicker() : _buildImperialHeightPicker(),
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

  Widget _buildMetricHeightPicker() {
    return SizedBox(
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: _heightController,
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            _selectedHeightIndex = _heightValues[index];
          });
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _heightValues.length,
          builder: (context, index) {
            final isSelected = _heightController.selectedItem == index;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_heightValues[index]} cm',
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

  Widget _buildImperialHeightPicker() {
    return Row(
      children: [
        // Feet picker
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: _ftController,
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedFtIndex = _ftValues[index];
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _ftValues.length,
              builder: (context, index) {
                final isSelected = _ftController.selectedItem == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${_ftValues[index]} ft',
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
        ),

        // Inches picker
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: _inController,
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedInIndex = _inValues[index];
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _inValues.length,
              builder: (context, index) {
                final isSelected = _inController.selectedItem == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${_inValues[index]} in',
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
        ),
      ],
    );
  }
}
