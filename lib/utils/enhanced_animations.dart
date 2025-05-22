import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'm3_animations.dart';

/// Enhanced animations for the FoodAI app following Material 3 Expressive principles
class EnhancedAnimations {
  // Standard durations based on Material 3 Expressive
  static const Duration extraShort = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration extraLong = Duration(milliseconds: 700);

  // Standard delays for staggered animations
  static const Duration noDelay = Duration.zero;
  static const Duration tinyDelay = Duration(milliseconds: 50);
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 200);
  static const Duration longDelay = Duration(milliseconds: 300);
  static const Duration extraLongDelay = Duration(milliseconds: 400);

  // Standard curves based on Material 3 Expressive
  static const Curve emphasizedCurve = Cubic(0.2, 0.0, 0.0, 1.0); // Material 3 emphasized curve
  static const Curve standardCurve = Cubic(0.2, 0.0, 0.0, 1.0); // Material 3 standard curve
  static const Curve decelerateCurve = Cubic(0.0, 0.0, 0.0, 1.0); // Material 3 decelerate curve
  static const Curve accelerateCurve = Cubic(0.3, 0.0, 1.0, 1.0); // Material 3 accelerate curve

  // Fade animations
  static Effect fadeIn({
    Duration? duration,
    Duration? delay,
    Curve? curve,
  }) =>
      FadeEffect(
        duration: duration ?? short,
        delay: delay ?? noDelay,
        begin: 0.0,
        end: 1.0,
        curve: curve ?? standardCurve,
      );

  static Effect fadeOut({
    Duration? duration,
    Duration? delay,
    Curve? curve,
  }) =>
      FadeEffect(
        duration: duration ?? short,
        delay: delay ?? noDelay,
        begin: 1.0,
        end: 0.0,
        curve: curve ?? standardCurve,
      );

  // Scale animations with Material 3 Expressive motion
  static Effect scaleIn({
    Duration? duration,
    Duration? delay,
    Curve? curve,
  }) =>
      ScaleEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
        curve: curve ?? emphasizedCurve,
      );

  static Effect scaleOut({
    Duration? duration,
    Duration? delay,
    Curve? curve,
  }) =>
      ScaleEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: const Offset(1.0, 1.0),
        end: const Offset(0.95, 0.95),
        curve: curve ?? emphasizedCurve,
      );

  // Slide animations with Material 3 Expressive motion
  static Effect slideInFromBottom({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    double distance = 0.1,
  }) =>
      SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: Offset(0.0, distance),
        end: const Offset(0.0, 0.0),
        curve: curve ?? emphasizedCurve,
      );

  static Effect slideInFromTop({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    double distance = 0.1,
  }) =>
      SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: Offset(0.0, -distance),
        end: const Offset(0.0, 0.0),
        curve: curve ?? emphasizedCurve,
      );

  static Effect slideInFromLeft({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    double distance = 0.1,
  }) =>
      SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: Offset(-distance, 0.0),
        end: const Offset(0.0, 0.0),
        curve: curve ?? emphasizedCurve,
      );

  static Effect slideInFromRight({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    double distance = 0.1,
  }) =>
      SlideEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        begin: Offset(distance, 0.0),
        end: const Offset(0.0, 0.0),
        curve: curve ?? emphasizedCurve,
      );

  // Material 3 Expressive elevation animation
  static Effect elevate({
    Duration? duration,
    Duration? delay,
    Curve? curve,
  }) =>
      CustomEffect(
        duration: duration ?? medium,
        delay: delay ?? noDelay,
        curve: curve ?? standardCurve,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, -2 * value),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 * value),
                    blurRadius: 8 * value,
                    spreadRadius: 2 * value,
                    offset: Offset(0, 2 * value),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
      );

  // Material 3 Expressive pulse animation
  static Effect pulse({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    double intensity = 0.03,
  }) =>
      CustomEffect(
        duration: duration ?? long,
        delay: delay ?? noDelay,
        curve: curve ?? Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1.0 + intensity * math.sin(value * 2 * math.pi),
            child: child,
          );
        },
      );

  // Material 3 Expressive shimmer animation
  static List<Effect> shimmer({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    Color? color,
  }) =>
      [
        ShimmerEffect(
          duration: duration ?? extraLong,
          delay: delay ?? noDelay,
          color: color ?? Colors.white.withOpacity(0.5),
          size: 0.9,
          curve: curve ?? standardCurve,
        ),
      ];

  // Material 3 Expressive staggered list animation
  static List<Effect> staggeredList(int index, {
    Duration baseDuration = medium,
    Duration baseDelay = Duration.zero,
    double staggerFactor = 0.1,
  }) =>
      [
        fadeIn(
          delay: baseDelay + Duration(milliseconds: (index * staggerFactor * 1000).toInt()),
          duration: baseDuration,
        ),
        slideInFromBottom(
          delay: baseDelay + Duration(milliseconds: (index * staggerFactor * 1000).toInt()),
          duration: baseDuration,
          distance: 0.05,
        ),
      ];
}
