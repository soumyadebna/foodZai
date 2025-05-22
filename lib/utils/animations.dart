import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

/// A centralized class for all animations in the app
/// This ensures consistency across all screens
class AppAnimations {
  // Standard durations
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 800);

  // Standard delays
  static const Duration noDelay = Duration.zero;
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 200);
  static const Duration longDelay = Duration(milliseconds: 300);

  // Fade animations
  static Effect fadeIn({Duration? duration, Duration? delay}) => FadeEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: 0.0,
        end: 1.0,
        curve: Curves.easeOut,
      );

  static Effect fadeOut({Duration? duration, Duration? delay}) => FadeEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: 1.0,
        end: 0.0,
        curve: Curves.easeIn,
      );

  // Scale animations
  static Effect scaleIn({Duration? duration, Duration? delay}) => ScaleEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(0.8, 0.8),
        end: const Offset(1.0, 1.0),
        curve: Curves.easeOutBack,
      );

  static Effect scaleOut({Duration? duration, Duration? delay}) => ScaleEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.8, 0.8),
        curve: Curves.easeIn,
      );

  // Slide animations
  static Effect slideInFromBottom({Duration? duration, Duration? delay}) => SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(0.0, 0.2),
        end: const Offset(0.0, 0.0),
        curve: Curves.easeOutCubic,
      );

  static Effect slideInFromTop({Duration? duration, Duration? delay}) => SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(0.0, -0.2),
        end: const Offset(0.0, 0.0),
        curve: Curves.easeOutCubic,
      );

  static Effect slideInFromLeft({Duration? duration, Duration? delay}) => SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(-0.2, 0.0),
        end: const Offset(0.0, 0.0),
        curve: Curves.easeOutCubic,
      );

  static Effect slideInFromRight({Duration? duration, Duration? delay}) => SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(0.2, 0.0),
        end: const Offset(0.0, 0.0),
        curve: Curves.easeOutCubic,
      );

  // Bounce animations
  static Effect bounce({Duration? duration, Duration? delay}) => ShakeEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        hz: 4,
        offset: const Offset(0.0, 0.02),
        rotation: 0.01,
        curve: Curves.easeInOut,
      );

  // Pulse animations
  static Effect pulse({Duration? duration, Duration? delay}) => CustomEffect(
        duration: duration ?? slow,
        delay: delay ?? noDelay,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + 0.05 * sin(value * 2 * 3.14159),
            child: child,
          );
        },
      );

  // Shimmer animation for loading states
  static List<Effect> shimmer({Duration? duration, Duration? delay}) => [
        ShimmerEffect(
          duration: duration ?? slow,
          delay: delay ?? noDelay,
          color: Colors.white54,
          size: 0.9,
          curve: Curves.easeInOut,
        ),
      ];
}
