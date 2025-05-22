import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gender_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              _buildLogo(),
              const SizedBox(height: 40),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildSubtitle(),
              const Spacer(),
              _buildGetStartedButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/mango.png',
          width: 100,
          height: 100,
        ),
      ),
    ), end: const Offset(1.0, 1.0), 
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
        );
  }

  Widget _buildTitle() {
    return Text(
      'Welcome to FoodAI',
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      textAlign: TextAlign.center,
    )moveY(
          begin: 20,
          end: 0,
          duration: 600.ms,
          delay: 200.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildSubtitle() {
    return Text(
      'Track your nutrition, achieve your goals, and live healthier with AI-powered food recognition',
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.grey[600],
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    )moveY(
          begin: 20,
          end: 0,
          duration: 600.ms,
          delay: 400.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'OK. Let\'s go.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    )moveY(
          begin: 20,
          end: 0,
          duration: 600.ms,
          delay: 600.ms,
          curve: Curves.easeOutQuad,
        );
  }
}
