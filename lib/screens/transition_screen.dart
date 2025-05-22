import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class TransitionScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const TransitionScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> {
  @override
  void initState() {
    super.initState();
    
    // Save user data if needed
    if (widget.userData != null) {
      print('Saving user data in transition screen: ${widget.userData}');
    }
    
    // Navigate to home screen after a short delay
    Timer(const Duration(milliseconds: 1500), () {
      _navigateToHome();
    });
  }
  
  void _navigateToHome() {
    // Use pushAndRemoveUntil to clear the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mango body
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Mango leaf
                    Positioned(
                      top: 20,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 600.ms).slide(begin: const Offset(0, 0.2), end: Offset.zero, duration: 600.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 24),
            
            // App name
            Text(
              'FoodAI',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(
              duration: 600.ms,
              delay: 200.ms,
            ),
            
            const SizedBox(height: 8),
            
            // Loading text
            Text(
              'Loading your personalized plan...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ).animate().fadeIn(
              duration: 600.ms,
              delay: 400.ms,
            ),
            
            const SizedBox(height: 32),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ).animate().fadeIn(
              duration: 600.ms,
              delay: 600.ms,
            ),
          ],
        ),
      ),
    );
  }
}
