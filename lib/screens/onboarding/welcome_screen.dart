import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Removed GoogleFonts direct import, will use Theme.of(context).textTheme
import '../../utils/m3_animations.dart'; // For animation constants
import 'gender_screen.dart'; // Assuming this is part of the onboarding flow

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use M3 theme colors
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // M3 background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // M3 friendly padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              _buildLogo(context), // Pass context for theme access
              const SizedBox(height: 40), // M3 typical spacing
              _buildTitle(context), // Pass context for theme access
              const SizedBox(height: 16), // M3 typical spacing
              _buildSubtitle(context), // Pass context for theme access
              const Spacer(),
              _buildGetStartedButton(context), // Pass context for theme access
              const SizedBox(height: 24), // M3 typical spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    // Using primaryContainer for background for M3 compliance
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer, // M3 color
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/mango.png', // Assuming MangoLogo is this asset
          width: 100,
          height: 100,
        ),
      ),
    ).animate().fadeIn(duration: M3Animations.long).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: M3Animations.long,
          curve: M3Animations.emphasizedCurve,
        );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Welcome to FoodAI',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith( // M3 typography
            color: Theme.of(context).colorScheme.onBackground, // M3 color
          ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(duration: M3Animations.long, delay: M3Animations.shortDelay).moveY(
          begin: 20,
          end: 0,
          duration: M3Animations.long,
          delay: M3Animations.shortDelay,
          curve: M3Animations.emphasizedDecelerate,
        );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      'Track your nutrition, achieve your goals, and live healthier with AI-powered food recognition',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith( // M3 typography
            color: Theme.of(context).colorScheme.onSurfaceVariant, // M3 color
            height: 1.5,
          ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(duration: M3Animations.long, delay: M3Animations.mediumDelay).moveY(
          begin: 20,
          end: 0,
          duration: M3Animations.long,
          delay: M3Animations.mediumDelay,
          curve: M3Animations.emphasizedDecelerate,
        );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // M3 typical button height
      child: FilledButton( // M3 prominent button
        onPressed: onNext,
        style: FilledButton.styleFrom(
          // backgroundColor is handled by FilledButton's default M3 style
          // foregroundColor is handled by FilledButton's default M3 style
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // M3 typical radius
          ),
        ),
        child: Text(
          'OK. Let\'s go.',
          style: Theme.of(context).textTheme.labelLarge?.copyWith( // M3 typography
                fontWeight: FontWeight.w600,
                // color will be Theme.of(context).colorScheme.onPrimary by default
              ),
        ),
      ),
    ).animate().fadeIn(duration: M3Animations.long, delay: M3Animations.longDelay).moveY(
          begin: 20,
          end: 0,
          duration: M3Animations.long,
          delay: M3Animations.longDelay,
          curve: M3Animations.emphasizedDecelerate,
        );
  }
}
