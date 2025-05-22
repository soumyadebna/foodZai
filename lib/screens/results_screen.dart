import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import 'meal_timing_screen.dart';

class ResultsScreen extends StatefulWidget {
  final VoidCallback? onNext;

  const ResultsScreen({Key? key, this.onNext}) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _curveAnimation;

  // Current page in the onboarding flow (5 out of 7)
  final int _currentPage = 5;
  final int _numPages = 7;

  // Weight goal data
  String _goalType = 'gain'; // 'lose', 'gain', or 'maintain'
  double _currentWeight = 52.0;
  double _goalWeight = 62.0;
  double _weeklyRate = 0.5;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 180));

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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _curveAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    // Determine goal type based on current and goal weights
    // This would normally come from user data
    if (_currentWeight > _goalWeight) {
      _goalType = 'lose';
      _weeklyRate = 0.5; // kg per week
    } else if (_currentWeight < _goalWeight) {
      _goalType = 'gain';
      _weeklyRate = 0.3; // kg per week
    } else {
      _goalType = 'maintain';
      _weeklyRate = 0.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

            const SizedBox(height: 32),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'FoodAI delivers\nsustainable results',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Weight loss graph
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildWeightLossGraph(),
            ),

            const SizedBox(height: 24),

            // Statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _goalType == 'lose'
                            ? '85% of FoodAI users maintain their'
                            : _goalType == 'gain'
                              ? '82% of FoodAI users achieve their'
                              : '90% of FoodAI users successfully',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _goalType == 'lose'
                        ? 'weight loss goals beyond 6 months'
                        : _goalType == 'gain'
                          ? 'weight gain targets within 4 months'
                          : 'maintain their weight with our plan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Additional info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _goalType == 'lose'
                          ? Icons.lightbulb_outline
                          : _goalType == 'gain'
                            ? Icons.fitness_center
                            : Icons.balance,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _goalType == 'lose'
                              ? 'Personalized nutrition plans'
                              : _goalType == 'gain'
                                ? 'Muscle-building nutrition'
                                : 'Balanced nutrition plans',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _goalType == 'lose'
                              ? 'Tailored to your body type, activity level, and goals'
                              : _goalType == 'gain'
                                ? 'Optimized protein and calorie intake for healthy gains'
                                : 'Maintain your weight with balanced macronutrients',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

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

  Widget _buildWeightLossGraph() {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: _goalType == 'lose'
          ? _buildWeightLossContent()
          : _goalType == 'gain'
            ? _buildWeightGainContent()
            : _buildWeightMaintainContent(),
      ),
    );
  }

  Widget _buildWeightLossContent() {
    return AnimatedBuilder(
      animation: _curveAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: WeightLossGraphPainter(
            progress: _curveAnimation.value,
            traditionalColor: const Color(0xFFE57373),
            foodAiColor: Theme.of(context).colorScheme.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your weight loss progress',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '${_targetDate.month}/${_targetDate.day}/${_targetDate.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildLegendItem(
                    'FoodAI',
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    'Traditional diet',
                    const Color(0xFFE57373),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeightGainContent() {
    return Stack(
      children: [
        CustomPaint(
          painter: WeightGainGraphPainter(Theme.of(context).colorScheme.primary),
          size: Size.infinite,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your weight gain progress',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${_currentWeight.toStringAsFixed(1)} kg',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_targetDate.month}/${_targetDate.day}/${_targetDate.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${_goalWeight.toStringAsFixed(1)} kg',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightMaintainContent() {
    return Stack(
      children: [
        CustomPaint(
          painter: WeightMaintainGraphPainter(Theme.of(context).colorScheme.primary),
          size: Size.infinite,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your weight maintenance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${_currentWeight.toStringAsFixed(1)} kg',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_targetDate.month}/${_targetDate.day}/${_targetDate.year}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        '${_goalWeight.toStringAsFixed(1)} kg',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (widget.onNext != null) {
            widget.onNext!();
          } else {
            // Navigate to meal timing screen
            debugPrint('Navigating to meal timing screen');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MealTimingScreen(
                  userData: {
                    'gender': 'male', // Default value
                    'activity_level': 'moderate',
                    'experience': 'beginner',
                    'goal_weight': _goalWeight,
                    'goal_type': _goalType,
                    'current_weight': _currentWeight,
                  },
                  onNext: widget.onNext,
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
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

class WeightLossGraphPainter extends CustomPainter {
  final double progress;
  final Color traditionalColor;
  final Color foodAiColor;

  WeightLossGraphPainter({
    required this.progress,
    required this.traditionalColor,
    required this.foodAiColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height * 0.6;
    final startY = size.height * 0.2;

    // Draw traditional diet line (red)
    final traditionalPaint = Paint()
      ..color = traditionalColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final traditionalPath = Path();
    traditionalPath.moveTo(0, startY + height * 0.2);

    for (double x = 0; x <= width * progress; x += 1) {
      final normalizedX = x / width;
      final y = startY + height * (0.2 + 0.3 * math.sin(normalizedX * math.pi * 1.5) + 0.3 * normalizedX);
      traditionalPath.lineTo(x, y);
    }

    canvas.drawPath(traditionalPath, traditionalPaint);

    // Draw traditional diet area
    final traditionalGradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          traditionalColor.withOpacity(0.2),
          traditionalColor.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, startY, width, height))
      ..style = PaintingStyle.fill;

    final traditionalAreaPath = Path.from(traditionalPath);
    traditionalAreaPath.lineTo(width * progress, startY + height);
    traditionalAreaPath.lineTo(0, startY + height);
    traditionalAreaPath.close();

    canvas.drawPath(traditionalAreaPath, traditionalGradientPaint);

    // Draw FoodAI line (primary color)
    final foodAiPaint = Paint()
      ..color = foodAiColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final foodAiPath = Path();
    foodAiPath.moveTo(0, startY + height * 0.2);

    for (double x = 0; x <= width * progress; x += 1) {
      final normalizedX = x / width;
      final y = startY + height * (0.2 + 0.1 * math.sin(normalizedX * math.pi) - 0.5 * normalizedX);
      foodAiPath.lineTo(x, y);
    }

    canvas.drawPath(foodAiPath, foodAiPaint);

    // Draw FoodAI area
    final foodAiGradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          foodAiColor.withOpacity(0.2),
          foodAiColor.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, startY, width, height))
      ..style = PaintingStyle.fill;

    final foodAiAreaPath = Path.from(foodAiPath);
    foodAiAreaPath.lineTo(width * progress, startY + height);
    foodAiAreaPath.lineTo(0, startY + height);
    foodAiAreaPath.close();

    canvas.drawPath(foodAiAreaPath, foodAiGradientPaint);

    // Draw start and end points for FoodAI line
    if (progress > 0) {
      canvas.drawCircle(
        Offset(0, startY + height * 0.2),
        5,
        Paint()..color = foodAiColor,
      );
    }

    if (progress >= 0.99) {
      canvas.drawCircle(
        Offset(width, startY + height * (0.2 - 0.5)),
        5,
        Paint()..color = foodAiColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeightLossGraphPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class WeightGainGraphPainter extends CustomPainter {
  final Color primaryColor;

  WeightGainGraphPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create the path for the curve
    final path = Path();
    path.moveTo(0, height * 0.8); // Start at bottom left

    // Create a curve that goes up (weight gain)
    for (double x = 0; x <= width; x += 1) {
      final normalizedX = x / width;
      // Curve that starts slow and accelerates upward
      final y = height * (0.8 - 0.6 * math.pow(normalizedX, 1.5));
      path.lineTo(x, y);
    }

    // Draw the line
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Create and draw the gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.3),
          primaryColor.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw start and end points
    canvas.drawCircle(
      Offset(0, height * 0.8),
      5,
      Paint()..color = primaryColor,
    );

    canvas.drawCircle(
      Offset(width, height * 0.2),
      5,
      Paint()..color = primaryColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WeightMaintainGraphPainter extends CustomPainter {
  final Color primaryColor;

  WeightMaintainGraphPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Create the path for the curve
    final path = Path();
    path.moveTo(0, height * 0.5); // Start at middle left

    // Create a slightly wavy horizontal line (weight maintenance)
    for (double x = 0; x <= width; x += 1) {
      final normalizedX = x / width;
      // Small oscillations around the middle
      final y = height * (0.5 + 0.1 * math.sin(normalizedX * math.pi * 3));
      path.lineTo(x, y);
    }

    // Draw the line
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    // Create and draw the gradient fill
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.2),
          primaryColor.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw start and end points
    canvas.drawCircle(
      Offset(0, height * 0.5),
      5,
      Paint()..color = primaryColor,
    );

    canvas.drawCircle(
      Offset(width, height * 0.5),
      5,
      Paint()..color = primaryColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
