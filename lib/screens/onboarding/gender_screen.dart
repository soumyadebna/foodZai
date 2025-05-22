import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart'; // Added AppColors import

class GenderScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel updatedUser) onNext;
  final VoidCallback onBack;

  const GenderScreen({
    Key? key,
    required this.user,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String _selectedGender = 'male';
  DateTime _selectedDate = DateTime(1990, 1, 1);

  @override
  void initState() {
    super.initState();
    // Initialize with existing user data if available
    if (widget.user.gender != null) {
      _selectedGender = widget.user.gender!;
    }
    if (widget.user.dateOfBirth != null) {
      _selectedDate = widget.user.dateOfBirth!;
    }
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
              _buildGenderSelection(),
              const SizedBox(height: 40),
              _buildDateOfBirthSection(),
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
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const Expanded(flex: 4, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Tell us about yourself',
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'We need this information to calculate your nutrition needs accurately',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
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
              child: _buildGenderCard(
                'Male',
                'male',
                Icons.male_rounded,
                Colors.blue[100]!,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderCard(
                'Female',
                'female',
                Icons.female_rounded,
                Colors.pink[100]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(String title, String value, IconData icon, Color color) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? color.withOpacity(0.8) : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOfBirthSection() {
    // Calculate age
    final now = DateTime.now();
    final age = now.year - _selectedDate.year -
      (now.month > _selectedDate.month ||
      (now.month == _selectedDate.month && now.day >= _selectedDate.day) ? 0 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '$age years old',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker() async {
    // Use a direct, mobile-friendly approach with three number pickers
    // This is much easier to use on mobile devices

    // Initialize with current selected date
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;
    int selectedDay = _selectedDate.day;

    // Show a bottom sheet with three number pickers
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select Date of Birth',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Date display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('MMMM d, yyyy').format(DateTime(selectedYear, selectedMonth, selectedDay)),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  // Pickers
                  Expanded(
                    child: Row(
                      children: [
                        // Month picker
                        Expanded(
                          child: _buildWheelPicker(
                            context: context,
                            items: List.generate(
                              12,
                              (index) => DateFormat('MMM').format(DateTime(2000, index + 1)),
                            ),
                            selectedIndex: selectedMonth - 1,
                            onChanged: (index) {
                              setState(() {
                                selectedMonth = index + 1;
                                // Adjust day if needed
                                final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
                                if (selectedDay > daysInMonth) {
                                  selectedDay = daysInMonth;
                                }
                              });
                              HapticFeedback.selectionClick();
                            },
                            fontSize: 18,
                          ),
                        ),

                        // Day picker
                        Expanded(
                          child: _buildWheelPicker(
                            context: context,
                            items: List.generate(
                              DateTime(selectedYear, selectedMonth + 1, 0).day,
                              (index) => '${index + 1}',
                            ),
                            selectedIndex: selectedDay - 1,
                            onChanged: (index) {
                              setState(() {
                                selectedDay = index + 1;
                              });
                              HapticFeedback.selectionClick();
                            },
                            fontSize: 18,
                          ),
                        ),

                        // Year picker
                        Expanded(
                          child: _buildWheelPicker(
                            context: context,
                            items: List.generate(
                              DateTime.now().year - 1920 + 1,
                              (index) => '${1920 + index}',
                            ),
                            selectedIndex: selectedYear - 1920,
                            onChanged: (index) {
                              setState(() {
                                selectedYear = 1920 + index;
                                // Adjust day if needed (e.g., Feb 29 in non-leap year)
                                final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
                                if (selectedDay > daysInMonth) {
                                  selectedDay = daysInMonth;
                                }
                              });
                              HapticFeedback.selectionClick();
                            },
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final newDate = DateTime(selectedYear, selectedMonth, selectedDay);
                              setState(() {
                                this.setState(() {
                                  _selectedDate = newDate;
                                });
                              });
                              Navigator.pop(context);
                              HapticFeedback.mediumImpact();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Confirm',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build a wheel picker
  Widget _buildWheelPicker({
    required BuildContext context,
    required List<String> items,
    required int selectedIndex,
    required Function(int) onChanged,
    required double fontSize,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: selectedIndex),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: items.length,
          builder: (context, index) {
            final isSelected = index == selectedIndex;
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Text(
                  items[index],
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primaryColor : Colors.black54,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Update user model with selected gender and date of birth
          final updatedUser = widget.user.copyWith(
            gender: _selectedGender,
            dateOfBirth: _selectedDate,
          );

          // Call onNext callback with updated user
          widget.onNext(updatedUser);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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
