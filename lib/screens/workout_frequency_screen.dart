import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutFrequencyScreen extends StatefulWidget {
  final VoidCallback? onNext;

  const WorkoutFrequencyScreen({Key? key, this.onNext}) : super(key: key);

  @override
  State<WorkoutFrequencyScreen> createState() => _WorkoutFrequencyScreenState();
}

class _WorkoutFrequencyScreenState extends State<WorkoutFrequencyScreen> {
  String? _selectedFrequency;
  final List<Map<String, dynamic>> _frequencyOptions = [
    {
      'value': '0-2',
      'title': '0 - 2',
      'subtitle': 'Workouts now and then',
      'icon': Icons.fitness_center,
      'iconCount': 1,
    },
    {
      'value': '3-5',
      'title': '3 - 5',
      'subtitle': 'A few workouts per week',
      'icon': Icons.fitness_center,
      'iconCount': 2,
    },
    {
      'value': '6+',
      'title': '6+',
      'subtitle': 'Dedicated athlete',
      'icon': Icons.fitness_center,
      'iconCount': 3,
    },
  ];
  
  // Progress indicator value (2 out of 5 steps)
  final double _progressValue = 0.4;

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Progress bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ),
                        minHeight: 8,
                      ),
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
                  Text(
                    'How many workouts do\nyou do per week?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
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
            
            const SizedBox(height: 40),
            
            // Workout frequency options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListView.builder(
                  itemCount: _frequencyOptions.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final option = _frequencyOptions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildFrequencyOption(
                        option['value'],
                        option['title'],
                        option['subtitle'],
                        option['icon'],
                        option['iconCount'],
                        option['value'] == _selectedFrequency,
                        onTap: () {
                          setState(() {
                            _selectedFrequency = option['value'];
                          });
                        },
                      )fadeIn(
                        delay: Duration(milliseconds: 300 + (index * 100)),
                        duration: 500.ms,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildNextButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    int iconCount,
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildIconsForCount(iconCount, isSelected),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ), end: const Offset(1.0, 1.0)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIconsForCount(int count, bool isSelected) {
    Color iconColor = isSelected 
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[600]!;
    
    switch (count) {
      case 1:
        return Center(
          child: Icon(Icons.fitness_center, color: iconColor),
        );
      case 2:
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: [
              Icon(Icons.fitness_center, color: iconColor, size: 20),
              Icon(Icons.fitness_center, color: iconColor, size: 20),
            ],
          ),
        );
      case 3:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, color: iconColor, size: 16),
                  const SizedBox(width: 2),
                  Icon(Icons.fitness_center, color: iconColor, size: 16),
                ],
              ),
              const SizedBox(height: 2),
              Icon(Icons.fitness_center, color: iconColor, size: 16),
            ],
          ),
        );
      default:
        return Center(
          child: Icon(Icons.fitness_center, color: iconColor),
        );
    }
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _selectedFrequency != null
          ? () {
              if (widget.onNext != null) {
                widget.onNext!();
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedFrequency != null 
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300],
        foregroundColor: _selectedFrequency != null 
            ? Colors.white
            : Colors.grey[500],
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[500],
        elevation: _selectedFrequency != null ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      child: Text(
        'Next',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
