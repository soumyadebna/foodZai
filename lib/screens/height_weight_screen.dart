import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/user_service.dart';
import 'dob_input_screen.dart';
import '../widgets/standard_button.dart';

class HeightWeightScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onNext;

  const HeightWeightScreen({
    Key? key,
    required this.userData,
    this.onNext,
  }) : super(key: key);

  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends State<HeightWeightScreen> {
  bool _isMetric = true; // Default to metric
  
  // Height values for metric
  int _selectedCmIndex = 165;
  List<int> _cmValues = List.generate(121, (index) => index + 120); // 120-240 cm
  
  // Height values for imperial
  int _selectedFtIndex = 5;
  int _selectedInIndex = 5;
  List<int> _ftValues = List.generate(8, (index) => index + 3); // 3-10 ft
  List<int> _inValues = List.generate(12, (index) => index); // 0-11 in
  
  // Weight values for metric
  int _selectedKgIndex = 54;
  List<int> _kgValues = List.generate(171, (index) => index + 30); // 30-200 kg
  
  // Weight values for imperial
  int _selectedLbIndex = 119;
  List<int> _lbValues = List.generate(371, (index) => index + 30); // 30-400 lb
  
  // Controllers for the scroll views
  final FixedExtentScrollController _cmController = FixedExtentScrollController(initialItem: 45);
  final FixedExtentScrollController _ftController = FixedExtentScrollController(initialItem: 2);
  final FixedExtentScrollController _inController = FixedExtentScrollController(initialItem: 5);
  final FixedExtentScrollController _kgController = FixedExtentScrollController(initialItem: 24);
  final FixedExtentScrollController _lbController = FixedExtentScrollController(initialItem: 89);
  
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
      
      if (heightUnit == 'cm') {
        _isMetric = true;
        _selectedCmIndex = heightValue.round();
        _cmController.jumpToItem(_cmValues.indexOf(_selectedCmIndex));
      } else if (heightUnit == 'ft/in') {
        _isMetric = false;
        // Convert total inches to feet and inches
        final totalInches = heightValue.round();
        final feet = totalInches ~/ 12;
        final inches = totalInches % 12;
        
        _selectedFtIndex = feet;
        _selectedInIndex = inches;
        
        _ftController.jumpToItem(_ftValues.indexOf(_selectedFtIndex));
        _inController.jumpToItem(_inValues.indexOf(_selectedInIndex));
      }
    }
    
    if (widget.userData.containsKey('weight') && widget.userData['weight'] != null) {
      final weightData = widget.userData['weight'] as Map<String, dynamic>;
      final weightValue = weightData['value'] as double;
      final weightUnit = weightData['unit'] as String;
      
      if (weightUnit == 'kg') {
        _isMetric = true;
        _selectedKgIndex = weightValue.round();
        _kgController.jumpToItem(_kgValues.indexOf(_selectedKgIndex));
      } else if (weightUnit == 'lbs') {
        _isMetric = false;
        _selectedLbIndex = weightValue.round();
        _lbController.jumpToItem(_lbValues.indexOf(_selectedLbIndex));
      }
    }
  }

  @override
  void dispose() {
    _cmController.dispose();
    _ftController.dispose();
    _inController.dispose();
    _kgController.dispose();
    _lbController.dispose();
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
    // Calculate height in cm for both metric and imperial
    double heightCm;
    if (_isMetric) {
      heightCm = _cmValues[_cmController.selectedItem].toDouble();
    } else {
      // Convert feet and inches to cm
      final feet = _ftValues[_ftController.selectedItem];
      final inches = _inValues[_inController.selectedItem];
      final totalInches = (feet * 12) + inches;
      heightCm = totalInches * 2.54; // Convert inches to cm
    }

    // Calculate weight in kg for both metric and imperial
    double weightKg;
    if (_isMetric) {
      weightKg = _kgValues[_kgController.selectedItem].toDouble();
    } else {
      // Convert pounds to kg
      final pounds = _lbValues[_lbController.selectedItem];
      weightKg = pounds * 0.453592; // Convert pounds to kg
    }

    // Add height and weight data to user data
    final Map<String, dynamic> updatedUserData = {
      ...widget.userData,
      'height': {
        'value': _isMetric ? heightCm : (_ftValues[_ftController.selectedItem] * 12 + _inValues[_inController.selectedItem]).toDouble(),
        'unit': _isMetric ? 'cm' : 'ft/in',
      },
      'weight': {
        'value': _isMetric ? weightKg : _lbValues[_lbController.selectedItem].toDouble(),
        'unit': _isMetric ? 'kg' : 'lbs',
      },
    };

    // Save height and weight data to UserService
    final userService = UserService();
    userService.saveUserData({
      'height': _isMetric ? heightCm : (_ftValues[_ftController.selectedItem] * 12 + _inValues[_inController.selectedItem]).toDouble(),
      'height_unit': _isMetric ? 'cm' : 'ft/in',
      'weight': _isMetric ? weightKg : _lbValues[_lbController.selectedItem].toDouble(),
      'weight_unit': _isMetric ? 'kg' : 'lbs',
    });

    print('Height saved: ${_isMetric ? heightCm : (_ftValues[_ftController.selectedItem] * 12 + _inValues[_inController.selectedItem])} ${_isMetric ? "cm" : "ft/in"}');
    print('Weight saved: ${_isMetric ? weightKg : _lbValues[_lbController.selectedItem]} ${_isMetric ? "kg" : "lbs"}');

    // Navigate to the date of birth screen
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
                  
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: _currentPage + 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: _numPages - (_currentPage + 1),
                            child: Container(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title and subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Height & Weight',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will be used to calibrate your custom plan.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

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
                      color: _isMetric ? Colors.black54 : Colors.black,
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
                    activeColor: Colors.black,
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

            const SizedBox(height: 32),

            // Height and Weight labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Height',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Weight',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Height and Weight pickers
            Expanded(
              child: _isMetric ? _buildMetricPickers() : _buildImperialPickers(),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: StandardButton(
                text: 'Next',
                onPressed: _navigateToNextScreen,
                backgroundColor: Colors.black,
                textColor: Colors.white,
                height: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPickers() {
    return Row(
      children: [
        // Height picker (cm)
        Expanded(
          child: _buildScrollingPicker(
            controller: _cmController,
            values: _cmValues,
            suffix: 'cm',
            onChanged: (index) {
              setState(() {
                _selectedCmIndex = _cmValues[index];
              });
            },
          ),
        ),
        
        // Weight picker (kg)
        Expanded(
          child: _buildScrollingPicker(
            controller: _kgController,
            values: _kgValues,
            suffix: 'kg',
            onChanged: (index) {
              setState(() {
                _selectedKgIndex = _kgValues[index];
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImperialPickers() {
    return Row(
      children: [
        // Height picker (ft and in)
        Expanded(
          child: Row(
            children: [
              // Feet picker
              Expanded(
                child: _buildScrollingPicker(
                  controller: _ftController,
                  values: _ftValues,
                  suffix: 'ft',
                  onChanged: (index) {
                    setState(() {
                      _selectedFtIndex = _ftValues[index];
                    });
                  },
                ),
              ),
              
              // Inches picker
              Expanded(
                child: _buildScrollingPicker(
                  controller: _inController,
                  values: _inValues,
                  suffix: 'in',
                  onChanged: (index) {
                    setState(() {
                      _selectedInIndex = _inValues[index];
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Weight picker (lb)
        Expanded(
          child: _buildScrollingPicker(
            controller: _lbController,
            values: _lbValues,
            suffix: 'lb',
            onChanged: (index) {
              setState(() {
                _selectedLbIndex = _lbValues[index];
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScrollingPicker({
    required FixedExtentScrollController controller,
    required List<int> values,
    required String suffix,
    required Function(int) onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final isSelected = controller.selectedItem == index;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[300] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${values[index]} $suffix',
              style: GoogleFonts.poppins(
                fontSize: isSelected ? 18 : 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}
