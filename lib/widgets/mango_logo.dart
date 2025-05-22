import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class MangoLogo extends StatelessWidget {
  final double size;
  final bool animate;
  final Duration? animationDelay;
  final bool showShadow;

  const MangoLogo({
    Key? key,
    this.size = 100.0,
    this.animate = true,
    this.animationDelay,
    this.showShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Create the base logo widget
    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFB74D), // Light mango
            AppColors.primaryColor, // Mango
            const Color(0xFFF57C00), // Dark mango
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: showShadow ? [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mango highlight
          Positioned(
            top: size * 0.2,
            left: size * 0.2,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Mango body
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),

          // Mango leaf
          Positioned(
            top: size * 0.15,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: AppColors.secondary, // Green leaf for better contrast
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.15),
                  topRight: Radius.circular(size * 0.15),
                  bottomLeft: Radius.circular(size * 0.05),
                  bottomRight: Radius.circular(size * 0.05),
                ),
                boxShadow: showShadow ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
            ),
          ),

          // Leaf stem
          Positioned(
            top: size * 0.35,
            child: Container(
              width: size * 0.05,
              height: size * 0.1,
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(size * 0.025),
              ),
            ),
          ),
        ],
      ),
    );

    // Add animations if needed
    if (animate) {
      logo = logo.animate(
        onPlay: (controller) => controller.repeat(reverse: true),
        delay: animationDelay ?? 500.ms,
      ).shimmer(
        duration: 2.seconds,
        color: Colors.white.withOpacity(0.2),
      );
    }

    return logo;
  }
}
