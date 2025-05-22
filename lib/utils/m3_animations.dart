import 'package:flutter/material.dart';

/// Material 3 animation utilities for consistent animations across the app
class M3Animations {
  // Standard durations based on Material 3 guidelines
  static const Duration micro = Duration(milliseconds: 50);
  static const Duration short = Duration(milliseconds: 100);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration long = Duration(milliseconds: 300);
  static const Duration extraLong = Duration(milliseconds: 500);
  
  // Standard delays
  static const Duration shortDelay = Duration(milliseconds: 50);
  static const Duration mediumDelay = Duration(milliseconds: 100);
  static const Duration longDelay = Duration(milliseconds: 200);
  
  // Material 3 easing curves
  static const Curve emphasizedCurve = Cubic(0.2, 0.0, 0.0, 1.0); // Material 3 emphasized curve
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve standardCurve = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);
  static const Curve standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);
  
  // Helper methods for common animations
  
  /// Creates a fade-in animation with Material 3 easing
  static Animation<double> fadeIn(AnimationController controller, {
    Curve? curve,
    Duration? delay,
  }) {
    final curveAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay != null ? delay.inMilliseconds / controller.duration!.inMilliseconds : 0.0,
        1.0,
        curve: curve ?? emphasizedCurve,
      ),
    );
    
    return Tween<double>(begin: 0.0, end: 1.0).animate(curveAnimation);
  }
  
  /// Creates a fade-out animation with Material 3 easing
  static Animation<double> fadeOut(AnimationController controller, {
    Curve? curve,
    Duration? delay,
  }) {
    final curveAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay != null ? delay.inMilliseconds / controller.duration!.inMilliseconds : 0.0,
        1.0,
        curve: curve ?? emphasizedCurve,
      ),
    );
    
    return Tween<double>(begin: 1.0, end: 0.0).animate(curveAnimation);
  }
  
  /// Creates a slide animation with Material 3 easing
  static Animation<Offset> slide(
    AnimationController controller, {
    Offset? begin,
    Offset? end,
    Curve? curve,
    Duration? delay,
  }) {
    final curveAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay != null ? delay.inMilliseconds / controller.duration!.inMilliseconds : 0.0,
        1.0,
        curve: curve ?? emphasizedCurve,
      ),
    );
    
    return Tween<Offset>(
      begin: begin ?? const Offset(0.0, 0.2),
      end: end ?? Offset.zero,
    ).animate(curveAnimation);
  }
  
  /// Creates a scale animation with Material 3 easing
  static Animation<double> scale(
    AnimationController controller, {
    double? begin,
    double? end,
    Curve? curve,
    Duration? delay,
  }) {
    final curveAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay != null ? delay.inMilliseconds / controller.duration!.inMilliseconds : 0.0,
        1.0,
        curve: curve ?? emphasizedCurve,
      ),
    );
    
    return Tween<double>(
      begin: begin ?? 0.8,
      end: end ?? 1.0,
    ).animate(curveAnimation);
  }
  
  /// Creates a staggered animation sequence
  static List<Animation<T>> staggered<T>(
    AnimationController controller,
    List<Tween<T>> tweens, {
    Duration staggerDuration = const Duration(milliseconds: 50),
    Curve curve = emphasizedCurve,
  }) {
    final animations = <Animation<T>>[];
    final itemDuration = 1.0 / tweens.length;
    
    for (int i = 0; i < tweens.length; i++) {
      final startTime = i * staggerDuration.inMilliseconds / controller.duration!.inMilliseconds;
      final endTime = startTime + itemDuration;
      
      final curveAnimation = CurvedAnimation(
        parent: controller,
        curve: Interval(startTime, endTime, curve: curve),
      );
      
      animations.add(tweens[i].animate(curveAnimation));
    }
    
    return animations;
  }
  
  /// Material 3 page transition
  static Widget pageTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    bool slide = true,
    bool fade = true,
  }) {
    // Primary animation for the new page
    final primaryTween = Tween(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: emphasizedCurve));
    final primaryAnimation = animation.drive(primaryTween);
    
    // Secondary animation for the current page
    final secondaryTween = Tween(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).chain(CurveTween(curve: emphasizedCurve));
    final secondarySlideAnimation = secondaryAnimation.drive(secondaryTween);
    
    // Fade animation for smoother transitions
    final fadeTween = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: emphasizedCurve));
    final fadeAnimation = animation.drive(fadeTween);
    
    Widget result = child;
    
    if (slide) {
      result = SlideTransition(
        position: primaryAnimation,
        child: SlideTransition(
          position: secondarySlideAnimation,
          child: result,
        ),
      );
    }
    
    if (fade) {
      result = FadeTransition(opacity: fadeAnimation, child: result);
    }
    
    return result;
  }
}
