import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';

class HeightWeightScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel updatedUser) onNext;
  final VoidCallback onBack;
  
  const HeightWeightScreen({
    Key? key,
    required this.user,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends State<HeightWeightScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  
  @override
  void initState() {
    super.initState();
    // Initialize with existing user data if available
    if (widget.user.weight != null) {
      _weightController.text = widget.user.weight!['value'].toString();
      _weightUnit = widget.user.weight!['unit'] as String;
    }
    
    if (widget.user.height != null) {
      _heightController.text = widget.user.height!['value'].toString();
      _heightUnit = widget.user.height!['unit'] as String;
    }
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 40),
              _buildWeightSection(),
              const SizedBox(height: 32),
              _buildHeightSection(),
              const Spacer(),
              _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }
  
  Widget _buildTitle() {
    return Text(
      'Your height and weight',
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
  
  Widget _buildSubtitle() {
    return Text(
      'This helps us calculate your calorie and nutrient needs',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.grey[600],
      ),
    );
  }
  
  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter weight',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildUnitSelector(
                _weightUnit,
                (value) {
                  setState(() {
                    _weightUnit = value!;
                    
                    // Convert weight value when unit changes
                    if (_weightController.text.isNotEmpty) {
                      double weight = double.parse(_weightController.text);
                      if (value == 'kg' && _weightUnit == 'lbs') {
                        // Convert lbs to kg
                        weight = weight * 0.453592;
                        _weightController.text = weight.toStringAsFixed(1);
                      } else if (value == 'lbs' && _weightUnit == 'kg') {
                        // Convert kg to lbs
                        weight = weight * 2.20462;
                        _weightController.text = weight.toStringAsFixed(1);
                      }
                    }
                  });
                },
                ['kg', 'lbs'],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildHeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Height',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter height',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildUnitSelector(
                _heightUnit,
                (value) {
                  setState(() {
                    _heightUnit = value!;
                    
                    // Convert height value when unit changes
                    if (_heightController.text.isNotEmpty) {
                      double height = double.parse(_heightController.text);
                      if (value == 'cm' && _heightUnit == 'ft/in') {
                        // Convert inches to cm
                        height = height * 2.54;
                        _heightController.text = height.toStringAsFixed(1);
                      } else if (value == 'ft/in' && _heightUnit == 'cm') {
                        // Convert cm to inches
                        height = height / 2.54;
                        _heightController.text = height.toStringAsFixed(1);
                      }
                    }
                  });
                },
                ['cm', 'ft/in'],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildUnitSelector(
    String currentValue,
    Function(String?) onChanged,
    List<String> options,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          onChanged: onChanged,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[600],
          ),
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  Widget _buildNextButton() {
    bool isValid = _weightController.text.isNotEmpty && _heightController.text.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isValid
            ? () {
                // Create weight and height maps
                final weight = {
                  'value': double.parse(_weightController.text),
                  'unit': _weightUnit,
                };
                
                final height = {
                  'value': double.parse(_heightController.text),
                  'unit': _heightUnit,
                };
                
                // Update user model with weight and height
                final updatedUser = widget.user.copyWith(
                  weight: weight,
                  height: height,
                );
                
                // Call onNext callback with updated user
                widget.onNext(updatedUser);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Next',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
