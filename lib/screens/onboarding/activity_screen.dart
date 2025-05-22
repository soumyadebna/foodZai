import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';

class ActivityScreen extends StatefulWidget {
  final UserModel user;
  final Function(UserModel updatedUser) onNext;
  final VoidCallback onBack;
  
  const ActivityScreen({
    Key? key,
    required this.user,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _selectedActivity = 'moderate';
  
  @override
  void initState() {
    super.initState();
    // Initialize with existing user data if available
    if (widget.user.activityLevel != null) {
      _selectedActivity = widget.user.activityLevel!;
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
              _buildActivityOptions(),
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
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
        ],
      ),
    );
  }
  
  Widget _buildTitle() {
    return Text(
      'How active are you?',
      style: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
  
  Widget _buildSubtitle() {
    return Text(
      'This helps us calculate your daily calorie needs',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.grey[600],
      ),
    );
  }
  
  Widget _buildActivityOptions() {
    return Column(
      children: [
        _buildActivityCard(
          'Sedentary',
          'sedentary',
          'Little or no exercise, desk job',
          Icons.weekend_outlined,
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          'Lightly Active',
          'light',
          'Light exercise 1-3 days/week',
          Icons.directions_walk,
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          'Moderately Active',
          'moderate',
          'Moderate exercise 3-5 days/week',
          Icons.directions_run,
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          'Very Active',
          'active',
          'Hard exercise 6-7 days/week',
          Icons.fitness_center,
        ),
        const SizedBox(height: 16),
        _buildActivityCard(
          'Extremely Active',
          'very_active',
          'Hard daily exercise and physical job',
          Icons.sports_gymnastics,
        ),
      ],
    );
  }
  
  Widget _buildActivityCard(
    String title,
    String value,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedActivity == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivity = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black.withOpacity(0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.black,
                size: 24,
              ),
          ],
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
          // Update user model with selected activity level
          final updatedUser = widget.user.copyWith(
            activityLevel: _selectedActivity,
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
